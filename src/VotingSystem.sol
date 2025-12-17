// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./VoteNFT.sol";

contract VotingSystem is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        uint fundsReceived;
    }

    WorkflowStatus public workflowStatus;
    uint public voteStartTime;
    VoteNFT public voteNFT;
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    event WorkflowStatusChanged(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event FundsSentToCandidate(uint candidateId, uint amount, address founder);
    event VoteCast(address voter, uint candidateId, uint nftTokenId);
    event WinnerDeclared(uint candidateId, string candidateName, uint voteCount);

    modifier onlyAtStatus(WorkflowStatus _status) {
        require(workflowStatus == _status, "Invalid workflow status for this action");
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        workflowStatus = WorkflowStatus.REGISTER_CANDIDATES;
        voteNFT = new VoteNFT();
    }

    function setWorkflowStatus(WorkflowStatus _newStatus) public onlyRole(ADMIN_ROLE) {
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _newStatus;

        // Record the time when VOTE status is set
        if (_newStatus == WorkflowStatus.VOTE) {
            voteStartTime = block.timestamp;
        }

        emit WorkflowStatusChanged(previousStatus, _newStatus);
    }

    function addCandidate(string memory _name) public onlyRole(ADMIN_ROLE) onlyAtStatus(WorkflowStatus.REGISTER_CANDIDATES) {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0, 0);
        candidateIds.push(candidateId);
    }

    function fundCandidate(uint _candidateId) public payable onlyRole(FOUNDER_ROLE) onlyAtStatus(WorkflowStatus.FOUND_CANDIDATES) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(msg.value > 0, "Must send funds");

        candidates[_candidateId].fundsReceived += msg.value;
        emit FundsSentToCandidate(_candidateId, msg.value, msg.sender);
    }

    function vote(uint _candidateId) public onlyAtStatus(WorkflowStatus.VOTE) {
        require(block.timestamp >= voteStartTime + 1 hours, "Voting not open yet, please wait 1 hour after vote status activation");
        require(!voteNFT.hasVoted(msg.sender), "You have already voted (NFT already owned)");
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;

        // Mint NFT to voter
        uint tokenId = voteNFT.mint(msg.sender);
        emit VoteCast(msg.sender, _candidateId, tokenId);
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }

    function getWinner() public onlyAtStatus(WorkflowStatus.COMPLETED) returns (Candidate memory) {
        require(candidateIds.length > 0, "No candidates registered");

        uint winnerCandidateId = candidateIds[0];
        uint maxVotes = candidates[winnerCandidateId].voteCount;

        for (uint i = 1; i < candidateIds.length; i++) {
            uint candidateId = candidateIds[i];
            if (candidates[candidateId].voteCount > maxVotes) {
                maxVotes = candidates[candidateId].voteCount;
                winnerCandidateId = candidateId;
            }
        }

        Candidate memory winner = candidates[winnerCandidateId];
        emit WinnerDeclared(winner.id, winner.name, winner.voteCount);
        return winner;
    }
}

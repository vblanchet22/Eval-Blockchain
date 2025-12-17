// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/VotingSystem.sol";

contract VotingSystemTest is Test {
    VotingSystem public votingSystem;
    address public admin;
    address public user1;
    address public user2;
    address public founder;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        founder = address(0x3);

        votingSystem = new VotingSystem();

        // Grant FOUNDER_ROLE to founder
        bytes32 founderRole = votingSystem.FOUNDER_ROLE();
        votingSystem.grantRole(founderRole, founder);

        // Give some ETH to founder for testing
        vm.deal(founder, 10 ether);
    }

    // Test 1: Admin role is granted to deployer
    function test_AdminRoleGrantedToDeployer() public {
        bytes32 adminRole = votingSystem.ADMIN_ROLE();
        assertTrue(votingSystem.hasRole(adminRole, admin));
    }

    // Test 2: Admin can add candidate
    function test_AdminCanAddCandidate() public {
        votingSystem.addCandidate("Alice");
        assertEq(votingSystem.getCandidatesCount(), 1);

        VotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
        assertEq(candidate.name, "Alice");
        assertEq(candidate.id, 1);
        assertEq(candidate.voteCount, 0);
    }

    // Test 3: Non-admin cannot add candidate
    function test_NonAdminCannotAddCandidate() public {
        vm.prank(user1);
        vm.expectRevert();
        votingSystem.addCandidate("Bob");
    }

    // Test 4: Anyone can vote (when workflow is at VOTE status)
    function test_AnyoneCanVote() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(user1);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 1);
        assertTrue(votingSystem.voters(user1));
    }

    // Test 5: Cannot vote twice
    function test_CannotVoteTwice() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.startPrank(user1);
        votingSystem.vote(1);
        vm.expectRevert("You have already voted (NFT already owned)");
        votingSystem.vote(1);
        vm.stopPrank();
    }

    // Test 6: Cannot vote for invalid candidate
    function test_CannotVoteForInvalidCandidate() public {
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);
        vm.prank(user1);
        vm.expectRevert("Invalid candidate ID");
        votingSystem.vote(999);
    }

    // Test 7: Cannot add empty candidate name
    function test_CannotAddEmptyCandidateName() public {
        vm.expectRevert("Candidate name cannot be empty");
        votingSystem.addCandidate("");
    }

    // Test 8: Multiple candidates can be added
    function test_MultipleCandiatesCanBeAdded() public {
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.addCandidate("Charlie");

        assertEq(votingSystem.getCandidatesCount(), 3);
    }

    // Test 9: Vote count increases correctly
    function test_VoteCountIncreasesCorrectly() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(user1);
        votingSystem.vote(1);

        vm.prank(user2);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 2);
    }

    // Test 10: Admin can grant admin role to another address
    function test_AdminCanGrantAdminRole() public {
        bytes32 adminRole = votingSystem.ADMIN_ROLE();
        votingSystem.grantRole(adminRole, user1);

        assertTrue(votingSystem.hasRole(adminRole, user1));

        // user1 should now be able to add candidates
        vm.prank(user1);
        votingSystem.addCandidate("Bob");

        assertEq(votingSystem.getCandidatesCount(), 1);
    }

    // Test 11: Initial workflow status is REGISTER_CANDIDATES
    function test_InitialWorkflowStatusIsRegisterCandidates() public {
        assertEq(uint(votingSystem.workflowStatus()), uint(VotingSystem.WorkflowStatus.REGISTER_CANDIDATES));
    }

    // Test 12: Admin can change workflow status
    function test_AdminCanChangeWorkflowStatus() public {
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        assertEq(uint(votingSystem.workflowStatus()), uint(VotingSystem.WorkflowStatus.FOUND_CANDIDATES));

        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        assertEq(uint(votingSystem.workflowStatus()), uint(VotingSystem.WorkflowStatus.VOTE));

        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.COMPLETED);
        assertEq(uint(votingSystem.workflowStatus()), uint(VotingSystem.WorkflowStatus.COMPLETED));
    }

    // Test 13: Non-admin cannot change workflow status
    function test_NonAdminCannotChangeWorkflowStatus() public {
        vm.prank(user1);
        vm.expectRevert();
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
    }

    // Test 14: Cannot add candidate when not in REGISTER_CANDIDATES status
    function test_CannotAddCandidateWhenNotInRegisterCandidatesStatus() public {
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.expectRevert("Invalid workflow status for this action");
        votingSystem.addCandidate("Alice");
    }

    // Test 15: Cannot vote when not in VOTE status
    function test_CannotVoteWhenNotInVoteStatus() public {
        votingSystem.addCandidate("Alice");
        // Still in REGISTER_CANDIDATES status
        vm.prank(user1);
        vm.expectRevert("Invalid workflow status for this action");
        votingSystem.vote(1);
    }

    // Test 16: WorkflowStatusChanged event is emitted
    function test_WorkflowStatusChangedEventIsEmitted() public {
        vm.expectEmit(true, true, true, true);
        emit VotingSystem.WorkflowStatusChanged(
            VotingSystem.WorkflowStatus.REGISTER_CANDIDATES,
            VotingSystem.WorkflowStatus.VOTE
        );
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
    }

    // Test 17: Founder can send funds to candidate during FOUND_CANDIDATES status
    function test_FounderCanSendFundsToCandidate() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.prank(founder);
        votingSystem.fundCandidate{value: 1 ether}(1);

        VotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
        assertEq(candidate.fundsReceived, 1 ether);
    }

    // Test 18: Non-founder cannot send funds to candidate
    function test_NonFounderCannotSendFundsToCandidate() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert();
        votingSystem.fundCandidate{value: 1 ether}(1);
    }

    // Test 19: Cannot send funds when not in FOUND_CANDIDATES status
    function test_CannotSendFundsWhenNotInFoundCandidatesStatus() public {
        votingSystem.addCandidate("Alice");
        // Still in REGISTER_CANDIDATES status

        vm.prank(founder);
        vm.expectRevert("Invalid workflow status for this action");
        votingSystem.fundCandidate{value: 1 ether}(1);
    }

    // Test 20: Cannot send funds to invalid candidate
    function test_CannotSendFundsToInvalidCandidate() public {
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.prank(founder);
        vm.expectRevert("Invalid candidate ID");
        votingSystem.fundCandidate{value: 1 ether}(999);
    }

    // Test 21: Cannot send zero funds
    function test_CannotSendZeroFunds() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.prank(founder);
        vm.expectRevert("Must send funds");
        votingSystem.fundCandidate{value: 0}(1);
    }

    // Test 22: FundsSentToCandidate event is emitted
    function test_FundsSentToCandidateEventIsEmitted() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.expectEmit(true, true, true, true);
        emit VotingSystem.FundsSentToCandidate(1, 1 ether, founder);

        vm.prank(founder);
        votingSystem.fundCandidate{value: 1 ether}(1);
    }

    // Test 23: Multiple founders can send funds to same candidate
    function test_MultipleFundersCanSendFundsToSameCandidate() public {
        address founder2 = address(0x4);
        bytes32 founderRole = votingSystem.FOUNDER_ROLE();
        votingSystem.grantRole(founderRole, founder2);
        vm.deal(founder2, 10 ether);

        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.prank(founder);
        votingSystem.fundCandidate{value: 1 ether}(1);

        vm.prank(founder2);
        votingSystem.fundCandidate{value: 2 ether}(1);

        VotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
        assertEq(candidate.fundsReceived, 3 ether);
    }

    // Test 24: Cannot vote before 1 hour after VOTE status is set
    function test_CannotVoteBeforeOneHour() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);

        // Try to vote immediately
        vm.prank(user1);
        vm.expectRevert("Voting not open yet, please wait 1 hour after vote status activation");
        votingSystem.vote(1);

        // Try to vote after 30 minutes
        vm.warp(block.timestamp + 30 minutes);
        vm.prank(user1);
        vm.expectRevert("Voting not open yet, please wait 1 hour after vote status activation");
        votingSystem.vote(1);
    }

    // Test 25: Can vote after 1 hour from VOTE status activation
    function test_CanVoteAfterOneHour() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);

        // Warp time to 1 hour + 1 second after vote status activation
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(user1);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 1);
        assertTrue(votingSystem.voters(user1));
    }

    // Test 26: voteStartTime is set when VOTE status is activated
    function test_VoteStartTimeIsSet() public {
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        assertEq(votingSystem.voteStartTime(), block.timestamp);
    }

    // Test 27: voteStartTime is only set for VOTE status
    function test_VoteStartTimeOnlySetForVoteStatus() public {
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        assertEq(votingSystem.voteStartTime(), 0);

        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        uint voteTime = votingSystem.voteStartTime();
        assertGt(voteTime, 0);

        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.COMPLETED);
        assertEq(votingSystem.voteStartTime(), voteTime); // Should remain the same
    }

    // Test 28: Voter receives NFT after voting
    function test_VoterReceivesNFTAfterVoting() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // Check user1 doesn't have NFT before voting
        assertFalse(votingSystem.voteNFT().hasVoted(user1));

        vm.prank(user1);
        votingSystem.vote(1);

        // Check user1 has NFT after voting
        assertTrue(votingSystem.voteNFT().hasVoted(user1));
        assertEq(votingSystem.voteNFT().balanceOf(user1), 1);
    }

    // Test 29: Cannot vote if already owns NFT
    function test_CannotVoteIfAlreadyOwnsNFT() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // User1 votes first time
        vm.prank(user1);
        votingSystem.vote(1);

        // User1 tries to vote again
        vm.prank(user1);
        vm.expectRevert("You have already voted (NFT already owned)");
        votingSystem.vote(1);
    }

    // Test 30: VoteCast event is emitted with NFT token ID
    function test_VoteCastEventIsEmitted() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.expectEmit(true, true, true, true);
        emit VotingSystem.VoteCast(user1, 1, 1);

        vm.prank(user1);
        votingSystem.vote(1);
    }

    // Test 31: Multiple voters each receive unique NFT
    function test_MultipleVotersReceiveUniqueNFTs() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(user1);
        votingSystem.vote(1);

        vm.prank(user2);
        votingSystem.vote(1);

        // Both should have NFTs
        assertTrue(votingSystem.voteNFT().hasVoted(user1));
        assertTrue(votingSystem.voteNFT().hasVoted(user2));
        assertEq(votingSystem.voteNFT().balanceOf(user1), 1);
        assertEq(votingSystem.voteNFT().balanceOf(user2), 1);
    }

    // Test 32: Cannot get winner when not in COMPLETED status
    function test_CannotGetWinnerWhenNotInCompletedStatus() public {
        votingSystem.addCandidate("Alice");
        vm.expectRevert("Invalid workflow status for this action");
        votingSystem.getWinner();
    }

    // Test 33: Can get winner when in COMPLETED status
    function test_CanGetWinnerInCompletedStatus() public {
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // Alice gets 2 votes
        vm.prank(user1);
        votingSystem.vote(1);

        vm.prank(user2);
        votingSystem.vote(1);

        // Bob gets 1 vote
        address user3 = address(0x5);
        vm.prank(user3);
        votingSystem.vote(2);

        // Set to COMPLETED
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.COMPLETED);

        VotingSystem.Candidate memory winner = votingSystem.getWinner();
        assertEq(winner.id, 1);
        assertEq(winner.name, "Alice");
        assertEq(winner.voteCount, 2);
    }

    // Test 34: Winner is correctly determined with multiple candidates
    function test_WinnerIsCorrectlyDetermined() public {
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.addCandidate("Charlie");

        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // Alice: 1 vote
        vm.prank(user1);
        votingSystem.vote(1);

        // Bob: 3 votes
        vm.prank(user2);
        votingSystem.vote(2);

        address user3 = address(0x5);
        vm.prank(user3);
        votingSystem.vote(2);

        address user4 = address(0x6);
        vm.prank(user4);
        votingSystem.vote(2);

        // Charlie: 2 votes
        address user5 = address(0x7);
        vm.prank(user5);
        votingSystem.vote(3);

        address user6 = address(0x8);
        vm.prank(user6);
        votingSystem.vote(3);

        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.COMPLETED);

        VotingSystem.Candidate memory winner = votingSystem.getWinner();
        assertEq(winner.id, 2);
        assertEq(winner.name, "Bob");
        assertEq(winner.voteCount, 3);
    }

    // Test 35: WinnerDeclared event is emitted
    function test_WinnerDeclaredEventIsEmitted() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(user1);
        votingSystem.vote(1);

        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.COMPLETED);

        vm.expectEmit(true, true, true, true);
        emit VotingSystem.WinnerDeclared(1, "Alice", 1);

        votingSystem.getWinner();
    }

    // Test 36: Winner can be determined with no votes
    function test_WinnerCanBeDeterminedWithNoVotes() public {
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.COMPLETED);

        VotingSystem.Candidate memory winner = votingSystem.getWinner();
        assertEq(winner.id, 1);
        assertEq(winner.name, "Alice");
        assertEq(winner.voteCount, 0);
    }

    // Test 37: Cannot get winner if no candidates registered
    function test_CannotGetWinnerIfNoCandidates() public {
        votingSystem.setWorkflowStatus(VotingSystem.WorkflowStatus.COMPLETED);
        vm.expectRevert("No candidates registered");
        votingSystem.getWinner();
    }
}

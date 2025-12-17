// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    constructor() ERC721("VoteNFT", "VNFT") Ownable(msg.sender) {}

    function mint(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function hasVoted(address voter) public view returns (bool) {
        return balanceOf(voter) > 0;
    }
}

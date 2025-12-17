// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {VotingSystem} from "../src/VotingSystem.sol";

contract DeployVotingSystem is Script {
    function run() external returns (VotingSystem) {
        //start and stop broadcast indicates that everything inside means that we are going to call a RPC Node
        vm.startBroadcast();
        VotingSystem votingSystem = new VotingSystem();
        vm.stopBroadcast();
        return votingSystem;
    }
}

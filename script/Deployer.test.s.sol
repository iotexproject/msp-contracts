// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {MockBucket} from "src/test/MockBucket.sol";
import {MockLST} from "src/test/MockLST.sol";

contract Deployer is Script {
    function run() external {
        vm.startBroadcast();

        // deploy bucket nft
        MockBucket bucket = new MockBucket();

        // deploy LST token
        MockLST lst = new MockLST("Mock LST", "MIOTX");

        vm.stopBroadcast();

        console.log("Deployed MockBucket: '%s'", address(bucket));
        console.log("Deployed MockLST: '%s'", address(lst));
    }
}

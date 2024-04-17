// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {BucketStrategy} from "src/strategies/BucketStrategy.sol";

contract Deployer is Script {
    function run() external {
        vm.startBroadcast();
        BucketStrategy strategy = new BucketStrategy();
        strategy.initialize(address(1));
        vm.stopBroadcast();
    }
}

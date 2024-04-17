// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {BucketStrategy} from "src/strategies/BucketStrategy.sol";

contract Deployer is Script {
    function run() external {
        Upgrades.deployUUPSProxy("BucketStrategy.sol", abi.encodeCall(BucketStrategy.initialize, (address(0))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {BucketRewardPool} from "src/core/BucketRewardPool.sol";
import {IStrategyManager, StrategyManager} from "src/core/StrategyManager.sol";
import {BucketStrategy} from "src/strategies/BucketStrategy.sol";

contract Deployer is Script {
    address private proxyAdmin;
    address private bucketNFT;

    function setUp() external {
        proxyAdmin = vm.envAddress("PROXY_ADMIN_ADDRESS");
        bucketNFT = vm.envAddress("BUCKET_NFT");

        console.log("PROXY_ADMIN_ADDRESS: '%s'", proxyAdmin);
        console.log("BUCKET_NFT: '%s'", bucketNFT);
    }

    function run() external {
        vm.startBroadcast();

        if (proxyAdmin == address(0)) {
            proxyAdmin = address(new ProxyAdmin());
            console.log("Deployed PROXY_ADMIN_ADDRESS: '%s'", proxyAdmin);
        }

        // deploy BucketRewardPool
        BucketRewardPool bucketRewardPoolImpl = new BucketRewardPool();
        TransparentUpgradeableProxy bucketRewardPool = new TransparentUpgradeableProxy(
            address(bucketRewardPoolImpl), proxyAdmin, abi.encodeCall(BucketRewardPool.initialize, ())
        );

        // deploy StrategyManager
        StrategyManager strategyManagerImpl = new StrategyManager();
        // TODO ratioManager
        TransparentUpgradeableProxy strategyManager = new TransparentUpgradeableProxy(
            address(strategyManagerImpl), proxyAdmin, abi.encodeCall(StrategyManager.initialize, (address(0)))
        );

        // deploy BucketStrategy
        BucketStrategy strategyImpl = new BucketStrategy();
        TransparentUpgradeableProxy strategy = new TransparentUpgradeableProxy(
            address(strategyImpl),
            proxyAdmin,
            abi.encodeCall(BucketStrategy.initialize, (bucketNFT, address(strategyManager), address(bucketRewardPool)))
        );

        // will fail at IoTeX chain
        // IStrategyManager strategyManagerProxy = IStrategyManager(address(strategyManager));
        // strategyManagerProxy.addStrategy(address(strategy), 100);

        vm.stopBroadcast();

        console.log("Deployed BucketRewardPool: '%s'", address(bucketRewardPool));
        console.log("Deployed StrategyManager: '%s'", address(strategyManager));
        console.log("Deployed BucketStrategy: '%s'", address(strategy));
    }
}

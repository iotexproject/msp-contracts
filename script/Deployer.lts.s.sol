// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {IStrategyManager} from "src/interfaces/IStrategyManager.sol";
import {LSTStrategy} from "src/strategies/LSTStrategy.sol";

contract Deployer is Script {
    address private proxyAdmin;
    address private strategyManager;
    address private lstToken;
    uint256 private lstRatio;

    function setUp() external {
        proxyAdmin = vm.envAddress("PROXY_ADMIN_ADDRESS");
        strategyManager = vm.envAddress("STRATEGY_MANAGER");
        lstToken = vm.envAddress("LST_TOKEN");

        console.log("PROXY_ADMIN_ADDRESS: '%s'", proxyAdmin);
        console.log("STRATEGY_MANAGER: '%s'", strategyManager);
        console.log("LST_TOKEN: '%s'", lstToken);
    }

    function run() external {
        vm.startBroadcast();

        LSTStrategy strategyImpl = new LSTStrategy();
        TransparentUpgradeableProxy strategy = new TransparentUpgradeableProxy(
            address(strategyImpl), proxyAdmin, abi.encodeCall(LSTStrategy.initialize, (lstToken, strategyManager))
        );

        IStrategyManager strategyManagerProxy = IStrategyManager(address(strategyManager));
        strategyManagerProxy.addStrategy(address(strategy));

        vm.stopBroadcast();

        console.log("Deployed LSTStrategy for %s LST: '%s'", lstToken, address(strategy));
    }
}

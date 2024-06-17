// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IStrategyManager.sol";

contract StrategyManager is IStrategyManager, OwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    function addStrategy(address strategy, uint256 ratio) external override {}

    function stopStrategy(address strategy) external override {}

    function changeStrategyRatio(address strategy, uint256 ratio) external override {}

    function shares(address user) external view override returns (uint256) {}

    function shares(address user, uint256 timepoint) external view override returns (uint256) {}

    function shares(address user, address strategy) external view override returns (uint256) {}

    function shares(address user, address strategy, uint256 timepoint) external view override returns (uint256) {}

    function totalShares() external view override returns (uint256) {}

    function totalShares(uint256 timepoint) external view override returns (uint256) {}

    function totalShares(address strategy) external view override returns (uint256) {}

    function totalShares(address strategy, uint256 timepoint) external view override returns (uint256) {}
}

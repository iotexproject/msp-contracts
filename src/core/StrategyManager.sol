// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IStrategyManager.sol";

contract StrategyManager is IStrategyManager, OwnableUpgradeable {
    uint256 public constant MAX_REWARD_TOKEN = 32;
    uint256 public constant MAX_STRATEGY = 32;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    function addStrategy(address strategy, uint256 ratio) external override {}

    function stopStrategy(address strategy) external override {}

    function changeStrategyRatio(address strategy, uint256 ratio) external override {}

    function shares(address user) external view override returns (uint256) {}

    function shares(address user, address strategy) external view override returns (uint256) {}

    function totalShares() external view override returns (uint256) {}

    function totalShares(address strategy) external view override returns (uint256) {}

    function distributeRewards(address token, uint256 amount) external payable override returns (bool) {}

    function addRewardToken(address token) external override {}

    function stopRewardToken(address token) external override {}

    function isRewardToken(address token) external view override returns (bool) {}

    function rewardTokens() external view override returns (address[] memory) {}
}

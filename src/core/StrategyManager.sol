// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IStrategyManager.sol";

contract StrategyManager is IStrategyManager {
    function addStrategy(address stragegy, uint256 ratio) external override {}

    function removeStrategy(address stragegy) external override {}

    function changeStrategyRatio(
        address stragegy,
        uint256 ratio
    ) external override {}

    function shares(address user) external view override returns (uint256) {}

    function shares(
        address user,
        uint256 timepoint
    ) external view override returns (uint256) {}

    function totalShares() external view override returns (uint256) {}

    function totalShares(
        uint256 timepoint
    ) external view override returns (uint256) {}
}

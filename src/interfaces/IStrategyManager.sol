// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IStrategy.sol";

interface IStrategyManager {
    /**
     * @notice add strategy with ratio
     */
    function addStrategy(address strategy, uint256 ratio) external;

    /**
     * @notice stop strategy
     */
    function stopStrategy(address strategy) external;

    /**
     * @notice change strategy ratio
     */
    function changeStrategyRatio(address strategy, uint256 ratio) external;

    /**
     * @notice convenience function for fetching the total shares of `user`
     */
    function shares(address user) external view returns (uint256);

    /**
     * @notice convenience function for fetching the total shares of `user`
     */
    function shares(address user, address strategy) external view returns (uint256);

    /**
     * @notice The total number of extant shares
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice The total number of extant shares
     */
    function totalShares(address strategy) external view returns (uint256);
}

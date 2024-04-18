// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IStrategy.sol";

interface IStrategyManager {
    /**
     * @notice convenience function for fetching the total shares of `user`
     */
    function shares(address user) external view returns (uint256);

    /// @notice The total number of extant shares
    function totalShares() external view returns (uint256);

    /// @notice Used by the DelegationManager to remove a Staker's shares from a particular strategy when entering the withdrawal queue
    function removeShares(address staker, IStrategy strategy, uint256 shares) external;

    /// @notice Used by the DelegationManager to award a Staker some shares that have passed through the withdrawal queue
    function addShares(address staker, IERC20 token, IStrategy strategy, uint256 shares) external;

    /// @notice Used by the DelegationManager to remove a bucket staker's shares from a particular strategy when entering the withdrawal queue
    function removeBucketShares(address staker, uint256 bucketId) external;

    /// @notice Used by the DelegationManager to award a bucket staker some shares that have passed through the withdrawal queue
    function addShares(address staker, IERC20 token, uint256 bucketId) external;
}

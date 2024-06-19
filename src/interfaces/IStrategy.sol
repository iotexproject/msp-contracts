// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStrategy {
    /// @notice The underlying token for staking in this Strategy
    function underlyingToken() external view returns (address);

    /**
     * @notice convenience function for fetching the total amount of `staker`
     */
    function amount(address staker) external view returns (uint256);

    /**
     * @notice The total number of extant amount
     */
    function totalAmount() external view returns (uint256);
}

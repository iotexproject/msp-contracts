// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStrategy {
    /// @notice The underlying token for staking in this Strategy
    function underlyingToken() external view returns (address);

    /**
     * @notice convenience function for fetching the total amount of `user`
     */
    function amount(address user) external view returns (uint256);

    /**
     * @notice convenience function for fetching the total amount of `user` at a specific moment in the past.
     */
    function amount(address user, uint48 timepoint) external view returns (uint256);

    /**
     * @notice The total number of extant amount
     */
    function totalAmount() external view returns (uint256);

    /**
     * @notice The total number of extant amount at a specific moment in the past.
     */
    function totalAmount(uint48 timepoint) external view returns (uint256);
}

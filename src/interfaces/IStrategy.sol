// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStrategy {
    /// @notice The underlying token for shares in this Strategy
    function underlyingToken() external view returns (address);
    
    /**
     * @notice convenience function for fetching the total shares of `user`
     */
    function shares(address user) external view returns (uint256);

    /**
     * @notice convenience function for fetching the total shares of `user` at a specific moment in the past.
     */
    function shares(address user, uint256 timepoint) external view returns (uint256);

    /**
     * @notice The total number of extant shares 
     */ 
    function totalShares() external view returns (uint256);

    /**
     * @notice The total number of extant shares at a specific moment in the past.
     */
    function totalShares(uint256 timepoint) external view returns (uint256);
}

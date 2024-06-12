// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBucketRewardPool {
    /**
     * @notice deposit bucket bucket voting rewards
     */
    function deposit() external;

    /**
     * @notice claim rewards and deposit to bucket
     *
     * @param index reward batch index
     * @param proof claim proof
     */
    function claim(uint256 index, bytes32[] calldata proof) external;

    /**
     * @notice claim rewards to receiver account
     *
     * @param index reward batch index
     * @param receiver reward receiver
     * @param proof claim proof
     */
    function claim(uint256 index, address receiver, bytes32[] calldata proof) external;

    /**
     * @notice commit buckets rewards root
     * 
     * @param index reward batch index
     * @param root reward commitment root
     */
    function commitRoot(uint256 index, bytes32 root) external;
}

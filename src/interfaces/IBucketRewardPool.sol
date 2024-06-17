// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBucketRewardPool {
    event BatchReward(address indexed dispatcher, uint256 indexed batch, uint256 amount);
    event CommitRoot(address indexed committer, uint256 batch, bytes32 root);
    event ApproveRoot(address indexed approver, uint256 batch);

    /**
     * @notice batch root
     */
    function batchRoot(uint256 batch) external view returns (bytes32);

    /**
     * @notice approve batch
     */
    function approvedBatch(uint256 batch) external view returns (bool);

    /**
     * @notice claim rewards and deposit to bucket
     */
    function claim(uint256 batch, uint256 bucketId, bytes32[] calldata proof) external;

    /**
     * @notice claim rewards to receiver account
     */
    function claim(uint256 batch, uint256 bucketId, address receiver, bytes32[] calldata proof) external;

    /**
     * @notice commit buckets rewards root
     */
    function commitRoot(uint256 batch, bytes32 root) external;

    /**
     * @notice approve root
     */
    function approveRoot(uint256 batch) external;
}

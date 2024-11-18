// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IStrategy.sol";

interface IBucketStrategy is IStrategy {
    event Stake(address indexed staker, uint256 indexed bucketId, uint256 bucketAmount, uint256 stakingAmount);
    event Deposit(address indexed staker, uint256 indexed bucketId, uint256 depositAmount, uint256 stakingAmount);
    event Unstake(address indexed staker, uint256 bucketId);
    event Withdraw(address indexed staker, uint256 bucketId);
    event Poke(address indexed staker, uint256 indexed bucketId, uint256 bucketAmount, uint256 stakingAmount);

    function rewardPool() external view returns (address);

    /**
     * @notice bucket stake status
     *
     * 1: staking
     * 2: unstaking
     */
    function stakeStatus(uint256 bucketId) external view returns (uint8);

    function bucketStaker(uint256 bucketId) external view returns (address);

    function bucketAmount(uint256 bucketId) external view returns (uint256);

    function unstakeTime(uint256 bucketId) external view returns (uint256);

    function withdrawTime(uint256 bucketId) external view returns (uint256);

    function stakerBuckets(address staker) external view returns (uint256[] memory);

    function calculateBucketRestakeAmount(uint256 bucketDuration, uint256 bucketAmount)
        external
        view
        returns (uint256);

    function stake(uint256 bucketId) external;

    function deposit(uint256 bucketId) external payable;

    function poke(uint256 bucketId) external;

    function unstake(uint256[] calldata bucketIds) external;

    function withdraw(uint256[] calldata bucketIds, address recipient) external;
}

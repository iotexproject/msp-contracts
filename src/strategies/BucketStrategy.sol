// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IBucket.sol";
import "../interfaces/IBucketStrategy.sol";
import "./BaseStrategy.sol";

contract BucketStrategy is IBucketStrategy, BaseStrategy, ERC721Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 constant WEEK = 7 days;
    uint256 public constant UINT256_MAX = type(uint256).max;

    /// @inheritdoc IBucketStrategy
    mapping(uint256 => uint8) public override stakeStatus;

    /// @inheritdoc IBucketStrategy
    mapping(uint256 => address) public override bucketStaker;

    /// @inheritdoc IBucketStrategy
    mapping(uint256 => uint256) public override bucketAmount;

    /// @inheritdoc IBucketStrategy
    mapping(uint256 => uint256) public override unstakeTime;

    /// @inheritdoc IBucketStrategy
    address public override rewardPool;

    mapping(address => EnumerableSet.UintSet) _stakerBucketList;

    function initialize(address bucketNFT, address manager, address bucketRewardPool) public initializer {
        __BaseStrategy_init(bucketNFT, manager);
        rewardPool = bucketRewardPool;
    }

    /// @inheritdoc IBucketStrategy
    function stake(uint256 bucketId) external override nonReentrant {
        IBucket bucketContract = IBucket(underlyingToken);
        require(bucketContract.ownerOf(bucketId) == msg.sender, "not owner");

        Bucket memory bucket = bucketContract.bucketOf(bucketId);
        require(bucketInLocking(bucket.duration), "not locking bucket");

        bucketContract.transferFrom(msg.sender, address(this), bucketId);

        stakeStatus[bucketId] = 1;
        bucketStaker[bucketId] = msg.sender;
        uint256 stakingAmount = calculateBucketRestakeAmount(bucket.duration, bucket.amount);
        bucketAmount[bucketId] = bucket.amount;
        uint256 originAmount = amount[msg.sender];
        uint256 newAmount = originAmount + stakingAmount;
        amount[msg.sender] = newAmount;
        _stakerBucketList[msg.sender].add(bucketId);
        _claimReward(msg.sender, originAmount, newAmount);

        totalAmount += stakingAmount;

        emit Stake(msg.sender, bucketId, bucket.amount, stakingAmount);
    }

    /// @inheritdoc IBucketStrategy
    function deposit(uint256 bucketId) external payable override nonReentrant {
        require(msg.value > 0, "zero amount");
        require(stakeStatus[bucketId] == 1, "not staking bucket");

        IBucket bucketContract = IBucket(underlyingToken);
        bucketContract.deposit{value: msg.value}(bucketId);

        Bucket memory bucket = bucketContract.bucketOf(bucketId);
        uint256 stakingAmount = calculateBucketRestakeAmount(bucket.duration, msg.value);
        bucketAmount[bucketId] = bucket.amount;
        uint256 originAmount = amount[msg.sender];
        uint256 newAmount = originAmount + stakingAmount;
        amount[msg.sender] = newAmount;
        _claimReward(msg.sender, originAmount, newAmount);

        totalAmount += stakingAmount;

        emit Deposit(msg.sender, bucketId, msg.value, stakingAmount);
    }

    /// @inheritdoc IBucketStrategy
    function unstake(uint256 bucketId) external nonReentrant {
        require(stakeStatus[bucketId] == 1, "not staking bucket");
        require(bucketStaker[bucketId] == msg.sender, "not staker");

        stakeStatus[bucketId] = 2;
        Bucket memory bucket = IBucket(underlyingToken).bucketOf(bucketId);
        uint256 stakingAmount = calculateBucketRestakeAmount(bucket.duration, bucketAmount[bucketId]);

        uint256 originAmount = amount[msg.sender];
        uint256 newAmount = amount[msg.sender] - stakingAmount;
        amount[msg.sender] = newAmount;
        _stakerBucketList[msg.sender].remove(bucketId);
        unstakeTime[bucketId] = block.timestamp;
        _claimReward(msg.sender, originAmount, newAmount);

        totalAmount -= stakingAmount;

        emit Unstake(msg.sender, bucketId);
    }

    /// @inheritdoc IBucketStrategy
    function withdraw(uint256 bucketId, address recipient) external {
        require(stakeStatus[bucketId] == 2, "not unstake bucket");
        require(bucketStaker[bucketId] == msg.sender, "not staker");
        require(unstakeTime[bucketId] + WEEK <= block.timestamp, "withdraw freeze");

        stakeStatus[bucketId] = 0;
        bucketStaker[bucketId] = address(0);
        unstakeTime[bucketId] = 0;
        bucketAmount[bucketId] = 0;

        IBucket(underlyingToken).transferFrom(address(this), recipient, bucketId);

        emit Withdraw(msg.sender, bucketId);
    }

    /// @inheritdoc IBucketStrategy
    function poke(uint256 bucketId) external override nonReentrant {
        require(stakeStatus[bucketId] == 1, "not staking bucket");
        Bucket memory bucket = IBucket(underlyingToken).bucketOf(bucketId);
        uint256 oldStakingAmount = bucketAmount[bucketId];
        require(bucket.amount > oldStakingAmount, "invalid bucket amount");

        uint256 stakingAmount = calculateBucketRestakeAmount(bucket.duration, bucket.amount - oldStakingAmount);

        uint256 originAmount = amount[msg.sender];
        uint256 newAmount = amount[msg.sender] + stakingAmount;
        amount[msg.sender] = newAmount;
        bucketAmount[bucketId] = bucket.amount;
        _claimReward(msg.sender, originAmount, newAmount);

        totalAmount += stakingAmount;

        emit Poke(msg.sender, bucketId, bucket.amount, stakingAmount);
    }

    /// @inheritdoc IBucketStrategy
    function stakerBuckets(address staker) public view override returns (uint256[] memory) {
        return _stakerBucketList[staker].values();
    }

    function bucketInLocking(uint256 bucketDuration) internal pure returns (bool) {
        return bucketDuration == UINT256_MAX;
    }

    /// @inheritdoc IBucketStrategy
    function calculateBucketRestakeAmount(uint256 _duration, uint256 _amount) public pure override returns (uint256) {
        // TODO calculate bonus by duration
        return _amount;
    }
}

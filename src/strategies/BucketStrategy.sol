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
        _stake(msg.sender, bucketId);
    }

    /// @inheritdoc IBucketStrategy
    function stake(address staker, uint256 bucketId) external override nonReentrant {
        _stake(staker, bucketId);
    }

    function _stake(address staker, uint256 bucketId) internal {
        IBucket bucketContract = IBucket(underlyingToken);
        require(bucketContract.ownerOf(bucketId) == staker, "not owner");

        Bucket memory bucket = bucketContract.bucketOf(bucketId);
        require(bucketInLocking(bucket.unlockedAt), "not locking bucket");

        bucketContract.transferFrom(staker, address(this), bucketId);

        stakeStatus[bucketId] = 1;
        bucketStaker[bucketId] = staker;
        uint256 stakingAmount = calculateBucketRestakeAmount(bucket.duration, bucket.amount);
        bucketAmount[bucketId] = bucket.amount;
        uint256 originAmount = amount[staker];
        uint256 newAmount = originAmount + stakingAmount;
        amount[staker] = newAmount;
        _stakerBucketList[staker].add(bucketId);
        _claimReward(staker, originAmount, newAmount);

        totalAmount += stakingAmount;

        emit Stake(staker, bucketId, bucket.amount, stakingAmount);
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
        address staker = bucketStaker[bucketId];
        uint256 originAmount = amount[staker];
        uint256 newAmount = originAmount + stakingAmount;
        amount[staker] = newAmount;
        _claimReward(staker, originAmount, newAmount);

        totalAmount += stakingAmount;

        emit Deposit(staker, bucketId, msg.value, stakingAmount);
    }

    /// @inheritdoc IBucketStrategy
    function unstake(uint256[] calldata bucketIds) external override nonReentrant {
        uint256 unstakeAmount = 0;
        for (uint256 i = 0; i < bucketIds.length; i++) {
            uint256 bucketId = bucketIds[i];
            require(stakeStatus[bucketId] == 1, "not staking bucket");
            require(bucketStaker[bucketId] == msg.sender, "not staker");

            stakeStatus[bucketId] = 2;
            Bucket memory bucket = IBucket(underlyingToken).bucketOf(bucketId);

            unstakeAmount += calculateBucketRestakeAmount(bucket.duration, bucketAmount[bucketId]);

            _stakerBucketList[msg.sender].remove(bucketId);
            unstakeTime[bucketId] = block.timestamp;

            emit Unstake(msg.sender, bucketId);
        }

        uint256 originAmount = amount[msg.sender];
        uint256 newAmount = originAmount - unstakeAmount;
        _claimReward(msg.sender, originAmount, newAmount);

        totalAmount -= unstakeAmount;
    }

    /// @inheritdoc IBucketStrategy
    function withdraw(uint256[] calldata bucketIds, address recipient) external override {
        for (uint256 i = 0; i < bucketIds.length; i++) {
            uint256 bucketId = bucketIds[i];

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

    function withdrawTime(uint256 bucketId) external view returns (uint256) {
        return unstakeTime[bucketId] + WEEK;
    }

    /// @inheritdoc IBucketStrategy
    function stakerBuckets(address staker) public view override returns (uint256[] memory) {
        return _stakerBucketList[staker].values();
    }

    function bucketInLocking(uint256 unlockedAt) internal pure returns (bool) {
        return unlockedAt == UINT256_MAX;
    }

    /// @inheritdoc IBucketStrategy
    function calculateBucketRestakeAmount(uint256 _duration, uint256 _amount) public pure override returns (uint256) {
        // TODO calculate bonus by duration
        return _amount;
    }
}

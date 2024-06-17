// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/IBucket.sol";
import "../interfaces/IBucketStrategy.sol";
import "../utils/Checkpoints.sol";

contract BucketStrategy is IBucketStrategy, Initializable, ERC721Holder {
    using EnumerableSet for EnumerableSet.UintSet;
    using Checkpoints for Checkpoints.Trace208;

    uint256 public constant UINT256_MAX = type(uint256).max;
    uint256 public constant MAX_BUCKET_LIST_LENGTH = 32;
    uint256 public constant WITHDRAW_PERIOD = 7 days;

    mapping(uint256 => uint8) public override stakeStatus;
    mapping(uint256 => address) public override bucketStaker;
    mapping(uint256 => uint256) public override unstakeTime;

    Checkpoints.Trace208 _totalAmount;
    mapping(uint256 => Checkpoints.Trace208) _bucketAmount;
    mapping(address => EnumerableSet.UintSet) _stakerBucketList;

    /// @inheritdoc IBucketStrategy
    address public override rewardPool;
    /// @inheritdoc IStrategy
    address public override underlyingToken;

    function initialize(address bucketNFT, address bucketRewardPool) public initializer {
        underlyingToken = bucketNFT;
        rewardPool = bucketRewardPool;
    }

    /// @inheritdoc IBucketStrategy
    function stake(uint256 bucketId) external override {
        EnumerableSet.UintSet storage _stakerBuckets = _stakerBucketList[msg.sender];
        require(_stakerBuckets.length() < MAX_BUCKET_LIST_LENGTH, "exceed max bucket size");

        IBucket bucketContract = IBucket(underlyingToken);
        require(bucketContract.ownerOf(bucketId) == msg.sender, "not owner");

        Bucket memory bucket = bucketContract.bucketOf(bucketId);
        require(bucketInLocking(bucket.duration), "not locking bucket");

        bucketContract.transferFrom(msg.sender, address(this), bucketId);

        stakeStatus[bucketId] = 1;
        bucketStaker[bucketId] = msg.sender;
        uint48 current = SafeCast.toUint48(block.timestamp);
        uint208 stakingAmount = SafeCast.toUint208(calculateBucketRestakeAmount(bucket.duration, bucket.amount));
        _bucketAmount[bucketId].push(current, SafeCast.toUint208(stakingAmount));
        _stakerBucketList[msg.sender].add(bucketId);

        uint208 _oldTotal = _totalAmount.latest();
        _totalAmount.push(current, _oldTotal + stakingAmount);

        emit Stake(msg.sender, bucketId, bucket.amount, stakingAmount);
    }

    /// @inheritdoc IBucketStrategy
    function deposit(uint256 bucketId) external payable override {
        require(msg.value > 0, "zero amount");
        require(stakeStatus[bucketId] == 1, "not staking bucket");

        IBucket bucketContract = IBucket(underlyingToken);
        bucketContract.deposit{value: msg.value}(bucketId);

        Bucket memory bucket = bucketContract.bucketOf(bucketId);
        uint48 current = SafeCast.toUint48(block.timestamp);
        uint208 stakingAmount = SafeCast.toUint208(calculateBucketRestakeAmount(bucket.duration, bucket.amount));
        uint208 oldStakingAmount = _bucketAmount[bucketId].latest();
        _bucketAmount[bucketId].push(current, stakingAmount);

        uint208 _oldTotal = _totalAmount.latest();
        _totalAmount.push(current, _oldTotal + stakingAmount - oldStakingAmount);

        emit Deposit(msg.sender, bucketId, msg.value, stakingAmount);
    }

    /// @inheritdoc IBucketStrategy
    function unstake(uint256 bucketId) external {
        require(stakeStatus[bucketId] == 1, "not staking bucket");
        require(bucketStaker[bucketId] == msg.sender, "not staker");

        stakeStatus[bucketId] = 2;
        uint208 oldStakingAmount = _bucketAmount[bucketId].latest();
        uint48 current = SafeCast.toUint48(block.timestamp);
        _bucketAmount[bucketId].push(current, 0);
        _stakerBucketList[msg.sender].remove(bucketId);
        unstakeTime[bucketId] = block.timestamp;

        uint208 _oldTotal = _totalAmount.latest();
        _totalAmount.push(current, _oldTotal - oldStakingAmount);

        emit Unstake(msg.sender, bucketId);
    }

    /// @inheritdoc IBucketStrategy
    function withdraw(uint256 bucketId, address recipient) external {
        require(stakeStatus[bucketId] == 2, "not unstake bucket");
        require(bucketStaker[bucketId] == msg.sender, "not staker");
        require(unstakeTime[bucketId] + WITHDRAW_PERIOD <= block.timestamp, "withdraw freeze");

        stakeStatus[bucketId] = 0;
        bucketStaker[bucketId] = address(0);
        unstakeTime[bucketId] = 0;

        IBucket(underlyingToken).transferFrom(address(this), recipient, bucketId);

        emit Withdraw(msg.sender, bucketId);
    }

    /// @inheritdoc IBucketStrategy
    function poke(uint256 bucketId) external override {
        require(stakeStatus[bucketId] == 1, "not staking bucket");

        Bucket memory bucket = IBucket(underlyingToken).bucketOf(bucketId);
        uint256 stakingAmount = calculateBucketRestakeAmount(bucket.duration, bucket.amount);
        _bucketAmount[bucketId].push(SafeCast.toUint48(block.timestamp), SafeCast.toUint208(stakingAmount));

        emit Poke(msg.sender, bucketId, bucket.amount, stakingAmount);
    }

    /// @inheritdoc IStrategy
    function amount(address staker) external view override returns (uint256) {
        uint208 total = 0;
        uint256[] memory buckets = _stakerBucketList[staker].values();
        for (uint256 i = 0; i < buckets.length; i++) {
            total += _bucketAmount[buckets[i]].latest();
        }
        return total;
    }

    /// @inheritdoc IStrategy
    function amount(address staker, uint256 timepoint) external view override returns (uint256) {
        uint208 total = 0;
        uint256[] memory buckets = _stakerBucketList[staker].values();
        for (uint256 i = 0; i < buckets.length; i++) {
            total += _bucketAmount[buckets[i]].upperLookup(SafeCast.toUint48(timepoint));
        }
        return total;
    }

    /// @inheritdoc IStrategy
    function totalAmount() external view override returns (uint256) {
        return _totalAmount.latest();
    }

    /// @inheritdoc IStrategy
    function totalAmount(uint256 timepoint) external view override returns (uint256) {
        return _totalAmount.upperLookup(SafeCast.toUint48(timepoint));
    }

    function stakerBuckets(address staker) public view returns (uint256[] memory) {
        return _stakerBucketList[staker].values();
    }

    function bucketInLocking(uint256 bucketDuration) internal pure returns (bool) {
        return bucketDuration == UINT256_MAX;
    }

    /// @inheritdoc IBucketStrategy
    function calculateBucketRestakeAmount(uint256 bucketDuration, uint256 bucketAmount)
        public
        pure
        override
        returns (uint256)
    {
        // TODO calculate bonus by duration
        return bucketAmount;
    }
}

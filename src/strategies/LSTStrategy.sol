// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILSTStrategy.sol";
import "../utils/Checkpoints.sol";

contract LSTStrategy is ILSTStrategy, Initializable {
    using Checkpoints for Checkpoints.Trace208;
    using SafeERC20 for IERC20;

    uint48 constant WEEK = 7 days;

    /// @inheritdoc IStrategy
    address public override underlyingToken;

    mapping(address => uint256) public override unstakeTime;
    mapping(address => uint256) public override unstakingAmount;

    Checkpoints.Trace208 _totalAmount;
    mapping(address => Checkpoints.Trace208) _stakingAmount;

    function initialize(address lst) public initializer {
        underlyingToken = lst;
    }

    function stake(uint256 _amount) external override {
        IERC20(underlyingToken).safeTransferFrom(msg.sender, address(this), _amount);

        uint48 current = (SafeCast.toUint48(block.timestamp) / WEEK) * WEEK;
        uint208 stakingAmount = SafeCast.toUint208(_amount);
        uint208 oldStakingAmount = _stakingAmount[msg.sender].latest();
        _stakingAmount[msg.sender].push(current, oldStakingAmount + stakingAmount);

        uint208 _oldTotal = _totalAmount.latest();
        _totalAmount.push(current, _oldTotal + stakingAmount);

        emit Stake(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external override {
        require(unstakingAmount[msg.sender] == 0, "exist unstaking");
        uint208 stakingAmount = _stakingAmount[msg.sender].latest();
        uint208 unstakeAmount = SafeCast.toUint208(_amount);
        require(stakingAmount >= unstakeAmount, "Insufficient staking");

        uint48 current = (SafeCast.toUint48(block.timestamp) / WEEK) * WEEK;
        _stakingAmount[msg.sender].push(current, stakingAmount - unstakeAmount);
        unstakeTime[msg.sender] = block.timestamp;
        unstakingAmount[msg.sender] = _amount;

        uint208 _oldTotal = _totalAmount.latest();
        _totalAmount.push(current, _oldTotal - unstakeAmount);

        emit Unstake(msg.sender, _amount);
    }

    function withdraw(address recipient) external override {
        uint256 _amount = unstakingAmount[msg.sender];
        require(_amount > 0, "no unstaking");
        require(unstakeTime[msg.sender] + WEEK <= block.timestamp, "withdraw freeze");

        unstakeTime[msg.sender] = 0;
        unstakingAmount[msg.sender] = 0;

        IERC20(underlyingToken).safeTransfer(recipient, _amount);

        emit Withdraw(msg.sender, recipient, _amount);
    }

    function amount(address staker) external view override returns (uint256) {
        return _stakingAmount[staker].latest();
    }

    function amount(address staker, uint48 timepoint) external view override returns (uint256) {
        return _stakingAmount[staker].upperLookup(timepoint);
    }

    function totalAmount() external view override returns (uint256) {
        return _totalAmount.latest();
    }

    function totalAmount(uint48 timepoint) external view override returns (uint256) {
        return _totalAmount.upperLookup(timepoint);
    }
}

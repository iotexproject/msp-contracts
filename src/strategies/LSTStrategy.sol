// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILSTStrategy.sol";
import "./BaseStrategy.sol";

contract LSTStrategy is ILSTStrategy, BaseStrategy {
    using SafeERC20 for IERC20;

    uint256 constant WEEK = 7 days;

    // @inheritdoc ILSTStrategy
    mapping(address => uint256) public override unstakeTime;

    // @inheritdoc ILSTStrategy
    mapping(address => uint256) public override unstakingAmount;

    function initialize(address lst, address manager) public initializer {
        __BaseStrategy_init(lst, manager);
    }

    function stake(uint256 _amount) external override {
        require(_amount > 0, "zero amount");

        IERC20(underlyingToken).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 stakingAmount = _amount;
        amount[msg.sender] += stakingAmount;

        totalAmount += stakingAmount;

        emit Stake(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external override {
        require(unstakingAmount[msg.sender] == 0, "exist unstaking");
        uint256 stakingAmount = amount[msg.sender];
        require(stakingAmount >= _amount, "Insufficient staking");

        amount[msg.sender] -= _amount;
        unstakeTime[msg.sender] = block.timestamp;
        unstakingAmount[msg.sender] = _amount;

        totalAmount -= _amount;

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IStrategyManager.sol";
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

    function stake(uint256 _amount) external override nonReentrant {
        _stake(msg.sender, _amount);
    }

    function stake(address _staker, uint256 _amount) external override nonReentrant {
        _stake(_staker, _amount);
    }

    function _stake(address _staker, uint256 _amount) internal {
        require(_amount > 0, "zero amount");

        // todo. maybe use msg.sender not _staker.
        // Otherwise, the business by the proxy will not be processed
        IERC20(underlyingToken).safeTransferFrom(_staker, address(this), _amount);

        uint256 originAmount = amount[_staker];
        uint256 newAmount = originAmount + _amount;
        amount[_staker] = newAmount;
        _claimReward(_staker, originAmount, newAmount);

        totalAmount += _amount;

        emit Stake(_staker, _amount);
    }

    function unstake(uint256 _amount) external override nonReentrant {
        require(unstakingAmount[msg.sender] == 0, "exist unstaking");
        uint256 stakingAmount = amount[msg.sender];
        require(stakingAmount >= _amount, "Insufficient staking");

        uint256 originAmount = amount[msg.sender];
        uint256 newAmount = originAmount - _amount;
        amount[msg.sender] = newAmount;
        unstakeTime[msg.sender] = block.timestamp;
        unstakingAmount[msg.sender] = _amount;
        _claimReward(msg.sender, originAmount, newAmount);

        totalAmount -= _amount;
        IStrategyManager(strategyManager).poke(msg.sender);

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

    function withdrawTime(address staker) external view returns (uint256) {
        return unstakeTime[staker] + WEEK;
    }
}

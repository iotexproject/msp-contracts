// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IStrategy.sol";

interface ILSTStrategy is IStrategy {
    event Stake(address indexed staker, uint256 stakingAmount);
    event Unstake(address indexed staker, uint256 unstakeAmount);
    event Withdraw(address indexed staker, address recipient, uint256 amount);

    function unstakeTime(address staker) external view returns (uint256);

    function unstakingAmount(address staker) external view returns (uint256);

    function stake(uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function withdraw(address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IStrategy.sol";

interface ILSTStrategy is IStrategy {
    event Stake(address indexed staker, uint256 stakingAmount);
    event Unstake(address indexed staker, uint256 unstakeAmount);
    event Withdraw(address indexed staker, address recipient, uint256 amount);
    event SetCap(uint256 cap);

    function unstakeTime(address staker) external view returns (uint256);

    function withdrawTime(address staker) external view returns (uint256);

    function unstakingAmount(address staker) external view returns (uint256);

    function cap() external view returns (uint256);

    function stake(uint256 _amount) external;

    function stake(address _staker, uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function withdraw(address recipient) external;

    function setCap(uint256 _cap) external;
}

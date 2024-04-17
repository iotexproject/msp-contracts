// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Strategy {
    function deposit(uint256 amount) external returns (uint256);
}

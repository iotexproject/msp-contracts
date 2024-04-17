// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStrategy {
    function deposit(uint256 bucketId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBucketStrategy {
    function deposit(uint256 bucketId) external returns (uint256);
}

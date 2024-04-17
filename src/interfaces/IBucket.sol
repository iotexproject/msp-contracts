// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBucket {
    function bucketOf(uint256 bucketId)
        external
        view
        returns (uint256 amount, uint256 duration, uint256 unlockedAt, uint256 unstakedAt, address delegate);
}

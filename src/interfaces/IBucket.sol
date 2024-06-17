// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Bucket {
    uint256 amount;
    uint256 duration;
    uint256 unlockedAt; // UINT256_MAX: in lock
    uint256 unstakedAt; // UINT256_MAX: in stake
    address delegate;
}

interface IBucket {
    function ownerOf(uint256 tokenId) external view returns (address);

    function bucketOf(uint256 _bucketId) external view returns (Bucket memory);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function deposit(uint256 _bucketId) external payable;
}

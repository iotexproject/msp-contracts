// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {Bucket} from "../interfaces/IBucket.sol";

contract MockBucket is ERC721 {
    uint256 public constant UINT256_MAX = type(uint256).max;

    event Staked(uint256 indexed bucketId, address delegate, uint256 amount, uint256 duration);

    uint256 public nextBucketId;
    mapping(uint256 => Bucket) private __buckets;

    constructor() ERC721("Mock bucket", "MBTK") {}

    function stake(uint256 _amount, uint256 _duration, address _delegate, uint256 _count)
        external
        payable
        returns (uint256[] memory bucketIds_)
    {
        bucketIds_ = new uint256[](_count);

        for (uint256 i = 0; i < _count; i++) {
            uint256 bucketId = ++nextBucketId;
            __buckets[bucketId] = Bucket(_amount, _duration, UINT256_MAX, UINT256_MAX, _delegate);
            _safeMint(msg.sender, bucketId);
            emit Staked(bucketId, _delegate, _amount, _duration);
        }
    }

    function bucketOf(uint256 _bucketId) external view returns (Bucket memory) {
        return __buckets[_bucketId];
    }

    function deposit(uint256 _bucketId) external payable {
        Bucket storage bucket = __buckets[_bucketId];
        bucket.amount += msg.value;
    }

    function withdraw(uint256 amount) external {
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "withdraw failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IBucketStrategy.sol";

contract BucketStrategy is IBucketStrategy, Initializable, ERC721Holder {
    address public bucket;

    function initialize(address _bucket) public initializer {
        bucket = _bucket;
    }

    function deposit(uint256 bucketId) external override returns (uint256) {}
}

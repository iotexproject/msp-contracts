// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IBucketStrategy.sol";

contract BucketStrategy is IBucketStrategy, Initializable, ERC721Holder {
    /// @inheritdoc IStrategy
    function underlyingToken() external view override returns (address) {}

    /// @inheritdoc IStrategy
    function shares(address user) external view override returns (uint256) {}

    /// @inheritdoc IStrategy
    function shares(
        address user,
        uint256 timepoint
    ) external view override returns (uint256) {}

    /// @inheritdoc IStrategy
    function totalShares() external view override returns (uint256) {}

    /// @inheritdoc IStrategy
    function totalShares(
        uint256 timepoint
    ) external view override returns (uint256) {}
}

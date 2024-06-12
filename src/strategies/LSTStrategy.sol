// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IStrategy.sol";

contract LSTStrategy is IStrategy {
    function underlyingToken() external view override returns (address) {}

    function shares(address user) external view override returns (uint256) {}

    function shares(
        address user,
        uint256 timepoint
    ) external view override returns (uint256) {}

    function totalShares() external view override returns (uint256) {}

    function totalShares(
        uint256 timepoint
    ) external view override returns (uint256) {}
}

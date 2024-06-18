// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IStrategy.sol";

contract LSTStrategy is IStrategy {
    function underlyingToken() external view override returns (address) {}

    function amount(address user) external view override returns (uint256) {}

    function amount(address user, uint48 timepoint) external view override returns (uint256) {}

    function totalAmount() external view override returns (uint256) {}

    function totalAmount(uint48 timepoint) external view override returns (uint256) {}
}

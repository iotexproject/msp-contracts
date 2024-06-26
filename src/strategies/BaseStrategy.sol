// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IStrategy.sol";

abstract contract BaseStrategy is IStrategy, Initializable {
    /// @inheritdoc IStrategy
    address public override underlyingToken;

    /// @inheritdoc IStrategy
    uint256 public override totalAmount;

    /// @inheritdoc IStrategy
    mapping(address => uint256) public override amount;

    /// @inheritdoc IStrategy
    address public override strategyManager;

    function __BaseStrategy_init(address underlyingToken_, address strategyManager_) internal onlyInitializing {
        underlyingToken = underlyingToken_;
        strategyManager = strategyManager_;
    }

    uint256[30] private __gap;
}

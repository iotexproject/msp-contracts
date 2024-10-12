// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IEntity} from "../../interfaces/common/IEntity.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Entity is Initializable, IEntity {
    /**
     * @inheritdoc IEntity
     */
    address public immutable override FACTORY;

    /**
     * @inheritdoc IEntity
     */
    uint64 public immutable override TYPE;

    constructor(address factory, uint64 type_) {
        _disableInitializers();

        FACTORY = factory;
        TYPE = type_;
    }

    /**
     * @inheritdoc IEntity
     */
    function initialize(bytes calldata data) external override initializer {
        _initialize(data);
    }

    function _initialize(bytes calldata /* data */ ) internal virtual {}
}

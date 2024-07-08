// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IVoter} from "../interfaces/IVoter.sol";
import {IStrategyManager} from "../interfaces/IStrategyManager.sol";
import {StrategyManager} from "../core/StrategyManager.sol";

contract MockVoter is IVoter {
    StrategyManager public manager;
    mapping(address => uint256) public amount;
    mapping(address => uint256) public ratios;

    constructor(address _manager) {
        manager = StrategyManager(_manager);
    }

    function poke(address _user) external {
        uint256 share = manager.shares(_user);
        amount[_user] = share;
    }

    function updateRatio(address _gauge, uint256 _ratio) external {
        ratios[_gauge] = _ratio;
    }
}

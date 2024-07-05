// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {BaseStrategy} from "../src/strategies/BaseStrategy.sol";
import {LSTStrategy} from "../src/strategies/LSTStrategy.sol";
import {StrategyManager} from "../src/core/StrategyManager.sol";
import {BucketStrategy} from "../src/strategies/BucketStrategy.sol";
import {MockLST} from "../src/test/MockLST.sol";

contract TestStrategy is Test {
    MockLST public lst;
    StrategyManager public manager;


    function setUp() external {
        lst = new MockLST("Test-LST", "LST");
        manager = new StrategyManager();
        manager.initialize();
    }

    function TestStake() external {
        LSTStrategy strategy = new LSTStrategy();
    }
}
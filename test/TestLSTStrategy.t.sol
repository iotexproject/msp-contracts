// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {BaseStrategy} from "../src/strategies/BaseStrategy.sol";
import {LSTStrategy} from "../src/strategies/LSTStrategy.sol";
import {StrategyManager} from "../src/core/StrategyManager.sol";
import {BucketStrategy} from "../src/strategies/BucketStrategy.sol";
import {MockLST} from "../src/test/MockLST.sol";
import {MockVoter} from "../src/test/MockVoter.sol";

contract TestStrategy is Test {
    MockLST public lst;
    MockVoter public voter;
    LSTStrategy public strategy;
    StrategyManager public manager;

    function setUp() external {
        lst = new MockLST("Test-LST", "LST");
        lst.mint(address(this), 10000 ether);
        manager = new StrategyManager();
        manager.initialize();
        voter = new MockVoter(address(manager));
        manager.setVoter(address(voter));
        strategy = new LSTStrategy();
        strategy.initialize(address(lst), address(manager));
        manager.addStrategy(address(strategy), 100);
    }

    function test_stake_unstake() external {
        lst.approve(address(strategy), 10 ether);

        //0. stake failed
        vm.expectRevert("zero amount");
        strategy.stake(0);

        //1. stake 1 ether
        strategy.stake(1 ether);
        vm.assertEq(1 ether, strategy.amount(address(this)));
        vm.assertEq(1 ether, strategy.totalAmount());

        //2. stake 2 ether
        strategy.stake(2 ether);
        vm.assertEq(3 ether, strategy.amount(address(this)));
        vm.assertEq(3 ether, strategy.totalAmount());

        //3. unstake 1 ether
        strategy.unstake(1 ether);
        vm.assertEq(2 ether, voter.amount(address(this)));
        console.log("this: ", address(this));
        console.log("strategy: ", address(strategy));
    }
}

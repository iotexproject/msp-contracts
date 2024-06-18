// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../src/utils/Checkpoints.sol";

contract CheckpointsBTest is Test {
    using Checkpoints for Checkpoints.Trace208;

    uint48 constant WEEK = 7 days;
    uint48 constant DAY = 1 days;

    Checkpoints.Trace208 _amount;

    function test_SetWeekly() public {
        assertEq(_amount.latest(), 0);
        assertEq(_amount.upperLookup(100), 0);

        uint48 timestamp = 1718676650;
        uint48 thisWeek = (timestamp / WEEK) * WEEK;
        uint48 thisWeekFirstDay = thisWeek + DAY;
        uint48 nextWeek = thisWeek + WEEK;
        console.log("This week:", thisWeek);
        console.log("Next week:", nextWeek);
        console.log("This week first day:", thisWeekFirstDay);

        _amount.push(thisWeek, SafeCast.toUint208(1000));
        assertEq(_amount.upperLookup(thisWeek - 1), 0);
        assertEq(_amount.latest(), 1000);
        assertEq(_amount.upperLookup(thisWeek), 1000);
        assertEq(_amount.upperLookup(thisWeekFirstDay), 1000);
        assertEq(_amount.upperLookup(nextWeek), 1000);
    }
}

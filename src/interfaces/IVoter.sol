// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVoter {
    /*
    * @notice update share in Voter when user withdraw
    */
    function poke() external;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVoter {
    /*
    * @notice update share in Voter when user withdraw
    */
    function poke(address _user) external;

    /*
    * @notice update ratio of gauge in Voter
    */
    function updateRatio(address _pool, uint256 _ratio) external;
}

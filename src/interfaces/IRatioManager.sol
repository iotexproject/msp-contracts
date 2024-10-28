// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRatioManager {
    function isSupportedToken(address _token) external view returns (bool);

    function getTargetAmount(address _token, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IRatioManager.sol";

interface IOracle {
    function latestAnswer() external view returns (uint256);
}

contract USDBasedOracleRatioManager is IRatioManager, OwnableUpgradeable {
    event AddOracle(address indexed token, address indexed oracle);
    event RemoveOracle(address indexed token);

    mapping(address => address) public oracles;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    function addOracle(address _token, address _oracle) external onlyOwner {
        require(_token != address(0) && _oracle != address(0), "zero address");

        oracles[_token] = _oracle;

        emit AddOracle(_token, _oracle);
    }

    function removeOracle(address _token) external onlyOwner {
        require(oracles[_token] != address(0), "invalid token");

        delete oracles[_token];

        emit RemoveOracle(_token);
    }

    function isSupportedToken(address _token) external view returns (bool) {
        return oracles[_token] != address(0);
    }

    function getTargetAmount(address _token, uint256 _amount) external view override returns (uint256) {
        require(oracles[_token] != address(0), "unsupport token");

        return IOracle(oracles[_token]).latestAnswer() * _amount;
    }
}

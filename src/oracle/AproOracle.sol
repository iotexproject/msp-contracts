// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IOracle.sol";

interface AproAggregator {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract AproOracle is IOracle, Ownable {
    event ChangeHeartbeat(uint256 heartbeat);

    AproAggregator public dataFeed;
    uint256 public heartbeat;

    constructor(address _aggregator, uint256 _heartbeat) {
        require(_aggregator != address(0), "zero address");
        dataFeed = AproAggregator(_aggregator);
        heartbeat = _heartbeat;
    }

    function changeHeartbeat(uint256 _heartbeat) external onlyOwner {
        heartbeat = _heartbeat;
        emit ChangeHeartbeat(_heartbeat);
    }

    function latestAnswer() external view override returns (uint256) {
        (
            /* uint80 roundId */
            ,
            int256 answer,
            /*uint256 startedAt*/
            ,
            uint256 timestamp,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        require(block.timestamp - timestamp < heartbeat, "expired price");
        return uint256(answer);
    }
}

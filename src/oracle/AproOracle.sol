// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IOracle.sol";

interface AproAggregator {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract AproOracle is IOracle {
    AproAggregator public dataFeed;

    constructor(address _aggregator) {
        require(_aggregator != address(0), "zero address");
        dataFeed = AproAggregator(_aggregator);
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
        require(block.timestamp - timestamp < 1.5 hours, "expired price");
        return uint256(answer);
    }
}

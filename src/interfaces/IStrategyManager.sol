// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IStrategy.sol";

interface IStrategyManager {
    event AddStrategy(address indexed strategy);
    event RemoveStrategy(address indexed strategy);
    event SetVoter(address indexed voter);
    event ChangeRatioManager(address indexed ratioManager);
    event AddRewardToken(address indexed token);
    event RemoveRewardToken(address indexed token);
    event DistributeRewards(address indexed strategy, address indexed token, uint256 rewards);

    /**
     * @notice add strategy
     */
    function addStrategy(address strategy) external;

    /**
     * @notice remove strategy
     */
    function removeStrategy(address strategy) external;

    /**
     * @notice change ratio manager
     */
    function changeRatioManager(address _ratioManager) external;

    /**
     * @notice strategy count
     */
    function strategyCount() external view returns (uint256);

    /**
     * @notice all strategies
     */
    function strategies() external view returns (address[] memory);

    /**
     * @notice convenience function for fetching the total shares of `user`
     */
    function shares(address user) external view returns (uint256);

    /**
     * @notice convenience function for fetching the total shares of `user`
     */
    function shares(address user, address strategy) external view returns (uint256);

    /**
     * @notice The total number of extant shares
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice The total number of extant shares
     */
    function totalShares(address strategy) external view returns (uint256);

    /**
     * @notice Distribute rewards with ERC20 or IOTX to strategy.
     */
    function distributeRewards(address token, uint256 amount) external payable returns (bool);

    /**
     * @notice add reward token
     */
    function addRewardToken(address token) external;

    /**
     * @notice remove reward token
     */
    function removeRewardToken(address token) external;

    /**
     * @notice reward token count
     */
    function rewardTokenCount() external view returns (uint256);

    /**
     * @notice check reward token
     */
    function isRewardToken(address token) external view returns (bool);

    /**
     * @notice reward tokens
     */
    function rewardTokens() external view returns (address[] memory);

    /**
     * @notice poke share for user
     */
    function poke(address user) external;
}

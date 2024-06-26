// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IStrategy.sol";

interface IStrategyManager {
    event AddStrategy(address indexed strategy, uint256 ratio);
    event RemoveStrategy(address indexed strategy);
    event ChangeStrategyRatio(address indexed strategy, uint256 ratio);
    event AddRewardToken(address indexed token);
    event StopRewardToken(address indexed token);
    event DistributeRewards(address indexed strategy, address indexed token, uint256 rewards);

    /**
     * @notice add strategy with ratio
     */
    function addStrategy(address strategy, uint256 ratio) external;

    /**
     * @notice stop strategy
     */
    function stopStrategy(address strategy) external;

    /**
     * @notice change strategy ratio
     */
    function changeStrategyRatio(address strategy, uint256 ratio) external;

    /**
     * @notice strategy count
     */
    function strategyCount() external view returns (uint256);

    /**
     * @notice all strategies
     */
    function strategies() external view returns (address[] memory);

    /**
     * @notice strategy ratio
     */
    function strategyRatio(address strategy) external view returns (uint256);

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
     * @notice add reward token
     */
    function stopRewardToken(address token) external;

    /**
     * @notice reward token count
     */
    function rewardTokenCount() external view returns (uint256);

    /**
     * @notice is distributable reward token
     */
    function isDistributableRewardToken(address token) external view returns (bool);

    /**
     * @notice check reward token
     */
    function rewardTokenStopped(address token) external view returns (bool);

    /**
     * @notice reward tokens
     */
    function rewardTokens() external view returns (address[] memory);
}

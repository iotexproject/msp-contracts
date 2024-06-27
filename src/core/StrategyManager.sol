// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyManager.sol";

contract StrategyManager is IStrategyManager, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_REWARD_TOKEN = 32;
    uint256 public constant MAX_STRATEGY = 32;
    uint256 public constant RATIO_FACTOR = 100;
    address public constant IOTX_REWARD_TOKEN = address(1);
    uint256 public constant PRECISION_FACTOR = 12;

    mapping(address => uint256) public override strategyRatio;

    EnumerableSet.AddressSet _strategySet;
    EnumerableSet.AddressSet _rewardTokenSet;

    function initialize() public initializer {
        __Ownable_init_unchained();

        _rewardTokenSet.add(IOTX_REWARD_TOKEN);
        emit AddRewardToken(IOTX_REWARD_TOKEN);
    }

    function addStrategy(address strategy, uint256 ratio) external override onlyOwner {
        require(strategy != address(0), "zero address");
        require(_strategySet.length() < MAX_STRATEGY, "exceed max strategy");
        require(ratio > 10 && ratio < 5000, "invalid ratio");
        require(!_strategySet.contains(strategy), "strategy exist");
        require(IStrategy(strategy).strategyManager() == address(this), "invalid strategy manager");

        _strategySet.add(strategy);
        strategyRatio[strategy] = ratio;

        emit AddStrategy(strategy, ratio);
    }

    function removeStrategy(address strategy) external override onlyOwner {
        require(_strategySet.contains(strategy), "strategy not exist");

        _strategySet.remove(strategy);
        strategyRatio[strategy] = 0;

        emit RemoveStrategy(strategy);
    }

    function changeStrategyRatio(address strategy, uint256 ratio) external override onlyOwner {
        require(_strategySet.contains(strategy), "strategy not exist");
        require(ratio > 10 && ratio < 5000, "invalid ratio");

        strategyRatio[strategy] = ratio;

        emit ChangeStrategyRatio(strategy, ratio);
    }

    function strategyCount() external view override returns (uint256) {
        return _strategySet.length();
    }

    function strategies() external view override returns (address[] memory) {
        return _strategySet.values();
    }

    function shares(address staker) external view override returns (uint256) {
        address[] memory _strategies = _strategySet.values();
        uint256 result = 0;
        for (uint256 i = 0; i < _strategies.length; i++) {
            address strategy = _strategies[i];
            uint256 ratio = strategyRatio[strategy];

            result += IStrategy(_strategies[i]).amount(staker) * ratio / RATIO_FACTOR;
        }

        return result;
    }

    function shares(address staker, address strategy) external view override returns (uint256) {
        uint256 ratio = strategyRatio[strategy];
        require(ratio > 0, "strategy not exist");

        return IStrategy(strategy).amount(staker) * ratio / RATIO_FACTOR;
    }

    function totalShares() public view override returns (uint256) {
        address[] memory _strategies = _strategySet.values();
        uint256 result = 0;
        for (uint256 i = 0; i < _strategies.length; i++) {
            address strategy = _strategies[i];
            uint256 ratio = strategyRatio[strategy];

            result += IStrategy(_strategies[i]).totalAmount() * ratio / RATIO_FACTOR;
        }

        return result;
    }

    function totalShares(address strategy) public view override returns (uint256) {
        uint256 ratio = strategyRatio[strategy];
        require(ratio > 0, "strategy not exist");

        return IStrategy(strategy).totalAmount() * ratio / RATIO_FACTOR;
    }

    function addRewardToken(address token) external override onlyOwner {
        require(token != address(0), "zero address");
        require(_rewardTokenSet.length() < MAX_REWARD_TOKEN, "exceed max reward token");
        require(!_rewardTokenSet.contains(token), "token exist");

        _rewardTokenSet.add(token);

        emit AddRewardToken(token);
    }

    function removeRewardToken(address token) external override onlyOwner {
        require(token != IOTX_REWARD_TOKEN, "invalid token");
        require(_rewardTokenSet.contains(token), "token not exist");

        _rewardTokenSet.remove(token);

        emit RemoveRewardToken(token);
    }

    function isRewardToken(address token) public view override returns (bool) {
        return _rewardTokenSet.contains(token);
    }

    function rewardTokenCount() external view override returns (uint256) {
        return _rewardTokenSet.length();
    }

    function rewardTokens() external view override returns (address[] memory) {
        return _rewardTokenSet.values();
    }

    function distributeRewards(address token, uint256 amount) external payable override returns (bool) {
        require(_rewardTokenSet.contains(token), "not distributable");
        if (token == IOTX_REWARD_TOKEN) {
            require(amount == msg.value, "rewards dismatch");
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        uint256 _totalShares = totalShares();
        uint256 _perShare = amount * PRECISION_FACTOR / _totalShares;

        address[] memory _strategies = _strategySet.values();
        for (uint256 i = 0; i < _strategies.length; i++) {
            address strategy = _strategies[i];
            uint256 rewards = _perShare * totalShares(strategy) / PRECISION_FACTOR;

            if (rewards > 0) {
                if (token == IOTX_REWARD_TOKEN) {
                    IStrategy(strategy).distributeRewards{value: rewards}(token, rewards);
                } else {
                    IERC20(token).safeApprove(strategy, rewards);
                    IStrategy(strategy).distributeRewards(token, rewards);
                }
            }

            emit DistributeRewards(strategy, token, rewards);
        }

        return true;
    }
}

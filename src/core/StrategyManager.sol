// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IVoter.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyManager.sol";
import "../interfaces/IRatioManager.sol";

contract StrategyManager is IStrategyManager, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_REWARD_TOKEN = 32;
    uint256 public constant MAX_STRATEGY = 32;
    address public constant IOTX_REWARD_TOKEN = address(1);
    uint256 public constant PRECISION_FACTOR = 12;

    address public ratioManager;
    address public voter;

    EnumerableSet.AddressSet _strategySet;
    EnumerableSet.AddressSet _rewardTokenSet;

    function initialize(address _ratioManager) public initializer {
        __Ownable_init_unchained();

        ratioManager = _ratioManager;
        _rewardTokenSet.add(IOTX_REWARD_TOKEN);
        emit AddRewardToken(IOTX_REWARD_TOKEN);
    }

    function addStrategy(address strategy) external override onlyOwner {
        require(strategy != address(0), "zero address");
        require(_strategySet.length() < MAX_STRATEGY, "exceed max strategy");

        IStrategy _strategy = IStrategy(strategy);
        require(IRatioManager(ratioManager).isSupportedToken(_strategy.underlyingToken()));
        require(!_strategySet.contains(strategy), "strategy exist");
        require(_strategy.strategyManager() == address(this), "invalid strategy manager");

        _strategySet.add(strategy);

        emit AddStrategy(strategy);
    }

    function removeStrategy(address strategy) external override onlyOwner {
        require(_strategySet.contains(strategy), "strategy not exist");

        _strategySet.remove(strategy);

        emit RemoveStrategy(strategy);
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
            IStrategy strategy = IStrategy(_strategies[i]);
            result += IRatioManager(ratioManager).getTargetAmount(strategy.underlyingToken(), strategy.amount(staker));
        }

        return result;
    }

    function shares(address staker, address strategy) external view override returns (uint256) {
        IStrategy _strategy = IStrategy(strategy);

        return IRatioManager(ratioManager).getTargetAmount(_strategy.underlyingToken(), _strategy.amount(staker));
    }

    function totalShares() public view override returns (uint256) {
        address[] memory _strategies = _strategySet.values();
        uint256 result = 0;
        for (uint256 i = 0; i < _strategies.length; i++) {
            IStrategy strategy = IStrategy(_strategies[i]);

            result += IRatioManager(ratioManager).getTargetAmount(strategy.underlyingToken(), strategy.totalAmount());
        }

        return result;
    }

    function totalShares(address strategy) public view override returns (uint256) {
        IStrategy _strategy = IStrategy(strategy);

        return IRatioManager(ratioManager).getTargetAmount(_strategy.underlyingToken(), _strategy.totalAmount());
    }

    function addRewardToken(address token) external override onlyOwner {
        require(token != address(0), "zero address");
        require(_rewardTokenSet.length() < MAX_REWARD_TOKEN, "exceed max reward token");
        require(!_rewardTokenSet.contains(token), "token exist");

        _rewardTokenSet.add(token);

        emit AddRewardToken(token);
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0), "zero address");

        voter = _voter;
        emit SetVoter(_voter);
    }

    function changeRatioManager(address _ratioManager) external onlyOwner {
        require(_ratioManager != address(0), "zero address");

        address[] memory _strategies = _strategySet.values();
        for (uint256 i = 0; i < _strategies.length; i++) {
            require(
                IRatioManager(_ratioManager).isSupportedToken(IStrategy(_strategies[i]).underlyingToken()),
                "unsupport token"
            );
        }
        ratioManager = _ratioManager;
        emit ChangeRatioManager(_ratioManager);
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

    function poke(address user) external {
        IVoter(voter).poke(user);
    }
}

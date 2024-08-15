// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyManager.sol";

abstract contract BaseStrategy is IStrategy, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    event ReceiveRewards(address indexed sender, address indexed token, uint256 amount);
    event ClaimReward(address indexed token, address indexed staker, uint256 amount);

    address public constant IOTX_REWARD_TOKEN = address(1);
    uint256 public constant PRECISION_FACTOR = 12;

    /// @inheritdoc IStrategy
    address public override underlyingToken;

    /// @inheritdoc IStrategy
    uint256 public override totalAmount;

    /// @inheritdoc IStrategy
    mapping(address => uint256) public override amount;

    /// @inheritdoc IStrategy
    address public override strategyManager;

    // token address -> reward
    mapping(address => uint256) public remainingReward;

    // token address -> per amount
    mapping(address => uint256) public accTokenPerAmount;

    // token address -> staker address -> reward debt
    mapping(address => mapping(address => uint256)) public rewardDebt;

    function __BaseStrategy_init(address underlyingToken_, address strategyManager_) internal onlyInitializing {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        underlyingToken = underlyingToken_;
        strategyManager = strategyManager_;
    }

    /// @inheritdoc IStrategy
    function distributeRewards(address _token, uint256 _amount) external payable virtual override {
        require(IStrategyManager(strategyManager).isRewardToken(_token), "not reward token");
        if (_token == IOTX_REWARD_TOKEN) {
            require(_amount == msg.value, "rewards dismatch");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        // todo. if totalAmount == 0, the rewardValue will not be claim
        if (totalAmount > 0) {
            accTokenPerAmount[_token] = accTokenPerAmount[_token] + (_amount * PRECISION_FACTOR) / totalAmount;
        }

        emit ReceiveRewards(msg.sender, _token, _amount);
    }

    function pendingRewards(address staker) public view returns (uint256[] memory) {
        address[] memory rewardTokens = IStrategyManager(strategyManager).rewardTokens();
        uint256[] memory result = new uint256[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            result[i] = pendingReward(token, staker);
        }

        return result;
    }

    function pendingReward(address token, address staker) public view returns (uint256) {
        uint256 _accTokenPerAmount = accTokenPerAmount[token];
        if (_accTokenPerAmount == 0) {
            return 0;
        }
        return amount[staker] * accTokenPerAmount[token] / PRECISION_FACTOR - rewardDebt[token][staker];
    }

    function pendingReward(address _token, address _staker, uint256 _amount) internal view returns (uint256) {
        uint256 _accTokenPerAmount = accTokenPerAmount[_token];
        // todo. maybe only check _accTokenPerAmount==0?
        if (_amount == 0 && _accTokenPerAmount == 0) {
            return 0;
        }
        return _amount * _accTokenPerAmount / PRECISION_FACTOR - rewardDebt[_token][_staker];
    }

    function claimReward(address token) external nonReentrant {
        uint256 reward = pendingReward(token, msg.sender);
        if (reward > 0) {
            // todo. whether rewardDebt[token][msg.sender] += reward?
            rewardDebt[token][msg.sender] = amount[msg.sender] * accTokenPerAmount[token] / PRECISION_FACTOR;
            if (token == IOTX_REWARD_TOKEN) {
                payable(msg.sender).sendValue(reward);
            } else {
                IERC20(token).safeTransfer(msg.sender, reward);
            }

            emit ClaimReward(token, msg.sender, reward);
        }
    }

    function claimReward() external nonReentrant {
        uint256 reward = pendingReward(IOTX_REWARD_TOKEN, msg.sender);
        if (reward > 0) {
            // todo. whether rewardDebt[token][msg.sender] += reward?
            rewardDebt[IOTX_REWARD_TOKEN][msg.sender] =
                amount[msg.sender] * accTokenPerAmount[IOTX_REWARD_TOKEN] / PRECISION_FACTOR;
            payable(msg.sender).sendValue(reward);

            emit ClaimReward(IOTX_REWARD_TOKEN, msg.sender, reward);
        }

        address[] memory rewardTokens = IStrategyManager(strategyManager).rewardTokens();
        if (rewardTokens.length > 1) {
            for (uint256 i = 1; i < rewardTokens.length; i++) {
                address token = rewardTokens[i];
                reward = pendingReward(token, msg.sender);
                if (reward > 0) {
                    // todo. whether rewardDebt[token][msg.sender] += reward?
                    rewardDebt[token][msg.sender] = amount[msg.sender] * accTokenPerAmount[token] / PRECISION_FACTOR;
                    IERC20(token).safeTransfer(msg.sender, reward);

                    emit ClaimReward(token, msg.sender, reward);
                }
            }
        }
    }

    function _claimReward(address staker, uint256 originAmount, uint256 newAmount) internal {
        uint256 reward = pendingReward(IOTX_REWARD_TOKEN, staker, originAmount);
        if (reward > 0) {
            payable(staker).sendValue(reward);

            emit ClaimReward(IOTX_REWARD_TOKEN, staker, reward);
        }
        // todo. maybe move forward follow patten: Checks-Effects-Interactions
        uint256 _accTokenPerAmount = accTokenPerAmount[IOTX_REWARD_TOKEN];
        if (_accTokenPerAmount > 0) {
            rewardDebt[IOTX_REWARD_TOKEN][staker] = newAmount * _accTokenPerAmount / PRECISION_FACTOR;
        }

        address[] memory rewardTokens = IStrategyManager(strategyManager).rewardTokens();
        if (rewardTokens.length > 1) {
            for (uint256 i = 1; i < rewardTokens.length; i++) {
                address token = rewardTokens[i];
                reward = pendingReward(token, staker, originAmount);
                if (reward > 0) {
                    IERC20(token).safeTransfer(staker, reward);

                    emit ClaimReward(token, staker, reward);
                }
                _accTokenPerAmount = accTokenPerAmount[token];
                if (_accTokenPerAmount > 0) {
                    // todo. maybe move forward follow patten: Checks-Effects-Interactions
                    rewardDebt[token][staker] = newAmount * _accTokenPerAmount / PRECISION_FACTOR;
                }
            }
        }
    }

    uint256[30] private __gap;
}

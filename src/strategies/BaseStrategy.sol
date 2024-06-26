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
        require(IStrategyManager(strategyManager).isDistributableRewardToken(_token), "not distributable");
        if (_token == IOTX_REWARD_TOKEN) {
            require(_amount == msg.value, "rewards dismatch");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        if (totalAmount > 0) {
            accTokenPerAmount[_token] = accTokenPerAmount[_token] + (_amount * PRECISION_FACTOR) / totalAmount;
        }

        emit ReceiveRewards(msg.sender, _token, _amount);
    }

    function pendingReward(address token, address staker) public view returns (uint256) {
        return amount[staker] * accTokenPerAmount[token] / PRECISION_FACTOR - rewardDebt[token][staker];
    }

    function claimReward() external nonReentrant {
        _claimReward(msg.sender);
    }

    function _claimReward(address staker) internal {
        uint256 reward = pendingReward(IOTX_REWARD_TOKEN, staker);
        if (reward > 0) {
            rewardDebt[IOTX_REWARD_TOKEN][staker] =
                amount[staker] * accTokenPerAmount[IOTX_REWARD_TOKEN] / PRECISION_FACTOR;
            payable(staker).sendValue(reward);

            emit ClaimReward(IOTX_REWARD_TOKEN, staker, reward);
        }

        address[] memory rewardTokens = IStrategyManager(strategyManager).rewardTokens();
        if (rewardTokens.length > 1) {
            for (uint256 i = 1; i < rewardTokens.length; i++) {
                address token = rewardTokens[i];
                reward = pendingReward(token, staker);
                if (reward > 0) {
                    rewardDebt[token][staker] = amount[staker] * accTokenPerAmount[token] / PRECISION_FACTOR;
                    IERC20(token).safeTransfer(staker, reward);

                    emit ClaimReward(token, staker, reward);
                }
            }
        }
    }

    uint256[30] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IBucketRewardPool.sol";

contract BucketRewardPool is IBucketRewardPool, OwnableUpgradeable {
    using Address for address payable;

    event SetCommitter(address indexed committer);
    event SetApprover(address indexed approver);

    uint256 public currentbatch;
    address public committer;
    address public approver;
    mapping(uint256 => bytes32) public override batchRoot;
    mapping(uint256 => bool) public override approvedBatch;
    mapping(uint256 => mapping(uint256 => uint256)) public claimed;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    function setCommitter(address newCommitter) external onlyOwner {
        require(newCommitter != address(0), "zero address");

        committer = newCommitter;
        emit SetCommitter(newCommitter);
    }

    function setApprover(address newApprover) external onlyOwner {
        require(newApprover != address(0), "zero address");

        approver = newApprover;
        emit SetApprover(newApprover);
    }

    function claim(uint256 batch, address owner, uint256 bucketId, uint256 value, bytes32[] calldata proof)
        external
        override
    {
        require(approvedBatch[batch], "invalid batch");
        require(claimed[batch][bucketId] == 0, "claimed");
        bytes32 node = keccak256(abi.encodePacked(batch, owner, bucketId, value));
        require(MerkleProof.verify(proof, batchRoot[batch], node), "invalid proof");
        payable(msg.sender).sendValue(value);
    }

    function claim(
        uint256 batch,
        address owner,
        uint256 bucketId,
        uint256 value,
        address receiver,
        bytes32[] calldata proof
    ) external override {
        require(owner == msg.sender, "invalid owner");
        require(approvedBatch[batch], "invalid batch");
        require(claimed[batch][bucketId] == 0, "claimed");
        bytes32 node = keccak256(abi.encodePacked(batch, owner, bucketId, value));
        require(MerkleProof.verify(proof, batchRoot[batch], node), "invalid proof");
        payable(receiver).sendValue(value);
    }

    function commitRoot(uint256 batch, bytes32 root) external override {
        require(committer == msg.sender, "not committer");
        require(!approvedBatch[batch], "already approved");
        require(root != bytes32(0), "invalid root");

        batchRoot[batch] = root;
        emit CommitRoot(msg.sender, batch, root);
    }

    function approveRoot(uint256 batch) external override {
        require(approver == msg.sender, "not approver");
        require(!approvedBatch[batch], "already approved");

        approvedBatch[batch] = true;
        emit ApproveRoot(msg.sender, batch);
    }

    receive() external payable {
        uint256 batch = ++currentbatch;
        emit BatchReward(msg.sender, batch, msg.value);
    }
}

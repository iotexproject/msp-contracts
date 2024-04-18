// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDelegationManager {
    // @notice Struct used for storing information about a single operator who has registered with MSP
    struct OperatorDetails {
        // @notice address to receive the rewards that the operator earns via serving applications built on EigenLayer.
        address earningsReceiver;
        /**
         * @notice Address to verify signatures when a staker wishes to delegate to the operator, as well as controlling "forced undelegations".
         * @dev Signature verification follows these rules:
         * 1) If this address is left as address(0), then any staker will be free to delegate to the operator, i.e. no signature verification will be performed.
         * 2) If this address is an EOA (i.e. it has no code), then we follow standard ECDSA signature verification for delegations to the operator.
         * 3) If this address is a contract (i.e. it has code) then we forward a call to the contract and verify that it returns the correct EIP-1271 "magic value".
         */
        address delegationApprover;
        /**
         * @notice A minimum delay -- measured in blocks -- enforced between:
         * 1) the operator signalling their intent to register for a service, via calling `Slasher.optIntoSlashing`
         * and
         * 2) the operator completing registration for the service, via the service ultimately calling `Slasher.recordFirstStakeUpdate`
         * @dev note that for a specific operator, this value *cannot decrease*, i.e. if the operator wishes to modify their OperatorDetails,
         * then they are only allowed to either increase this value or keep it the same.
         */
        uint32 stakerOptOutWindowBlocks;
    }

    /**
     * @notice Registers the caller as an operator in MSP.
     * @param registeringOperatorDetails is the `OperatorDetails` for the operator.
     * @param metadataURI is a URI for the operator's metadata, i.e. a link providing more details on the operator.
     *
     * @dev Once an operator is registered, they cannot 'deregister' as an operator, and they will forever be considered "delegated to themself".
     * @dev This function will revert if the caller attempts to set their `earningsReceiver` to address(0).
     * @dev Note that the `metadataURI` is *never stored * and is only emitted in the `OperatorMetadataURIUpdated` event
     */
    function registerAsOperator(
        OperatorDetails calldata registeringOperatorDetails,
        string calldata metadataURI
    ) external;

    /**
     * @notice Caller delegates their stake to an operator.
     * @param operator The account (`msg.sender`) is delegating its assets to for use in serving applications built on MSP.
     */
    function delegateTo(
        address operator
    ) external;
}

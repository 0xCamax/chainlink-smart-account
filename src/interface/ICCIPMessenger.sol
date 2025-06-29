// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../../lib/chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {Call} from "./IBaseAccount.sol";

interface ICCIPMessenger {
    // Custom error
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

    // Event emitted after sending a CCIP message
    event Message(bytes32 messageId);

    /// @notice Executes a cross-chain message via CCIP
    /// @param calls The calldata to be executed on destination chain
    /// @param config Configuration for CCIP transmission (chain, feeToken, tokens, extraArgs)
    /// @return messageId ID of the sent CCIP message
    function executeCCIP(
        Call[] calldata calls,
        Config calldata config
    ) external returns (bytes32 messageId);

    /// @notice Handles incoming CCIP messages from the router
    /// @param message The CCIP message data from the router
    function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// Struct definition must be included here too, since it's used in the interface
struct Config {
    uint64 chain;
    address feeToken;
    Client.EVMTokenAmount[] transferTokens;
    Client.GenericExtraArgsV2 extraArgs;
}

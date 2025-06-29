// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Call} from "../interface/IBaseAccount.sol";
import {ICronUpkeep} from "./ICronUpkeep.sol";

interface IAutomation is ICronUpkeep {
    enum UpkeepType {
        CRONJOB,
        CONDITIONAL
    }

    struct PerformData {
        UpkeepType upkeepType;
        bytes performData;
    }

    /// @notice Registers a new upkeep with the Chainlink Automation Registrar.
    /// @param name Human-readable name of the upkeep
    /// @param gasLimit Maximum gas the upkeep is allowed to use
    /// @param offchainConfig Optional off-chain configuration
    /// @param amount Amount of LINK to fund the upkeep
    /// @param nonce Nonce used to calculate the forwarder address
    function registerUpkeep(
        string calldata name,
        uint32 gasLimit,
        bytes calldata offchainConfig,
        uint96 amount,
        uint32 nonce
    ) external payable;

    /// @notice Checks whether any upkeep (cron or conditional) needs to be performed.
    /// @param checkData Custom data to pass to conditional upkeep
    /// @return upkeepNeeded True if an upkeep should be performed
    /// @return performData Encoded PerformData struct
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    /// @notice Performs an upkeep (cron or conditional) based on the encoded data.
    /// @param performData Encoded PerformData struct containing the type and payload
    function performUpkeep(bytes calldata performData) external;

    /// @notice Sets the address allowed to run conditional logic checks.
    /// @param delegatee Address of the contract implementing `checkUpkeep`
    function setConditionDelegatee(address delegatee) external;

    /// @notice Grants or revokes permission to a forwarder to call restricted functions.
    /// @param newForwarder The forwarder address
    /// @param allowed True to allow, false to revoke
    function setForwarder(address newForwarder, bool allowed) external;
}

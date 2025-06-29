// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct RegistrationParams {
    address upkeepContract;
    uint96 amount;
    // 1 word full
    address adminAddress;
    uint32 gasLimit;
    uint8 triggerType;
    // 7 bytes left in 2nd word
    address billingToken;
    // 12 bytes left in 3rd word
    string name;
    bytes encryptedEmail;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
}
interface IAutomationRegistrar2_3 {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external payable returns (uint256);
}

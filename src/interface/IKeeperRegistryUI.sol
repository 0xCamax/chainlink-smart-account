// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */

  struct OnchainConfig {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend;
    uint32 maxPerformGas;
    uint32 maxCheckDataSize;
    uint32 maxPerformDataSize;
    uint32 maxRevertDataSize;
    uint256 fallbackGasPrice;
    uint256 fallbackLinkPrice;
    address transcoder;
    address[] registrars;
    address upkeepPrivilegeManager;
  }

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
  struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint96 totalPremium;
    uint256 numUpkeeps;
    uint32 configCount;
    uint32 latestConfigBlockNumber;
    bytes32 latestConfigDigest;
    uint32 latestEpoch;
    bool paused;
  }

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
    address target;
    uint32 executeGas;
    bytes checkData;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    uint32 lastPerformBlockNumber;
    uint96 amountSpent;
    bool paused;
    bytes offchainConfig;
}

interface AutomationRegistryBaseInterface {
    function cancelUpkeep(uint256 id) external;

    function pauseUpkeep(uint256 id) external;

    function unpauseUpkeep(uint256 id) external;

    function transferUpkeepAdmin(uint256 id, address proposed) external;

    function acceptUpkeepAdmin(uint256 id) external;

    function addFunds(uint256 id, uint96 amount) external;

    function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

    function getUpkeep(
        uint256 id
    ) external view returns (UpkeepInfo memory upkeepInfo);
}

interface IKeeperRegistryUI is AutomationRegistryBaseInterface {
    function setUpkeepCheckData(uint256 id, bytes calldata newCheckData) external;
    function setUpkeepOffchainConfig(
        uint256 id,
        bytes calldata config
    ) external;
    function withdrawFunds(uint256 id, address to) external;
    function getForwarder(uint256 upKeepId) external view returns (address);
}

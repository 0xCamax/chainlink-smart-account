# Chainlink Powered Smart Account

> **Modular EIP-7702 Account Abstraction with Chainlink CCIP, Automation, and Fee Token Integration**

## 🧩 Overview

`ChainlinkPoweredSmartAccount` is a modular and extensible smart account built on top of the EIP-7702 specification. It integrates powerful Chainlink services including:

- 🧬 **CCIP (Cross-Chain Interoperability Protocol)** for sending and receiving cross-chain messages
- ⏰ **Automation (Keepers)** for scheduled execution of tasks
- 💸 **Fee Token Logic** for paying gas in alternative tokens through a `PoolManager`

The design leverages `delegatecall` to keep the core account lightweight and enables flexible upgrades via logic contracts.

## 🚀 Workflow & User Experience

### Improved UX Through Streamlined Automation

The Chainlink Powered Smart Account revolutionizes automation UX by separating **infrastructure setup** from **job management**:

**🔧 Phase 1: One-Time Setup (Delegation)**

- Upkeep registration happens once during account delegation
- Establishes the foundational automation infrastructure
- Funds the upkeep with LINK tokens
- Configures forwarder permissions

**⚡ Phase 2: Dynamic Management (Ongoing)**

- Users can create, update, and eliminate CRON jobs
- Switch between custom conditional logic and CRON-based automation
- Perform complex automation changes in a single transaction
- Combine automation updates with other account operations

**Benefits:**

- 📈 **Reduced Setup Costs** - Single upkeep registration handles multiple job types
- 🎯 **Simplified UX** - No need to understand Chainlink's registration complexity
- 🔄 **Real-time Flexibility** - Instant job management without re-initialization
- 🏗️ **Composable Operations** - Mix automation with other smart account features
- 💡 **Dual Mode Support** - Seamlessly switch between CRON and conditional logic
- 🛡️ **Security** - Proper access controls and timing validation

---

## ⚙️ Key Features

### ✅ EIP-4337 Compatibility

- Inherits from `Simple7702Account`
- Fully compatible with ephemeral smart accounts and programmable session logic

### 🔗 Chainlink CCIP

- `executeCCIP(Call[], Config)` delegates execution to `CCIPLogic`, enabling secure message dispatching across chains
- `ccipReceive(Any2EVMMessage)` handles incoming messages and delegates to the same logic
- Makes use of `Client` library for message struct decoding

### ⏰ Chainlink Automation

- Inherits `Automation` logic
- Interfaces with `IKeeperRegistryUI` and `IAutomationRegistrar2_3` for upkeeps
- Stores upkeep-related metadata in deterministic storage slots

### 💸 Fee Token Support

- `setFeeTokenInfo()` and `feeTokenInfo()` allow the account to set or read custom fee tokens
- Supports `ETH` or ERC-20 tokens as gas tokens
- Interacts with a `PoolManager` to unlock funds and provide pre-funding logic via `_payPrefund`

---

## 🧱 Architecture

```mermaid
graph TD
  A[ChainlinkPoweredSmartAccount] -->|inherits| B[Simple7702Account]
  A -->|inherits| C[Automation]
  A -->|inherits| D[ChainlinkAccountConstants]
  A --> E[CCIPLogic (delegatecall)]
  A --> F[FeeTokenLogic (delegatecall)]
  A --> G[PoolManager]
  A --> H[KeeperRegistry & Registrar]
```

---

## 🧭 Automation Module

The `Automation` contract integrates **Chainlink Automation (Keepers)** and extends `CronUpkeep` to allow scheduling tasks via:

- 📅 **CRON-based automation**
- 🧪 **Custom conditional checks via delegatees**

It is fully self-managed and can register its own upkeeps, manage forwarders, and perform batch executions.

### 🧩 How It Works

#### 1. One-Time Upkeep Registration (Initialization)

```solidity
registerUpkeep(
  string name,
  uint32 gasLimit,
  bytes offchainConfig,
  bytes checkData,
  uint96 amount
);
```

**This is a one-time initialization step performed during account delegation:**

- Registers a new upkeep using the AutomationRegistrar
- Funds the upkeep using LINK (`s_linkToken.approve(...)`)
- Automatically retrieves the Chainlink forwarder from `keeperRegister.getForwarder(...)` and authorizes it
- Sets up the foundational automation infrastructure for the account

#### 2. Dynamic Job Management (Post-Initialization)

**After initialization, users can manage automation using the inherited CronUpkeep functions:**

```solidity
// Create new CRON jobs from encoded specs
createCronJobFromSpec(Call[] calls, Spec spec);

// Update existing CRON jobs
updateCronJob(uint256 id, Call[] newCall, bytes newEncodedCronSpec);

// Delete CRON jobs
deleteCronJob(uint256 id);

// Set custom conditional logic
setConditionDelegatee(address delegatee);
```

**Available CronUpkeep Management:**

- `getActiveCronJobIDs()` - Returns all active cron job IDs
- `getCronJob(uint256 id)` - Returns job details (calls, cronString, nextTick)
- Jobs are managed through the `onlyCronjobManager` modifier (account itself or EntryPoint)

**Enhanced UX Features:**

- ✅ **Flexible Job Management** - Create, update, and delete CRON jobs independently
- ✅ **Hot-Swap Logic** - Change conditional logic without re-registering upkeeps
- ✅ **State Persistence** - Jobs survive across conditional logic changes
- ✅ **Dual Trigger Support** - Both CRON and custom conditional logic in one upkeep

#### 3. Upkeep Management

- Registered upkeep IDs are stored in `mapping(bytes32 => uint256[]) upkeeps` under the `UPKEEPS_ID_SLOT`
- Validates and stores forwarder access for `performUpkeep`

#### 4. Check Logic (Chainlink-Compatible)

```solidity
function checkUpkeep(bytes calldata checkData) external view returns (bool, bytes memory);
```

**Smart Dual-Mode Checking:**

1. **Custom Conditional Logic** - First checks `CONDITION_DELEGATEE_SLOT` for custom delegatee

   - If delegatee exists: calls `ICheckUpkeep(conditionDelegatee).checkUpkeep(...)`
   - Returns `PerformData` with `UpkeepType.CUSTOM`

2. **CRON Job Logic** - If no custom condition needed, checks scheduled CRON jobs
   - Uses round-robin checking starting from `block.number % numCrons`
   - Validates if any job's `lastTick > s_lastRuns[id]`
   - Returns `PerformData` with `UpkeepType.CRONJOB` and encoded `(id, tickTime, calls)`

#### 5. Perform Logic

```solidity
function performUpkeep(bytes calldata performData) external onlyForwarders;
```

**Dual Execution Paths:**

- **`UpkeepType.CRONJOB`**:
  - Decodes `(uint256 id, uint256 tickTime, Call[] calls)`
  - Validates timing with `_validate(id, tickTime)` (prevents future/old/mismatched ticks)
  - Executes calls and updates `s_lastRuns[id] = block.timestamp`
- **`UpkeepType.CUSTOM`**:
  - Decodes `Call[]` directly from performData
  - Executes immediately without timing validation

**Security Features:**

- `onlyForwarders` modifier restricts access to authorized Chainlink forwarders
- Timing validation prevents replay attacks and ensures proper scheduling
- Uses `IBaseAccount(address(this)).executeBatch(calls)` for execution

#### 6. Delegatee-Based Conditional Logic

```solidity
setConditionDelegatee(address delegatee);
```

- Allows dynamically plugging in custom check logic by storing a delegatee in `CONDITION_DELEGATEE_SLOT`
- Must be called by the account itself (`msg.sender == address(this)`)

#### 7. Secure Forwarder Control

```solidity
setForwarder(address newForwarder, bool allowed);
```

- Only trusted forwarders (retrieved from the registry) are allowed to call `performUpkeep`


### 🧩 Interfaces Used

- `AutomationCompatibleInterface` - Standard Chainlink automation interface
- `IAutomationRegistrar` - For registering new upkeeps
- `IKeeperRegistryUI` - For accessing upkeep data and forwarders
- `IAutomationForwarder` - Ensures forwarders route to correct registry and contract
- `IBaseAccount` - For executing batched calls through the smart account
- `CronUpkeep` - Extended for CRON job scheduling and management
- `ICheckUpkeep` - Interface for custom conditional logic delegates

---

## 📦 Usage Examples

### Trigger CCIP Execution

```solidity
chainlinkAccount.executeCCIP(calls, config)
```

### Receive CCIP Message (called automatically)

```solidity
function ccipReceive(Client.Any2EVMMessage calldata message) external;
```

### One-Time Initialization (During Account Delegation)

```solidity
// Performed once during account setup
registerUpkeep(
  "SmartAccountAutomation",
  2_000_000,                        // gasLimit
  abi.encodePacked(""),            // empty offchainConfig initially
  "",                              // empty checkData initially
  10 ether                         // amount in LINK
);
```

### Dynamic Management (Post-Initialization)

```solidity
// Create a new CRON job using encoded spec
Spec memory dailySpec = encodeCronString("0 0 * * *"); // Daily at midnight
createCronJobFromSpec(dailyCalls, dailySpec);

// Create multiple jobs
Spec memory hourlySpec = encodeCronString("0 * * * *"); // Hourly
createCronJobFromSpec(hourlyCalls, hourlySpec);

// Update existing job
updateCronJob(
    1,                                    // job ID
    updatedCalls,                        // new calls
    abi.encode(newSpec)                  // new encoded spec
);

// Delete job when no longer needed
deleteCronJob(2);

// Switch to custom conditional logic
setConditionDelegatee(customConditionalContract);

// Get job information
uint256[] memory activeJobs = getActiveCronJobIDs();
(Call[] memory calls, string memory cronString, uint256 nextTick) = getCronJob(1);
```

---

## ⚠️ Security Considerations

- `delegatecall` is strictly used with immutable addresses (`CCIPLogic`, `FeeTokenLogic`)
- Only Router can call CCIP, enforced at the delegated contract modifier
- `performUpkeep` is restricted to authorized forwarders only via `onlyForwarders` modifier
- All forwarders are validated via:
  ```solidity
  IAutomationForwarder(forwarder).getTarget() == address(this);
  IAutomationForwarder(forwarder).getRegistry() == keeperRegister;
  ```
- Custom condition logic is fully encapsulated in a delegatee, enhancing modularity
- CRON job timestamps are validated to prevent:
  - **Future ticks**: `block.timestamp < tickTime`
  - **Replay attacks**: `tickTime <= s_lastRuns[id]`
  - **Spec mismatches**: `!s_specs[id].matches(tickTime)`
- Job management restricted to account itself or EntryPoint via `onlyCronjobManager`
- Forwarder management restricted to account itself via `require(msg.sender == address(this))`

---

## 📝 Notes

This smart account serves as a powerful abstraction layer that simplifies the usage of Chainlink products such as CCIP, Automation, and gas fee management. It allows developers to offer users seamless cross-chain communication, scheduled execution, and flexible gas payments without exposing them to protocol-level complexity.

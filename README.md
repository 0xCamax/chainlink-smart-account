# Chainlink Powered Smart Account

> **Modular EIP-7702 Account Abstraction with Chainlink CCIP, Automation, and Fee Token Integration**

## 🧩 Overview

`ChainlinkPoweredSmartAccount` is a modular and extensible smart account built on top of the EIP-7702 specification. It integrates powerful Chainlink services including:

- 🧬 **CCIP (Cross-Chain Interoperability Protocol)** for sending and receiving cross-chain messages.
- ⏰ **Automation (Keepers)** for scheduled execution of tasks.
- 💸 **Fee Token Logic** for paying gas in alternative tokens through a `PoolManager`.

The design leverages `delegatecall` to keep the core account lightweight and enables flexible upgrades via logic contracts.

---

## ⚙️ Key Features

### ✅ EIP-4337 Compatibility

- Inherits from `Simple7702Account`.
- Fully compatible with ephemeral smart accounts and programmable session logic.

### 🔗 Chainlink CCIP

- `executeCCIP(Call[], Config)` delegates execution to `CCIPLogic`, enabling secure message dispatching across chains.
- `ccipReceive(Any2EVMMessage)` handles incoming messages and delegates to the same logic.
- Makes use of `Client` library for message struct decoding.

### ⏰ Chainlink Automation

- Inherits `Automation` logic.
- Interfaces with `IKeeperRegistryUI` and `IAutomationRegistrar2_3` for upkeeps.
- Stores upkeep-related metadata in deterministic storage slots.

### 💸 Fee Token Support

- `setFeeTokenInfo()` and `feeTokenInfo()` allow the account to set or read custom fee tokens.
- Supports `ETH` or ERC-20 tokens as gas tokens.
- Interacts with a `PoolManager` to unlock funds and provide pre-funding logic via `_payPrefund`.

---

## 🧱 Architecture

````mermaid
graph TD
  A[ChainlinkPoweredSmartAccount] -->|inherits| B[Simple7702Account]
  A -->|inherits| C[Automation]
  A -->|inherits| D[ChainlinkAccountConstants]
  A --> E[CCIPLogic (delegatecall)]
  A --> F[FeeTokenLogic (delegatecall)]
  A --> G[PoolManager]
  A --> H[KeeperRegistry & Registrar]

  ## 📦 Trigger CCIP Execution

  ```solidity
chainlinkAccount.executeCCIP(calls, config)
```
Receive CCIP Message (called automatically)
  ```solidity
function ccipReceive(Client.Any2EVMMessage calldata message) external;
```

##Security Considerations
delegatecall is strictly used with immutable addresses (CCIPLogic, FeeTokenLogic).

Only Router can call CCIP, enforced at the delegated contract modifier.

##Notes
This smart account serves as a powerful abstraction layer that simplifies the usage of Chainlink products such as CCIP, Automation, and gas fee management. It allows developers to offer users seamless cross-chain communication, scheduled execution, and flexible gas payments without exposing them to protocol-level complexity.

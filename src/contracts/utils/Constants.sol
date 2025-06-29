// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterClient} from "../../../lib/chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "../../../lib/chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IKeeperRegistryUI} from "../../interface/IKeeperRegistryUI.sol";
import {IAutomationRegistrar2_3} from "../../interface/IAutomationRegistrar.sol";
import {Currency} from "../../types/Currency.sol";
import {IPoolManager} from "../../interface/IPoolManager.sol";

abstract contract CCIPConstants {
    IRouterClient internal constant s_router =
        IRouterClient(0x141fa059441E0ca23ce184B6A78bafD2A517DdE8);

    LinkTokenInterface internal constant s_linkToken =
        LinkTokenInterface(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);
}

abstract contract AutomationConstants {
    IAutomationRegistrar2_3 internal constant registrar =
        IAutomationRegistrar2_3(0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad);

    IKeeperRegistryUI public constant keeperRegister =
        IKeeperRegistryUI(0x37D9dC70bfcd8BC77Ec2858836B923c560E891D1);

    bytes32 internal constant CONDITION_DELEGATEE_SLOT =
        keccak256("CONDITION_DELEGATEE_SLOT");
    bytes32 internal constant FORWARDER_SLOT = keccak256("FORWARDER_SLOT");
    bytes32 public constant UPKEEPS_ID_SLOT = keccak256("UPKEEPS_ID_SLOT");
    LinkTokenInterface internal constant s_linkToken =
        LinkTokenInterface(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);
}

abstract contract ChainlinkAccountConstants {
    bytes32 internal constant FEE_TOKEN_SLOT = keccak256("FEE_TOKEN_SLOT");
    address internal constant CCIPLogic =
        0x972171f5110a2bD2e3591346010e3273D68bF583;
    address internal constant FeeTokenLogic =
        address(0x7D3CBdAC374825d210e0f3eC4929f06B91F289ED);
    address internal constant poolManager =
        0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;
}

abstract contract FeeTokenConstants {
    bytes32 internal constant FEE_TOKEN_SLOT = keccak256("FEE_TOKEN_SLOT");
    IPoolManager internal constant poolManager =
        IPoolManager(0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
}

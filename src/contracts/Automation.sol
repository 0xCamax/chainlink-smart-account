// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationCompatibleInterface as ICheckUpkeep} from "../../lib/chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {CronUpkeep} from "../../lib/chainlink/contracts/src/v0.8/automation/upkeeps/CronUpkeep.sol";
import {Call, IBaseAccount} from "../interface/IBaseAccount.sol";
import {AutomationConstants} from "./utils/Constants.sol";
import {IAutomationForwarder} from "../interface/IAutomationForwarder.sol";
import {RegistrationParams} from "../interface/IAutomationRegistrar.sol";

enum UpkeepType {
    CRONJOB,
    CUSTOM
}
struct PerformData {
    UpkeepType upkeepType;
    bytes performData;
}

contract Automation is CronUpkeep, AutomationConstants {
    mapping(address => bool) internal forwarders;
    mapping(bytes32 => uint256[]) public upkeeps;

    modifier onlyForwarders() {
        require(forwarders[msg.sender], "Forwarder: not allowed");
        _;
    }

    function registerUpkeep(
        string memory name,
        uint32 gasLimit,
        bytes memory offchainConfig,
        bytes memory checkData,
        uint96 amount
    ) external payable {
        s_linkToken.approve(address(registrar), amount);
        uint256 upkeepID = registrar.registerUpkeep{value: 0}(
            RegistrationParams({
                name: name,
                encryptedEmail: "",
                upkeepContract: address(this),
                gasLimit: gasLimit,
                adminAddress: address(this),
                triggerType: 0,
                checkData: checkData,
                triggerConfig: "",
                offchainConfig: offchainConfig,
                amount: amount,
                billingToken: address(s_linkToken)
            })
        );

        _saveId(upkeepID);
        address forwarder = keeperRegister.getForwarder(upkeepID);
        setForwarder(_checkForwarder(forwarder), true);
    }

    function _saveId(uint256 id) internal {
        upkeeps[UPKEEPS_ID_SLOT].push(id);
    }

    function _checkForwarder(
        address forwarder
    ) internal view returns (address) {
        require(
            IAutomationForwarder(forwarder).getTarget() == address(this) &&
                IAutomationForwarder(forwarder).getRegistry() ==
                address(keeperRegister),
            "Invalid forwarder"
        );
        return forwarder;
    }

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool, bytes memory) {
        (
            bool customNeeded,
            bytes memory conditionalPerformData
        ) = _checkCondition(checkData);

        if (customNeeded) {
            return (
                customNeeded,
                abi.encode(
                    PerformData(UpkeepType.CUSTOM, conditionalPerformData)
                )
            );
        }
        (
            bool cronJobNeeded,
            bytes memory cronJobPerformData
        ) = _checkCronJobs();
        if (cronJobNeeded) {
            return (
                cronJobNeeded,
                abi.encode(PerformData(UpkeepType.CRONJOB, cronJobPerformData))
            );
        }
        return (false, bytes(""));
    }

    function performUpkeep(bytes calldata performData) external onlyForwarders {
        PerformData memory _performData = abi.decode(
            performData,
            (PerformData)
        );
        if (_performData.upkeepType == UpkeepType.CRONJOB) {
            (uint256 id, uint256 tickTime, Call[] memory calls) = abi.decode(
                _performData.performData,
                (uint256, uint256, Call[])
            );
            _validate(id, tickTime);
            _perform(calls);
            s_lastRuns[id] = block.timestamp;
        }
        if (_performData.upkeepType == UpkeepType.CUSTOM) {
            Call[] memory calls = abi.decode(performData, (Call[]));
            _perform(calls);
        }
    }
    function _checkCondition(
        bytes calldata checkData
    ) internal view returns (bool upkeepNeeded, bytes memory performData) {
        bytes32 s_slot = CONDITION_DELEGATEE_SLOT;
        address conditionDelegatee;
        assembly {
            conditionDelegatee := sload(s_slot)
        }
        if (conditionDelegatee != address(0)) {
            (upkeepNeeded, performData) = ICheckUpkeep(conditionDelegatee)
                .checkUpkeep(checkData);
        }
    }

    function _perform(Call[] memory calls) internal {
        IBaseAccount(address(this)).executeBatch(calls);
    }

    function setConditionDelegatee(address delegatee) external {
        require(msg.sender == address(this), "Ownable: Not Allowed");
        bytes32 slot = CONDITION_DELEGATEE_SLOT;
        assembly {
            sstore(slot, delegatee)
        }
    }

    function setForwarder(address newForwarder, bool allowed) public {
        require(msg.sender == address(this), "Ownable: Not Allowed");
        forwarders[newForwarder] = allowed;
    }
}

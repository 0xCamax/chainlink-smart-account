// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Simple7702Account} from "../lib/account-abstraction/contracts/accounts/Simple7702Account.sol";
import {IAny2EVMMessageReceiver} from "./interface/IAny2EVMMessageReceiver.sol";
import {ICCIPMessenger, Config} from "./interface/ICCIPMessenger.sol";
import {IAutomation} from "./interface/IAutomation.sol";
import {ChainlinkAccountConstants} from "./contracts/utils/Constants.sol";
import {Client} from "../lib/chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {Automation} from "./contracts/Automation.sol";
import {IPoolManager} from "./interface/IPoolManager.sol";

contract ChainlinkPoweredSmartAccount is
    Simple7702Account,
    ChainlinkAccountConstants,
    Automation
{
    error PerformUpkeepError();
    error CheckUpkeepError();
    error ExecuteCCIPError();
    error ReceiveCCIPError();
    error FeeTokenError();
    error NotPoolManager();
    error Unknown(bytes);

    function supportsInterface(bytes4 id) public pure override returns (bool) {
        return (super.supportsInterface(id) ||
            id == type(IAny2EVMMessageReceiver).interfaceId);
    }

    function executeCCIP(
        Call[] calldata,
        Config calldata
    ) external returns (bytes32 messageId) {
        (bool success, bytes memory returnData) = CCIPLogic.delegatecall(
            msg.data
        );
        if (!success) {
            revert ExecuteCCIPError();
        }
        return abi.decode(returnData, (bytes32));
    }

    function ccipReceive(Client.Any2EVMMessage calldata) external {
        (bool success, ) = CCIPLogic.delegatecall(msg.data);
        if (!success) {
            revert ReceiveCCIPError();
        }
    }

    function setFeeTokenInfo(uint96 maxFee, address token) public {
        require(msg.sender == address(this), "Not allowed");
        bytes32 slot = FEE_TOKEN_SLOT;
        assembly {
            let data := or(
                shl(160, maxFee),
                and(token, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            )
            sstore(slot, data)
        }
    }

    function feeTokenInfo() public view returns (uint96 maxFee, address token) {
        bytes32 slot = FEE_TOKEN_SLOT;
        assembly {
            let data := sload(slot)
            maxFee := shr(160, data)
            token := and(data, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    function _payPrefund(uint256 missingAccountFunds) internal override {
        (, address feeToken) = feeTokenInfo();
        if (missingAccountFunds != 0) {
            if (feeToken == address(0)) {
                (bool success, ) = payable(msg.sender).call{
                    value: missingAccountFunds
                }("");
                (success);
            } else {
                IPoolManager(poolManager).unlock(
                    abi.encode(missingAccountFunds, msg.sender)
                );
            }
        }
    }

    modifier onlyPoolManager() {
        if (msg.sender != poolManager) revert NotPoolManager();
        _;
    }

    function unlockCallback(
        bytes calldata
    ) external onlyPoolManager returns (bytes memory) {
        (bool success, ) = FeeTokenLogic.delegatecall(msg.data);
        return abi.encode(success);
    }

    fallback() external payable {}

    receive() external payable {}
}

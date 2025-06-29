// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterClient} from "../../lib/chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "../../lib/chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "../../lib/chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "./utils/AccessControl.sol";
import {Call, IBaseAccount} from "../interface/IBaseAccount.sol";
import {CCIPConstants} from "./utils/Constants.sol";

struct Config {
    uint64 chain;
    address feeToken;
    Client.EVMTokenAmount[] transferTokens;
    Client.GenericExtraArgsV2 extraArgs;
}

contract CCIPMessenger is AccessControl, CCIPConstants {
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    event Message(bytes32 messageId);

    modifier onlyRouter() {
        require(msg.sender == address(s_router), "Router: only router");
        _;
    }

    function executeCCIP(
        Call[] memory calls,
        Config memory config
    ) public onlyOwner returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(calls),
            tokenAmounts: config.transferTokens,
            extraArgs: Client._argsToBytes(config.extraArgs),
            feeToken: config.feeToken
        });

        if (config.transferTokens.length > 0) {
            for (uint8 i = 0; i < config.transferTokens.length; i++) {
                IERC20(config.transferTokens[i].token).approve(
                    address(s_router),
                    config.transferTokens[i].amount
                );
            }
        }

        uint256 fees = s_router.getFee(config.chain, message);

        if (config.feeToken == address(0)) {
            if (fees > address(this).balance)
                revert NotEnoughBalance(address(this).balance, fees);

            messageId = s_router.ccipSend{value: fees}(config.chain, message);
        } else {
            if (fees > s_linkToken.balanceOf(address(this)))
                revert NotEnoughBalance(
                    s_linkToken.balanceOf(address(this)),
                    fees
                );

            s_linkToken.approve(address(s_router), fees);

            messageId = s_router.ccipSend(config.chain, message);
        }

        emit Message(messageId);
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external virtual onlyRouter {
        _ccipReceive(message);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal {
        require(
            abi.decode(message.sender, (address)) == address(this),
            "Sender: not allowed"
        );
        Call[] memory calls = abi.decode(message.data, (Call[]));
        if (calls.length > 0) {
            IBaseAccount(address(this)).executeBatch(calls);
        }
    }
}

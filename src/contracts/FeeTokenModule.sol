// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FeeTokenConstants} from "./utils/Constants.sol";
import {IPoolManager} from "../interface/IPoolManager.sol";
import {Currency} from "../types/Currency.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {IHooks} from "../interface/IHooks.sol";
import {IPoolManager} from "../interface/IPoolManager.sol";
import {TransientStateLibrary} from "../libraries/TransientStateLibrary.sol";
import {StateLibrary} from "../libraries/StateLibrary.sol";

contract FeeTokenModule is FeeTokenConstants {
    error NotPoolManager();

    using TransientStateLibrary for IPoolManager;
    using StateLibrary for IPoolManager;
    function feeTokenInfo() public view returns (uint96 maxFee, address token) {
        bytes32 slot = FEE_TOKEN_SLOT;
        assembly {
            let data := sload(slot)
            maxFee := shr(160, data)
            token := and(data, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }
    function _payWithFeeToken(
        bytes memory data
    ) internal returns (bytes memory) {
        (uint256 missingAccountFunds, address sender) = abi.decode(
            data,
            (uint256, address)
        );
        (uint96 maxFee, address feeToken) = feeTokenInfo();
        poolManager.take(
            Currency.wrap(address(0)),
            sender,
            missingAccountFunds
        );
        PoolKey memory poolKey = PoolKey(
            Currency.wrap(address(0)),
            Currency.wrap(feeToken),
            100,
            1,
            IHooks(address(0))
        );
        (, int24 currentTick, , ) = poolManager.getSlot0(poolKey.toId());
        poolManager.swap(
            poolKey,
            IPoolManager.SwapParams(
                false,
                -int256(missingAccountFunds),
                TickMath.getSqrtPriceAtTick(currentTick - 50)
            ),
            ""
        );

        int256 feeTokenDelta = poolManager.currencyDelta(
            address(this),
            Currency.wrap(feeToken)
        );
        require(-feeTokenDelta < int256(int96(maxFee)), "Expensive");

        _resolve(feeToken);

        return abi.encode(true);
    }

    function _resolve(address token) internal {
        Currency _t = Currency.wrap(token);
        int256 tokenDelta = poolManager.currencyDelta(address(this), _t);

        if (tokenDelta < 0) {
            poolManager.sync(_t);
            _t.transfer(address(poolManager), uint256(-tokenDelta));
            poolManager.settle();
        } else if (tokenDelta > 0) {
            poolManager.take(_t, address(this), uint256(tokenDelta));
        }
    }

    function unlockCallback(
        bytes calldata data
    ) external returns (bytes memory) {
        return _payWithFeeToken(data);
    }
}

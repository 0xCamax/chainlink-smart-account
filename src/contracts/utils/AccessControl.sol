// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AccessControl {

    function _requireForExecute() internal view {
        require(
            msg.sender == address(this) || msg.sender == address(0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108),
            "not from self or EntryPoint"
        );
    }

    modifier onlyOwner() {
        _requireForExecute();
        _;
    }
}
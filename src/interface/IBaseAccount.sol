// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Call {
    address target;
    uint256 value;
    bytes data;
}

interface IBaseAccount {
    function executeBatch(Call[] calldata calls) external;
}
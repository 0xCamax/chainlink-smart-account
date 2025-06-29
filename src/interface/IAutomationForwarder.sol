// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutomationForwarder {
    function getTarget() external view returns (address);
    function getRegistry() external view returns (address);
}

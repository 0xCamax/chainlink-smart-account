// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyAccount} from "../src/MyAccount.sol";

contract AccountScript is Script {
    MyAccount public account;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        account = new MyAccount();

        vm.stopBroadcast();
    }
}

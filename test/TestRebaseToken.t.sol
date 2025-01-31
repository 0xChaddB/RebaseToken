// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vault} from "../src/Vault.sol";
import {Test, console} from "forge-std/Test.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
import {RebaseToken} from "../src/RebaseToken.sol";

contract TestRebaseToken is Test {
    RebaseToken public rebaseToken;
    Vault public vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        (bool success, ) = payable (address(vault)).call{value: 1 ether}("");
        vm.stopPrank();
    }
}
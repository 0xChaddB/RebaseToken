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
        vm.stopPrank();
    }
    
    function testDepositLinear(uint256 amount) public {
        // vm.asume(amout > 1e4)
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. Deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();

        // 2. Check our rebase token balance
        uint256 startBalance = rebaseToken.balanceOf(user);
        console.log("block.timestamp", block.timestamp);
        console.log("start balance", startBalance);
        assertEq(startBalance, amount);

        // 3. Warp the time and check the balance again 
        vm.warp(block.timestamp + 1 hours);
        console.log("block.timestamp", block.timestamp);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        console.log("middleBalance", middleBalance);
        assertGt(middleBalance, startBalance);
        // 4. Warp the time again by the same amount and check the balance again
        vm.warp(block.timestamp + 1 hours);
        console.log("block.timestamp", block.timestamp);
        uint256 endBalance = rebaseToken.balanceOf(user);
        console.log("endBalance", endBalance);
        assertGt(endBalance, middleBalance);
        
        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);
        vm.stopPrank(); 
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        // Deposit funds
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();

        // Redeem funds
        vault.redeem(amount);

        uint256 balance = rebaseToken.balanceOf(user);
        console.log("User balance: %d", balance);
        assertEq(balance, 0);
        vm.stopPrank();
    }

}
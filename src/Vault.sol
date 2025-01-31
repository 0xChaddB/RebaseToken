// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRebaseToken} from "./Interfaces/IRebaseToken.sol";

contract Vault {
    // We need to pass the token address to the constructor.
    // Create a deposit function that mints tokens to the user equal to the user
    // Create a redeem function that bruns the tokens from the user and sends the user ETH.
    // create a way to add rewards to the vault
    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    error Vault__RedeemFailed();
    
    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }
    
    receive() external payable {}

    function deposit() external payable {
        // 1. We need to use the amount of ETH the user has sent to visit tokens to the user 
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function redeem(uint256 _amount) external {
        // 1. Burn the tokens from the user
        i_rebaseToken.burn(msg.sender, _amount);
        // 2. Send the user ETH back
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
    }

    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
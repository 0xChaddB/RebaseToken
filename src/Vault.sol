// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    // We need to pass the token address to the constructor.
    // Create a deposit function that mints tokens to the user equal to the user
    // Create a redeem function that bruns the tokens from the user and sends the user ETH.
    // create a way to add rewards to the vault
    address private immutable i_rebaseToken;

    constructor(address _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }
    
    receive() external payable ()
    
    function getRebaseTokenAddress() external view returns (address) {
        return i_rebaseToken;
    }
}
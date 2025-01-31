// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRebaseToken {  
    function mint(address _to, uint256 _value) external;    
    function burn(address _from, uint256 _value) external;  
}
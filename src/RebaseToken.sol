// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title RebaseToken
* @author Chaddb
* @notice This is a cross-chain rebase token that incentivises users to deposit into a vault
* @notice The interest rate in the smart contract can only decrease
* @notice Each user will have their own interest rate that is the global interest rate at the time of deposit
*/

contract RebaseToken is ERC20 {

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 public s_interestRate = 5e10;
    mapping(address => uint256) public s_userInterestRates;
    mapping(address => uint256) public s_userLastUpdatedTimestamp;

    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);
        
    event RebaseToken__InterestRateChanged( uint256 newInterestRate);


    constructor() ERC20("RebaseToken", "RBT") {}

    /* 
    * @notice Set the interest rate in the contract
    * @param _newinterestRate The new interest rate
    * @dev The interest rate can only decrease
    */
    function setInterestRate(uint256 _newinterestRate) external  {
        require (_newinterestRate < s_interestRate, RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newinterestRate));

        s_interestRate = _newinterestRate;

        emit RebaseToken__InterestRateChanged(_newinterestRate);
    }

    /*
    * @notice Mints tokens for a user
    * @param _to The user
    * @param _amount The amount of tokens to mint
    */
    function mint(address _to, uint256 _amount) public {
        _mintAccruedInterest(_to);
        s_userInterestRates[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /* */
    function _mintAccruedInterest(address _to) private {
        // find their current balance of rebase tokens that have been minted to the user 
        // calculate their current balance including any interest -> balanceOf
        // calculate the number of tokens that need to be minted to the user 
        // call mint to min the token to the user 
        // set the users last updated timestamp

        
    }
    
    /*
    *
    *
    *
    */

    function _calculateUserAccumulatedInterestdSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = (PRECISION_FACTOR +(s_userInterestRates[_user] * timeElapsed));

    }

    /*
    * @notice Get the interest rate for a user
    * @param _user The user
    * @return The interest rate for the user
    */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRates[_user];
    }


    /* */
    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principle balance of the user (the number of tokens that have actually been minted to the user )
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestdSinceLastUpdate(_user) / PRECISION_FACTOR;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
/** 
 * @title RebaseToken
 * @author Chaddb
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate that is the global interest rate at the time of deposit
*/

contract RebaseToken is ERC20, Ownable, AccessControl {

    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);
        
    event RebaseToken__InterestRateChanged( uint256 newInterestRate);


    constructor() ERC20("RebaseToken", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /** 
     * @notice Set the interest rate in the contract
     * @param _newinterestRate The new interest rate
     * @dev The interest rate can only decrease
    */
    function setInterestRate(uint256 _newinterestRate) external  {
        require (_newinterestRate < s_interestRate, RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newinterestRate));

        s_interestRate = _newinterestRate;

        emit RebaseToken__InterestRateChanged(_newinterestRate);
    }

    /**
     * @notice Get the principle balance of a user. This is the number of tokens that have currently been minted to the user
     * not including any interest that has accrued since the last tiem they interacted with the protocol
     * @param _user The user
     * @return The principle balance of the user
    */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Mints tokens for a user
     * @param _to The user
     * @param _amount The amount of tokens to mint
    */
    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens when they withdraw from the vault
     * @param _from The user to burn tokens from
     * @param _amount The amount of tokens to burn
    */
    function burn(address _from, uint256 _amount) public onlyRole(MINT_AND_BURN_ROLE) {
        // Mints any existing interest that has accrued since the last time the user's balance was updated.
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /** 
     * @notice Mints the accrued interest to the user since the last time they interacted with the protocol, (e.g, burn, mint, transfer...)
     * @param _user The user 
    */
    function _mintAccruedInterest(address _user) internal {
        // Get the user's previous principal balance. The amount of tokens they had last time their interest was minted to them.
        uint256 previousPrincipalBalance = super.balanceOf(_user);

        // Calculate the accrued interest since the last accumulation
        // `balanceOf` uses the user's interest rate and the time since their last update to get the updated balance
        uint256 currentBalance = balanceOf(_user);
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;

        // Mint an amount of tokens equivalent to the interest accrued
        _mint(_user, balanceIncrease);
        // Update the user's last updated timestamp to reflect this most recent time their interest was minted to them.
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }
    
    /** 
     * @notice Calculate the amount of interest that has accrued since the last time the user interacted with the protocol
     * @param _user The user we want to calculate the interest 
     * @return linearInterest amount of interest that has accrued
    */

    function _calculateUserAccumulatedInterestdSinceLastUpdate(address _user) internal view returns (uint256 linearInterest) {
        
        uint256 timeDifference = block.timestamp - s_userLastUpdatedTimestamp[_user];
        // represents the linear growth over time = 1 + (interest rate * time)
        linearInterest = (s_userInterestRate[_user] * timeDifference) + PRECISION_FACTOR;

    }

    /** 
     * @notice Get the interest rate for a user
     * @param _user The user
     * @return The interest rate for the user
    */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    function getUserInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /** 
     * @notice Get the balance of a user
     * @param _user The user to get the balance of
    */
    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principle balance of the user (the number of tokens that have actually been minted to the user )
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestdSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    /**
     * @notice Transfer tokens from one user to another
     * @param _recipient The recipient of the tokens
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was successful 
    */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);        
        }

        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfer tokens from one user to another
     * @param _sender The sender of the tokens
     * @param _recipient The recipient of the tokens
     * @param _amount The amount of tokens to transfer
     * @return True if the transfer was successful 
    */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);        
        }

        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

}
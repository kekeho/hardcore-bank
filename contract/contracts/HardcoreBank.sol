pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/utils/math/SafeMath.sol";


struct Config {
    address owner;  // creator of bank
    string subject;  // name of piggybank
    string description;  // memo

    address tokenContractAddress;  // token address
    uint256 targetAmount;
    uint256 monthlyRemittrance;
}

contract HardcoreBank {
    using SafeMath for uint256;

    uint256 constant decimal = 18;

    Config public config;

    constructor(string memory subject, string memory description, address token, uint256 targetAmount, uint256 monthlyRemittrance) {
        config = Config(msg.sender, subject, description, token, targetAmount, monthlyRemittrance);
    }
}


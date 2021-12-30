pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/utils/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/token/ERC777/ERC777.sol";


struct Config {
    address owner;  // creator of bank
    string subject;  // name of piggybank
    string description;  // memo

    address tokenContractAddress;  // token address
    uint256 targetAmount;
    uint256 monthlyRemittrance;
}

contract HardcoreBank is IERC777Recipient {
    using SafeMath for uint256;

    uint256 constant decimal = 18;

    Config public config;

    constructor(string memory subject, string memory description, address token, uint256 targetAmount, uint256 monthlyRemittrance) {
        config = Config(msg.sender, subject, description, token, targetAmount, monthlyRemittrance);
    }

    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external {
        // TODO: write receiver
    }
}


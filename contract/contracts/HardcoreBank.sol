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

    bool disabled;
}

contract HardcoreBank is IERC777Recipient {
    using SafeMath for uint256;

    address private _owner;

    uint256 constant private _decimal = 18;
    IERC1820Registry private _erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => Config[]) private accountList;
    mapping(address => uint256) public activeCount;

    constructor() {
        // set owner;
        _owner = msg.sender;
        
        // set interface to registory
        _erc1820Registry.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    function createAccount(string calldata subject, string calldata description, address token, uint256 targetAmount, uint256 monthlyRemittrance) public {
        accountList[msg.sender].push(
            Config(msg.sender, subject, description, token, targetAmount, monthlyRemittrance, false)
        );
        activeCount[msg.sender] = activeCount[msg.sender].add(1);
    }

    function getAccounts() public view returns (Config[] memory) {
        Config[] memory result = new Config[](activeCount[msg.sender]);

        uint256 result_i = 0;
        for (uint256 i = 0; i < accountList[msg.sender].length; i=i.add(1)) {
            // pass disabled
            if (accountList[msg.sender][i].disabled == false) {
                result[result_i] = accountList[msg.sender][i];
                result_i = result_i.add(1);
            }
        }

        return result;
    }

    function disable(uint256 id) public {
        require(id < accountList[msg.sender].length);
        require(accountList[msg.sender][id].disabled == false);

        accountList[msg.sender][id].disabled = true;
        activeCount[msg.sender] = activeCount[msg.sender].sub(1);
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external {
        // TODO: write receiver
    }
}


pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/utils/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/token/ERC777/ERC777.sol";
import "kekeho/BokkyPooBahsDateTimeLibrary@1.02/contracts/BokkyPooBahsDateTimeLibrary.sol";

import "contracts/Utils.sol";


struct Config {
    address owner;  // creator of account
    string subject;  // name of account
    string description;  // memo

    address tokenContractAddress;  // token address
    uint256 targetAmount;
    uint256 monthlyRemittrance;

    uint256 created;

    bool disabled;
}


struct RecvTransaction {
    address from;
    uint256 amount;
    uint256 timestamp;
}


contract HardcoreBank is IERC777Recipient {
    using SafeMath for uint256;
    using BokkyPooBahsDateTimeLibrary for uint256;

    address private _owner;

    uint256 constant private _decimal = 18;
    IERC1820Registry private _erc1820Registry = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(uint256 => Config) private accountList;  // ID => account
    mapping(address => uint256[]) private userAccountList;  // user adderss => ID list
    uint256 private nextID = 0;

    mapping(uint256 => RecvTransaction[]) private recvList;  // ID => RecvTransaction


    constructor() {
        // set owner;
        _owner = msg.sender;
        
        // set interface to registory
        _erc1820Registry.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }


    function createAccount(string calldata subject, string calldata description, address token, uint256 targetAmount, uint256 monthlyRemittrance) public {
        accountList[nextID] = Config(msg.sender, subject, description,
                                     token, targetAmount, monthlyRemittrance, block.timestamp, false);
        userAccountList[msg.sender].push(nextID);
        nextID = nextID.add(1);
    }


    function getAccounts() public view returns (Config[] memory) {
        // count length
        uint256 active_length = 0;
        for (uint256 i = 0; i < userAccountList[msg.sender].length; i=i.add(1)) {
            uint256 id = userAccountList[msg.sender][i];
            if (accountList[id].disabled == false) {
                active_length = active_length.add(1);
            }
        }

        Config[] memory result = new Config[](active_length);
        uint256 result_id = 0;
        for (uint256 i = 0; i < userAccountList[msg.sender].length; i=i.add(1)) {
            uint256 id = userAccountList[msg.sender][i];
            // pass disabled
            if (accountList[id].disabled == false) {
                result[result_id] = accountList[id];
                result_id = result_id.add(1);
            }
        }

        return result;
    }


    // Logical Delete
    function disable(uint256 id) public {
        require(id < nextID);
        require(accountList[id].disabled == false);
        require(accountList[id].owner == msg.sender);

        accountList[id].disabled = true;

        // TODO: 残高があれば回収
    }


    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
        uint256 id = toUint256(data);
        require(id < nextID);
        require(accountList[id].disabled == false);
        require(to == address(this));
        require(msg.sender == accountList[id].tokenContractAddress);

        recvList[id].push(
            RecvTransaction(from, amount, block.timestamp)
        );
    }


    function tokensRecvList(uint256 id) public view returns (RecvTransaction[] memory) {
        require(isOwner(id));
        return recvList[id];
    }


    function balanceOf(uint256 id) public view returns (uint256) {
        require(isOwner(id));
        return _balanceOf(id);
    }


    function _balanceOf(uint256 id) private view returns (uint256) {
        require(id < nextID);
        Config memory accountConfig = accountList[id];
        require(accountConfig.disabled == false);

        // calc total amount
        uint256 start = accountConfig.created;
        uint256 totalAmount = 0;  // result
        uint256 ri = 0;  // recvList index
        uint256 addMonth = 1;
        // calc par month
        while (true) {
            // next year/month
            uint256 nextMonth = BokkyPooBahsDateTimeLibrary.addMonths(start, addMonth);
            uint256 currentMonth = BokkyPooBahsDateTimeLibrary.addMonths(start, addMonth.sub(1));

            uint256 monthTotal = 0;
            // look each recv-transaction
            while (ri < recvList[id].length) {
                RecvTransaction memory recv = recvList[id][ri];
                if (recv.timestamp >= nextMonth) {
                    break;
                }
                monthTotal = monthTotal.add(recv.amount);
                ri = ri.add(1);
            }


            if (currentMonth < block.timestamp && block.timestamp < nextMonth) {
                // current month
                totalAmount = totalAmount.add(monthTotal);
            } else if (monthTotal >= accountConfig.monthlyRemittrance) {
                // old great month
                totalAmount = totalAmount.add(monthTotal);
            } else {
                // old failed month
                if ( totalAmount >= accountConfig.targetAmount ) {
                    totalAmount = totalAmount.add(monthTotal);
                } else {
                    totalAmount = totalAmount.add(monthTotal);  // totalAmount += monthTotal
                    totalAmount = totalAmount.sub(totalAmount.div(5));  // totalAmount -= totalAmount/5
                }
            }

            addMonth = addMonth.add(1);
            if (nextMonth > block.timestamp) { break; }
        }

        return totalAmount;
    }

    function collectedAmount(address tokenContractAddress) public view returns (uint256) {
        require(isGrandOwner());

        uint256 result = 0;

        for (uint256 id = 0; id < nextID; id=id.add(1)) {
            Config memory account = accountList[id];
            if (account.tokenContractAddress != tokenContractAddress) { continue; }

            uint256 sum = 0;
            for (uint256 j = 0; j < recvList[id].length; j=j.add(1)) {
                sum = sum.add(recvList[id][j].amount);
            }

            if (account.disabled) {
                result = result.add(sum);
            } else {
                result = result.add(sum.sub(_balanceOf(id)));
            }
        }

        return result;
    }


    function withdraw(uint256 id) public {
        require(isOwner(id));
        Config memory account = accountList[id];
        uint256 balance = balanceOf(id);
        require(balance >= account.targetAmount);

        // send
        IERC777 tokenContract = IERC777(account.tokenContractAddress);
        tokenContract.send(account.owner, balance, bytes(""));
    }


    function isOwner(uint256 id) public view returns (bool) {
        require(id < nextID);
        return accountList[id].owner == msg.sender;
    }


    function isGrandOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

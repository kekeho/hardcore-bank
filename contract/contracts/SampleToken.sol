pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.4.1/contracts/token/ERC777/ERC777.sol";


contract SampleToken is ERC777 {
    constructor () public ERC777("SampleToken", "ST", new address[](0)) {
        _mint(msg.sender, 100 * 10**18, "", "");
    }
}

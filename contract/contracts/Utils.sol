pragma solidity ^0.8.0;


function toUint256(bytes memory _bytes) pure returns (uint256) {
    require(_bytes.length >= 32, "toUint256_outOfBounds");
    uint256 tempUint;

    assembly {
        tempUint := mload(add(_bytes, 0x20))
    }

    return tempUint;
}

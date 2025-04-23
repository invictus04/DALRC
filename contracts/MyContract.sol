// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract MyContract {
    uint public value;

    function setValue(uint _value) public {
        value = _value;
    }

    function getValue() public view returns(uint) {
        return value;
    }
}

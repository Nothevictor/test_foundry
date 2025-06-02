// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function decrement() public {
        require(number > 0, "Counter: cannot decrement below zero");
        number--;
    }
}
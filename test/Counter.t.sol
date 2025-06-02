// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {

    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function test_InitialNumber() public {
        assertEq(counter.number(), 0);

        console.log(address(this));
        console.log(address(counter));
    }

    function test_SetNumber(uint256 anyNumber) public {
        vm.assume(anyNumber <= 1000);

        counter.setNumber(anyNumber);
        assertEq(counter.number(), anyNumber);

        console.log("anyNumber:", anyNumber);
    }

    function test_IncrementFromZero() public {
        counter.increment();

        assertEq(counter.number(), 1);
    }

    function test_Increment(uint256 anyNumber) public {
        vm.assume(anyNumber <= 1000);

        counter.setNumber(anyNumber);
        counter.increment();

        assertEq(counter.number(), anyNumber+1);
    }

    function test_Decerement(uint256 startValue) public {
        vm.assume(startValue > 0 && startValue <=1000000);

        counter.setNumber(startValue);
        console.log("Before decrement:", counter.number());

        counter.decrement();
        console.log("After decrement:", counter.number());

        assertEq(counter.number(), startValue - 1);
    }

    function test_DecrementShouldUnderflow() public {
        vm.expectRevert();
        counter.decrement();
    }
}
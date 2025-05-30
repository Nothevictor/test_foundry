// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {LikeButton} from "../src/LikeButton.sol";

contract LikeButtonTest is Test {

    LikeButton likeContract;

    address userVolodya = address(1);
    address userOlya = address(2);

    function setUp() public {
        likeContract = new LikeButton();
    }

    function test_InitState() public {
        assertEq(likeContract.totalLikes(), 0);
        assertFalse(likeContract.liked(userVolodya));
        assertFalse(likeContract.liked(userOlya));
    }

    function test_PressLikeButton() public {
        vm.prank(userOlya);
        likeContract.like();

        assertEq(likeContract.totalLikes(), 1);
        assertTrue(likeContract.liked(userOlya));
    }

    function test_Dislike() public {
        //like
        vm.prank(userOlya);
        likeContract.like();
        //dislike
        vm.prank(userOlya);
        likeContract.like();

        assertEq(likeContract.totalLikes(), 0);
        assertFalse(likeContract.liked(userOlya));
    }

    function test_MultipleLikes() public {
        vm.prank(userOlya);
        likeContract.like();

        vm.prank(userVolodya);
        likeContract.like();

        assertEq(likeContract.totalLikes(), 2);
        assertTrue(likeContract.liked(userVolodya));
        assertTrue(likeContract.liked(userOlya));
    }

    function test_FuzzLikeCheck(address randomUser) public {
        vm.prank(randomUser);
        likeContract.like();
        assertTrue(likeContract.liked(randomUser));
        assertEq(likeContract.liked(randomUser), true);
    }
}
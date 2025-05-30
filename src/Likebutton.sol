// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

contract LikeButton {
    mapping (address => bool) public liked;

    uint256 public totalLikes;

    function like() external {
        if (liked[msg.sender]) {
            liked[msg.sender] = false;
            totalLikes -= 1;
        } else {
            liked[msg.sender] = true;
            totalLikes += 1;
        }
    }
}
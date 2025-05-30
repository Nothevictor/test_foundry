// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title SimpleTodoList - Basic task manager
/// @notice Users can add, update, complete, and delete their own tasks
contract SimpleTodoList {
    struct Task {
        string text;
        bool isDone;
    }

    mapping(address => Task[]) private userTasks;

    event TaskAdded(address indexed user, uint256 taskId, string text);
    event TaskUpdated(address indexed user, uint256 taskId, string newText);
    event TaskCompleted(address indexed user, uint256 taskId);
    event TaskDeleted(address indexed user, uint256 taskId);

    /// @notice Adds a new task to caller's list
    function addTask(string calldata _text) external {
        userTasks[msg.sender].push(Task(_text, false));
        emit TaskAdded(msg.sender, userTasks[msg.sender].length - 1, _text);
    }

    /// @notice Returns all tasks of the caller
    function getMyTasks() external view returns (Task[] memory) {
        return userTasks[msg.sender];
    }

    /// @notice Edits task text by index
    function updateTask(uint256 _index, string calldata _newText) external {
        require(_index < userTasks[msg.sender].length, "Invalid task index");
        userTasks[msg.sender][_index].text = _newText;
        emit TaskUpdated(msg.sender, _index, _newText);
    }

    /// @notice Marks task as completed
    function completeTask(uint256 _index) external {
        require(_index < userTasks[msg.sender].length, "Invalid task index");
        userTasks[msg.sender][_index].isDone = true;
        emit TaskCompleted(msg.sender, _index);
    }

    /// @notice Deletes task by index (by replacing it with the last one)
    function deleteTask(uint256 _index) external {
        require(_index < userTasks[msg.sender].length, "Invalid task index");

        uint256 last = userTasks[msg.sender].length - 1;
        if (_index != last) {
            userTasks[msg.sender][_index] = userTasks[msg.sender][last];
        }

        userTasks[msg.sender].pop();
        emit TaskDeleted(msg.sender, _index);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/ToDolist.sol";

contract SimpleTodoListTest is Test {
    SimpleTodoList public todoList;
    address public user1 = address(0x1); // Пример пользователя 1
    address public user2 = address(0x2); // Пример пользователя 2

    // События для проверки
    event TaskAdded(address indexed user, uint256 taskId, string text);
    event TaskUpdated(address indexed user, uint256 taskId, string newText);
    event TaskCompleted(address indexed user, uint256 taskId);
    event TaskDeleted(address indexed user, uint256 taskId);

    /// @notice Настройка, выполняемая перед каждым тестом
    function setUp() public {
        todoList = new SimpleTodoList();
    }

    // --- Тесты для addTask ---

    function test_addTask_succeedsAndEmitsEvent() public {
        string memory taskText = unicode"Купить продукты";

        // Ожидаем событие TaskAdded
        vm.expectEmit(true, true, true, true, address(todoList));
        emit TaskAdded(address(this), 0, taskText);

        // Выполняем действие
        todoList.addTask(taskText);

        // Проверяем состояние
        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertEq(tasks.length, 1, "Task count should be 1");
        assertEq(tasks[0].text, taskText, "Task text mismatch");
        assertFalse(tasks[0].isDone, "Task should not be done initially");
    }

    function test_addTask_multipleTasksForSameUser() public {
        todoList.addTask(unicode"Задача 1");
        todoList.addTask(unicode"Задача 2");

        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertEq(tasks.length, 2, "Task count should be 2");
        assertEq(tasks[0].text, unicode"Задача 1");
        assertEq(tasks[1].text, unicode"Задача 2");
    }

    function test_addTask_differentUsers() public {
        string memory taskUser1 = unicode"Задача для user1";
        string memory taskUserThis = unicode"Задача для this";

        // User1 добавляет задачу
        vm.prank(user1);
        todoList.addTask(taskUser1);

        // address(this) добавляет задачу
        // vm.prank(address(this)); // Не обязательно, так как это вызывающий по умолчанию
        todoList.addTask(taskUserThis);

        // Проверяем задачи user1
        vm.prank(user1);
        SimpleTodoList.Task[] memory tasksUser1 = todoList.getMyTasks();
        assertEq(tasksUser1.length, 1, "User1 task count should be 1");
        assertEq(tasksUser1[0].text, taskUser1, "User1 task text mismatch");

        // Проверяем задачи address(this)
        // vm.prank(address(this));
        SimpleTodoList.Task[] memory tasksThis = todoList.getMyTasks();
        assertEq(tasksThis.length, 1, "address(this) task count should be 1");
        assertEq(tasksThis[0].text, taskUserThis, "address(this) task text mismatch");
    }

    // --- Тесты для getMyTasks ---

    function test_getMyTasks_returnsEmptyForNewUser() public {
        vm.prank(user2); // Используем нового пользователя, который еще не добавлял задач
        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertEq(tasks.length, 0, "Task list should be empty for a new user");
    }

    // --- Тесты для updateTask ---

    function test_updateTask_succeedsAndEmitsEvent() public {
        todoList.addTask(unicode"Старая задача");
        string memory newTaskText = unicode"Новая задача";

        // Ожидаем событие TaskUpdated
        vm.expectEmit(true, true, true, true, address(todoList));
        emit TaskUpdated(address(this), 0, newTaskText);

        todoList.updateTask(0, newTaskText);

        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertEq(tasks[0].text, newTaskText, "Task text should be updated");
    }

    function test_updateTask_fails_invalidIndex() public {
        todoList.addTask(unicode"Задача есть");

        // Ожидаем revert с сообщением "Invalid task index"
        vm.expectRevert(bytes("Invalid task index"));
        todoList.updateTask(1, unicode"Попытка обновить несуществующую задачу");
    }

    function test_updateTask_fails_noTasks() public {
        // Ожидаем revert, так как список задач пуст
        vm.expectRevert(bytes("Invalid task index"));
        todoList.updateTask(0, unicode"Попытка обновить в пустом списке");
    }

    // --- Тесты для completeTask ---

    function test_completeTask_succeedsAndEmitsEvent() public {
        todoList.addTask(unicode"Выполнить это");

        // Ожидаем событие TaskCompleted
        vm.expectEmit(true, true, false, true, address(todoList)); // text не индексируется и не передается
        emit TaskCompleted(address(this), 0);

        todoList.completeTask(0);

        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertTrue(tasks[0].isDone, "Task should be marked as done");
    }

    function test_completeTask_fails_invalidIndex() public {
        todoList.addTask(unicode"Задача для проверки индекса");

        vm.expectRevert(bytes("Invalid task index"));
        todoList.completeTask(1);
    }

    function test_completeTask_idempotent() public {
        todoList.addTask(unicode"Задача для двойного выполнения");
        todoList.completeTask(0); // Первое выполнение

        // Ожидаем событие TaskCompleted снова
        vm.expectEmit(true, true, false, true, address(todoList));
        emit TaskCompleted(address(this), 0);

        todoList.completeTask(0); // Повторное выполнение

        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertTrue(tasks[0].isDone, "Task should still be marked as done");
    }

    // --- Тесты для deleteTask ---

    function test_deleteTask_succeeds_middleAndEmitsEvent() public {
        todoList.addTask(unicode"Задача 1"); // index 0
        todoList.addTask(unicode"Задача 2"); // index 1 (будет удалена)
        todoList.addTask(unicode"Задача 3"); // index 2

        // Ожидаем событие TaskDeleted
        // При удалении элемента не из конца, taskId в событии остается _index удаляемого,
        // но фактически на этом месте теперь другой элемент или список короче.
        vm.expectEmit(true, true, false, true, address(todoList));
        emit TaskDeleted(address(this), 1);

        todoList.deleteTask(1); // Удаляем "Задача 2"

        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertEq(tasks.length, 2, "Task count should be 2 after deletion");
        assertEq(tasks[0].text, unicode"Задача 1", "First task should remain");
        assertEq(tasks[1].text, unicode"Задача 3", "Last task should now be at index 1");
    }

    function test_deleteTask_succeeds_last() public {
        todoList.addTask(unicode"Задача A");
        todoList.addTask(unicode"Задача B"); // index 1 (будет удалена)

        vm.expectEmit(true, true, false, true, address(todoList));
        emit TaskDeleted(address(this), 1);

        todoList.deleteTask(1);

        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertEq(tasks.length, 1, "Task count should be 1 after deleting last");
        assertEq(tasks[0].text, unicode"Задача A", "First task should remain");
    }

    function test_deleteTask_succeeds_onlyTask() public {
        todoList.addTask(unicode"Единственная задача");

        vm.expectEmit(true, true, false, true, address(todoList));
        emit TaskDeleted(address(this), 0);

        todoList.deleteTask(0);

        SimpleTodoList.Task[] memory tasks = todoList.getMyTasks();
        assertEq(tasks.length, 0, "Task count should be 0 after deleting the only task");
    }

    function test_deleteTask_fails_invalidIndex() public {
        todoList.addTask(unicode"Задача для проверки индекса при удалении");

        vm.expectRevert(bytes("Invalid task index"));
        todoList.deleteTask(1);
    }

    function test_deleteTask_fails_emptyList() public {
        vm.expectRevert(bytes("Invalid task index"));
        todoList.deleteTask(0);
    }

    // --- Тесты на безопасность/ограничения доступа (неявные) ---
    // В этом контракте нет явных модификаторов типа onlyOwner,
    // но каждая функция работает с задачами `msg.sender`.
    // Попытка одного пользователя изменить задачи другого невозможна напрямую,
    // так как он будет изменять свой собственный список задач.

    function test_access_userCannotUpdateAnotherUsersTaskDirectly() public {
        // User1 добавляет задачу
        vm.startPrank(user1);
        todoList.addTask(unicode"Задача User1");
        vm.stopPrank();

        // User2 (address(this)) пытается обновить задачу с индексом 0.
        // Это будет относиться к списку задач User2, а не User1.
        // Если у User2 нет задач, это вызовет revert "Invalid task index".
        vm.expectRevert(bytes("Invalid task index"));
        todoList.updateTask(0, unicode"Попытка User2 обновить задачу User1");

        // Проверяем, что задача User1 не изменилась
        vm.startPrank(user1);
        SimpleTodoList.Task[] memory tasksUser1 = todoList.getMyTasks();
        assertEq(tasksUser1[0].text, unicode"Задача User1", unicode"Задача User1 не должна была измениться");
        vm.stopPrank();
    }
}
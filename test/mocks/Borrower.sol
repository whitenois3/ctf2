// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "src/IERC20.sol";
import { ITransientLoan } from "src/ITransientLoan.sol";
import { IFlashLoanReceiver } from "src/IFlashLoanReceiver.sol";

contract Borrower is IFlashLoanReceiver {

    ITransientLoan immutable flashLoaner;

    address immutable target;

    bool fail = false;

    constructor(ITransientLoan loaner, address _target) {
        flashLoaner = loaner;
        target = _target;
    }

    /// @notice Call the flashloan function on the flashLoaner
    function startLoan() public {
        flashLoaner.startLoan();
    }

    /// @notice Mock the borrower doesn't repay the flashloan
    function failStartLoan() public {
        fail = true;
        flashLoaner.startLoan();
    }

    /// @notice This function is executed by the [TransientLoan] contract after the transient borrower
    /// is set. During its execution and its sub callframes, this contract can call [TransientLoan]'s `borrow`
    /// function to borrow tokens. All borrowed tokens must be returned by the end of this function's execution,
    /// or the call will revert.
    function bankroll() external {
        // Get the balance of the target and hoist it
        uint256 amount = IERC20(address(flashLoaner)).balanceOf(target);

        // Borrow some of the mock token
        flashLoaner.borrow(target, amount, address(this));

        // Transfer back to the flashLoaner
        if (!fail) {
            IERC20(address(flashLoaner)).transfer(address(flashLoaner), amount);
        }
        fail = false;
    }
}
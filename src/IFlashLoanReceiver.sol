// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title IFlashLoanReceiver
/// @notice Interface for contracts that wish to receive flashloans from a [TransientLoan] contract.
interface IFlashLoanReceiver {
    /// @notice This function is executed by the [TransientLoan] contract after the transient borrower
    /// is set. During its execution and its sub callframes, this contract can call [TransientLoan]'s `borrow`
    /// function to borrow tokens. All borrowed tokens must be returned by the end of this function's execution,
    /// or the call will revert.
    function bankroll() external;
}

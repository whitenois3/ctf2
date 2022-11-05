pragma solidity ^0.8.17;

import {ITransientLoan} from "../../src/interfaces/ITransientLoan.sol";
import {IFlashLoanReceiver} from "../../src/interfaces/IFlashLoanReceiver.sol";
import {MockToken} from "./MockERC20.sol";

/// @notice A borrower that reenters the `startLoan` function
contract MockReentrantBorrower is IFlashLoanReceiver {
    /// @notice The transient loan contract
    ITransientLoan flashLoaner;
    /// @notice The mock erc20 that will be borrowed
    MockToken mockToken;

    constructor(ITransientLoan _flashLoaner, MockToken _mockToken) {
        flashLoaner = _flashLoaner;
        mockToken = _mockToken;
    }

    /// @notice Perform a no-frills flash loan. If `doRepay` is set to false,
    /// the borrow will not be repaid.
    function performReentrantLoan() external {
        flashLoaner.startLoan();
    }

    ////////////////////////////////////////////////////////////////
    //                  IFlashLoanReceiver impl                   //
    ////////////////////////////////////////////////////////////////

    /// @notice `IFlashLoanReceiver` implementation
    function bankroll() external {
        flashLoaner.startLoan();
    }
}

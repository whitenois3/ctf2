pragma solidity ^0.8.17;

import { ITransientLoan } from "../../src/interfaces/ITransientLoan.sol";
import { IFlashLoanReceiver } from "../../src/interfaces/IFlashLoanReceiver.sol";
import { Token } from "../../src/Token.sol";

/// @notice A borrower that reenters the `startLoan` function
contract MockReentrantBorrower is IFlashLoanReceiver {
    /// @notice The transient loan contract
    ITransientLoan flashLoaner;
    /// @notice The mock erc20 that will be borrowed
    Token mockToken;

    constructor(ITransientLoan _flashLoaner, Token _mockToken) {
        flashLoaner = _flashLoaner;
        mockToken = _mockToken;
    }

    /// @notice Perform a reentrant flashloan
    function performReentrantLoan() external {
        flashLoaner.startLoan();
    }

    ////////////////////////////////////////////////////////////////
    //                  IFlashLoanReceiver impl                   //
    ////////////////////////////////////////////////////////////////

    /// @notice `IFlashLoanReceiver` implementation
    function bankroll() external {
        // Reenter `startLoan`
        flashLoaner.startLoan();
    }
}

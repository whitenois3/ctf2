// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";
import {MockToken} from "./mocks/MockERC20.sol";
import {IFlashLoanReceiver} from "../src/IFlashLoanReceiver.sol";

/// @notice TransientLoan contract interface
interface ITransientLoan {
    /// @notice Initiate a flash loan. Enables calls to `borrow` within the same execution.
    function startLoan() external virtual;

    /// @notice Borrow a token from the [TransientLoan] contract.
    function borrow(address token, uint256 amount, address to) external virtual;
}

contract TransientLoanTest is Test, IFlashLoanReceiver {

    ////////////////////////////////////////////////////////////////
    //                           STATE                            //
    ////////////////////////////////////////////////////////////////

    ITransientLoan public flashLoaner;
    MockToken public mockToken;
    bool public repayLoans;

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    error RejectBorrower(string);
    error OutstandingDebt(string);

    ////////////////////////////////////////////////////////////////
    //                           TESTS                            //
    ////////////////////////////////////////////////////////////////

    function setUp() public {
        // Deploy [TransientLoan] contract.
        flashLoaner = ITransientLoan(HuffDeployer.config().deploy("TransientLoan"));
        // Label [TransientLoan] contract in traces.
        vm.label(address(flashLoaner), "TransientLoan");
        
        // Deploy mock token
        mockToken = new MockToken("MOCK", "MCK", 18);
        mockToken.mint(address(flashLoaner), type(uint256).max);
    }

    function testLoan() public {
        // We want to repay our loans
        repayLoans = true;

        // Initialize a flash loan call frame
        // This contract's `bankroll` function will be called, and
        // loans can be taken out within that callframe by this contract.
        flashLoaner.startLoan();
    }

    function testLoanNoRepay() public {
        // Initialize a flash loan call frame
        // This contract's `bankroll` function will be called, and
        // loans can be taken out within that callframe by this contract.

        // This call will fail because we do not repay our loans.
        vm.expectRevert(abi.encodeWithSelector(OutstandingDebt.selector, "Repay your debt!"));
        flashLoaner.startLoan();
    }

    function testFailBorrowNoLoan(uint256 amount) public {
        // Attempt to borrow from outside of an approved callframe
        // Should revert every time.
        vm.expectRevert(abi.encodeWithSelector(RejectBorrower.selector, "Not the borrower!"));
        borrow(address(mockToken), amount, address(this), false);
    }

    ////////////////////////////////////////////////////////////////
    //                          HELPERS                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Call the `borrow` function on the [TransientLoan] contract with
    /// packed calldata.
    function borrow(address token, uint256 amount, address to, bool payBack) internal {
        (bool success,) = address(flashLoaner).call(abi.encodePacked(
            bytes4(flashLoaner.borrow.selector),
            token,
            amount,
            to
        ));
        assert(success);

        // Optionally pay back our debt after borrowing.
        if (payBack) {
            mockToken.transfer(address(flashLoaner), amount);
        }
    }

    ////////////////////////////////////////////////////////////////
    //                  IFlashLoanReceiver impl                   //
    ////////////////////////////////////////////////////////////////

    /// @notice `IFlashLoanReceiver` implementation
    function bankroll() external {
        // Borrow some of the mock token
        borrow(address(mockToken), 1 ether, address(this), repayLoans);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";
import {MockToken} from "./mocks/MockERC20.sol";
import {MockBaseBorrower} from "./mocks/MockBaseBorrower.sol";
import {MockAdversaryBorrower} from "./mocks/MockAdversaryBorrower.sol";
import {IFlashLoanReceiver} from "../src/interfaces/IFlashLoanReceiver.sol";
import {ITransientLoan} from "../src/interfaces/ITransientLoan.sol";

contract TransientLoanTest is Test {
    ////////////////////////////////////////////////////////////////
    //                           STATE                            //
    ////////////////////////////////////////////////////////////////

    ITransientLoan flashLoaner;
    MockToken mockToken;
    MockBaseBorrower mockBaseBorrower;
    MockAdversaryBorrower mockAdversaryBorrower;
    bool repayLoans;

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    error RejectBorrower(string);
    error OutstandingDebt(string);

    ////////////////////////////////////////////////////////////////
    //                           SETUP                            //
    ////////////////////////////////////////////////////////////////

    function setUp() public {
        // Deploy [TransientLoan] contract.
        flashLoaner = ITransientLoan(HuffDeployer.config().deploy("TransientLoan"));
        // Label [TransientLoan] contract in traces.
        vm.label(address(flashLoaner), "TransientLoan");

        // Deploy mock token
        mockToken = new MockToken("MOCK", "MCK", 18);
        mockToken.mint(address(flashLoaner), type(uint256).max);

        // Deploy mock borrowers
        mockBaseBorrower = new MockBaseBorrower(flashLoaner, mockToken);
        mockAdversaryBorrower = new MockAdversaryBorrower(
            flashLoaner,
            mockToken
        );
    }

    ////////////////////////////////////////////////////////////////
    //                    BASE BORROWER TESTS                     //
    ////////////////////////////////////////////////////////////////

    /// @notice Tests whether or not a loan will succeed if we repay our
    /// outstanding debt.
    function test_startLoan_repayDebt_success() public {
        // We want to repay our loans
        mockBaseBorrower.setRepay(true);

        // Initialize a flash loan call frame
        // The `MockBaseBorrower` contract's `bankroll` function will be called, and
        // loans can be taken out within that callframe by that contract.
        mockBaseBorrower.performHonestLoan();
    }

    /// @notice Tests whether or not a loan will revert if we do not repay
    /// our outstanding debt.
    function test_startLoan_noRepay_reverts() public {
        // Initialize a flash loan call frame
        // The `MockBaseBorrower` contract's `bankroll` function will be called, and
        // loans can be taken out within that callframe by that contract.

        // This call will fail because we do not repay our loans.
        vm.expectRevert(abi.encodeWithSelector(OutstandingDebt.selector, "Repay your debt!"));
        mockBaseBorrower.performHonestLoan();
    }

    /// @notice Tests whether or not a call to `borrow` will revert if we
    /// have not initiated a transient loan callframe.
    function test_borrow_noLoan_reverts(uint256 amount) public {
        vm.assume(amount != 0);

        // Attempt to borrow from outside of an approved callframe
        // Should revert every time.
        //
        // Note: We're sending incorrectly formatted data here, but the goal
        // is to hit the `ASSERT_BORROWER` check and have it fail.
        vm.expectRevert(abi.encodeWithSelector(RejectBorrower.selector, "Not the borrower!"));
        flashLoaner.borrow(address(mockToken), amount, address(this));
    }

    ////////////////////////////////////////////////////////////////
    //                  ADVERSARY BORROWER TESTS                  //
    ////////////////////////////////////////////////////////////////

    // TODO...
}

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

    uint256 constant MAX_BORROW = 1000;

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
        vm.assume(amount <= MAX_BORROW);

        // Attempt to borrow from outside of an approved callframe
        // Should revert every time.
        (bool success, bytes memory returndata) = address(flashLoaner).call(
            abi.encodePacked(bytes4(ITransientLoan.borrow.selector), mockToken, amount, address(this))
        );
        assert(!success);
        assertEq(returndata, abi.encodeWithSelector(RejectBorrower.selector, "Not the borrower!"));
    }

    ////////////////////////////////////////////////////////////////
    //                  ADVERSARY BORROWER TESTS                  //
    ////////////////////////////////////////////////////////////////

    /// @notice Tests the adversarial borrower's exploit.
    function test_startLoan_exploit_success() public {
        // Initiate the flash loan exploit
        //
        // Inside of the loan callframe, the adversarial contract deploys a new contract
        // that will be delegatecalled by the flashloaner
        mockAdversaryBorrower.exploit();

        // Ensure that the adversarial borrower kept the tokens
        assertEq(mockToken.balanceOf(address(mockAdversaryBorrower)), MAX_BORROW);
    }
}

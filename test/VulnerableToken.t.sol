// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import { IERC20 } from "src/IERC20.sol";
import { Borrower } from "./mocks/Borrower.sol";
import { ITransientLoan } from "src/ITransientLoan.sol";
import { IFlashLoanReceiver } from "src/IFlashLoanReceiver.sol";

/// @notice VulnerableToken contract interface
interface IVulnerableToken is IERC20, ITransientLoan {
    /// @notice Allows the warden to freeze the token
    function toggle() external;

    /// @notice Returns the given warden
    function warden() external returns (address);
}

contract VulnerableTokenTest is Test {
    IVulnerableToken public flashLoaner;
    bool public repayLoans;
    Borrower public borrower;

    error RejectBorrower(string);
    error OutstandingDebt(string);

    address constant target = address(0xdead);

    /// @notice Set up the test suite
    function setUp() public {
        // Deploy [TransientLoan] contract.
        vm.startPrank(target);
        flashLoaner = IVulnerableToken(
            HuffDeployer
            .config()
            .with_args(bytes.concat(abi.encode(18), abi.encode(target)))
            .deploy("VulnerableToken")
        );
        vm.stopPrank();

        // Label [VulnerableToken] contract in traces.
        vm.label(address(flashLoaner), "VulnerableToken");

        // Deploy the borrower with the configured target
        borrower = new Borrower(flashLoaner, target);
    }

    /// @notice Test the contract metdata
    function testMetadata() public {
        // Check the ERC20 metadata
        assertEq(keccak256(abi.encode(flashLoaner.name())), keccak256(abi.encode("Whitenois3")));
        assertEq(keccak256(abi.encode(flashLoaner.symbol())), keccak256(abi.encode("WHTN")));
        assertEq(flashLoaner.decimals(), 18);

        // Check the warden
        assertEq(flashLoaner.warden(), target);
        assertEq(flashLoaner.balanceOf(target), 0x100000);
    }

    /// @notice test warden can freeze transfers
    function testFreezeContract() public {

    }

    function testLoan() public {
        // We want to repay our loans
        repayLoans = true;

        // Initialize a flash loan call frame
        // This contract's `bankroll` function will be called, and
        // loans can be taken out within that callframe by this contract.
        borrower.startLoan();
    }

    function testLoanNoRepay() public {
        // Initialize a flash loan call frame
        // This contract's `bankroll` function will be called, and
        // loans can be taken out within that callframe by this contract.

        // This call will fail because we do not repay our loans.
        vm.expectRevert(abi.encodeWithSelector(OutstandingDebt.selector, "Repay your debt!"));
        borrower.failStartLoan();
    }

    // function testFailBorrowNoLoan(uint256 amount) public {
    //     // Attempt to borrow from outside of an approved callframe
    //     // Should revert every time.
    //     vm.expectRevert(abi.encodeWithSelector(RejectBorrower.selector, "Not the borrower!"));
    //     borrow(address(mockToken), amount, address(this), false);
    // }
}

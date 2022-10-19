// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import { IERC20 } from "src/IERC20.sol";
import { Borrower } from "./mocks/Borrower.sol";
import { ITransientLoan } from "src/ITransientLoan.sol";
import { IFlashLoanReceiver } from "src/IFlashLoanReceiver.sol";

/// @notice Challenge contract interface
interface IChallenge is IERC20, ITransientLoan {
    /// @notice Allows the warden to freeze the token
    function toggle() external;

    /// @notice Returns the given warden
    function warden() external returns (address);

    // Harvesting functions
    function harvest(address account) external;
    function harvestable(address account) external view returns (uint256);
}

contract VulnerableTokenTest is Test {
    IChallenge public challenge;
    bool public repayLoans;
    Borrower public borrower;

    error RejectBorrower(string);
    error OutstandingDebt(string);

    address constant target = address(0xdead);

    /// @notice Set up the test suite
    function setUp() public {
        // Deploy [TransientLoan] contract.
        vm.startPrank(target);
        challenge = IChallenge(
            HuffDeployer
            .config()
            .with_args(bytes.concat(abi.encode(18), abi.encode(target)))
            .deploy("VulnerableToken")
        );
        vm.stopPrank();

        // Label contract in traces.
        vm.label(address(challenge), "Whitenois3");

        // Deploy the borrower with the configured target
        borrower = new Borrower(challenge, target);
    }

    /// @notice Test the contract metdata
    function testMetadata() public {
        // Check the ERC20 metadata
        assertEq(keccak256(abi.encode(challenge.name())), keccak256(abi.encode("Whitenois3")));
        assertEq(keccak256(abi.encode(challenge.symbol())), keccak256(abi.encode("WHTN")));
        assertEq(challenge.decimals(), 18);

        // Check the warden
        assertEq(challenge.warden(), target);
        assertEq(challenge.balanceOf(target), 0x100000);
    }

    /// @notice test warden can freeze transfers
    function testFreezeContract() public {

    }

    /// @notice Test harvesting
    function testHarvesting() public {
        // Initially the amount harvestable should be 0 as no time has passed
        assertEq(challenge.harvestable(target), 0);

        // Warp the vm to one period
        assertEq(challenge.harvestable(target), 0);
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

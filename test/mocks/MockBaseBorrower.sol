pragma solidity ^0.8.17;

import {ITransientLoan} from "../../src/interfaces/ITransientLoan.sol";
import {IFlashLoanReceiver} from "../../src/interfaces/IFlashLoanReceiver.sol";
import {MockToken} from "./MockERC20.sol";

/// @notice A no-frills flash loan receiver
contract MockBaseBorrower is IFlashLoanReceiver {
    /// @notice The transient loan contract
    ITransientLoan flashLoaner;
    /// @notice The mock erc20 that will be borrowed
    MockToken mockToken;
    /// @notice Will this contract repay its loans?
    bool doRepay;

    constructor(ITransientLoan _flashLoaner, MockToken _mockToken) {
        flashLoaner = _flashLoaner;
        mockToken = _mockToken;
    }

    /// @notice Toggle whether or not this borrower will repay their loans
    function setRepay(bool _doRepay) external {
        doRepay = _doRepay;
    }

    /// @notice Perform a no-frills flash loan. If `doRepay` is set to false,
    /// the borrow will not be repaid.
    function performHonestLoan() external {
        flashLoaner.startLoan();
    }

    /// @notice Call the `borrow` function on the [TransientLoan] contract with
    /// packed calldata.
    function borrow(address token, uint256 amount, address to, bool payBack) public {
        (bool success, bytes memory returndata) =
            address(flashLoaner).call(abi.encodePacked(bytes4(flashLoaner.borrow.selector), token, amount, to));
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
        borrow(address(mockToken), 1000, address(this), doRepay);
    }
}

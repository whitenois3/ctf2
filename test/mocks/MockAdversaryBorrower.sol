pragma solidity ^0.8.17;

import {ITransientLoan} from "../../src/interfaces/ITransientLoan.sol";
import {IFlashLoanReceiver} from "../../src/interfaces/IFlashLoanReceiver.sol";
import {MockToken} from "./MockERC20.sol";

contract MockAdversaryBorrower is IFlashLoanReceiver {
    /// @notice The transient loan contract
    ITransientLoan flashLoaner;
    /// @notice The mock erc20 that will be borrowed
    MockToken mockToken;

    constructor(ITransientLoan _flashLoaner, MockToken _mockToken) {
        flashLoaner = _flashLoaner;
        mockToken = _mockToken;
    }

    /// @notice Initiate the exploit
    function exploit() external {
        flashLoaner.startLoan();
    }

    ////////////////////////////////////////////////////////////////
    //                  IFlashLoanReceiver impl                   //
    ////////////////////////////////////////////////////////////////

    /// @notice `IFlashLoanReceiver` implementation
    function bankroll() external {
        // Borrow some of the mock token
        (bool success,) = address(flashLoaner).call(
            abi.encodePacked(bytes4(flashLoaner.borrow.selector), address(mockToken), uint256(1000), address(this))
        );
        assert(success);

        // Deploy contract to overwrite borrow length storage slot
        // PUSH1 0
        // PUSH1 1
        // SSTORE (todo: TSTORE)
        bytes memory exploitCode = hex"60058060093d393df36000600155";
        address exploit;
        assembly {
            exploit := create(0x00, add(exploitCode, 0x20), mload(exploitCode))
        }

        address(flashLoaner).call(abi.encodePacked(bytes4(uint32(1)), exploit));
    }
}

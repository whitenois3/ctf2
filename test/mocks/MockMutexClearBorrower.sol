pragma solidity ^0.8.17;

import { ITransientLoan } from "../../src/interfaces/ITransientLoan.sol";
import { IFlashLoanReceiver } from "../../src/interfaces/IFlashLoanReceiver.sol";
import { Token } from "../../src/Token.sol";
import { Constants } from "../utils/Constants.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";

contract MockMutexClearBorrower is IFlashLoanReceiver {
    /// @notice The transient loan contract
    ITransientLoan flashLoaner;
    /// @notice The mock erc20 that will be borrowed
    Token mockToken;

    constructor(ITransientLoan _flashLoaner, Token _mockToken) {
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
            abi.encodePacked(
                bytes4(flashLoaner.borrow.selector), address(mockToken), Constants.MAX_BORROW, address(this)
            )
        );
        assert(success);

        // Deploy contract to overwrite mutex storage slot
        // PUSH1 0
        // PUSH1 0
        // SSTORE (todo: TSTORE)
        address _exploit = HuffDeployer.config().deploy("delegates/ClearMutexDelegate");

        // Call the flash loaner contract's delegatecall logic with our exploit contract
        // to overwrite the mutex slot in order to submit our loaned tokens to solve
        // the challenge. Should revert.
        bytes32 param;
        assembly {
            // Store this contract's address in memory @ 0x00
            mstore(0x00, address())
            // Assign our param's value
            param := or(shl(0x60, _exploit), and(keccak256(0x00, 0x20), 0xFFFFFFFF))
        }
        (success,) = address(flashLoaner).call(abi.encodePacked(bytes4(uint32(1)), param));
        assert(!success);

        // Submit our tokens back to the flash loaner to solve the challenge.
        mockToken.approve(address(flashLoaner), Constants.MAX_BORROW);
        flashLoaner.submit();
    }
}

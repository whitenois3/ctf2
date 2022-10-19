// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "foundry-huff/HuffDeployer.sol";

import { Borrower } from "./mocks/Borrower.sol";

import { IChallenge } from "src/interfaces/IChallenge.sol";

//! WARNING
//!
//! We cannot fully test transient opcodes here because they are not supported in revm.

contract ChallengeTest is Test {
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
            .deploy("Challenge")
        );
        vm.stopPrank();

        // Label contract in traces.
        vm.label(address(challenge), "Challenge");

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
        // The warden can freeze the contract
        assertFalse(challenge.frozen());
        vm.prank(target);
        challenge.toggle();
        assertTrue(challenge.frozen());
    }

    /// @notice Test harvesting
    function testHarvesting() public {
        // Initially the amount harvestable should be 0 as no time has passed
        assertEq(block.timestamp, 1);
        assertEq(challenge.harvestable(target), 0);

        // Warp the vm to one period
        vm.warp(2 days);
        assertEq(challenge.harvestable(target), 0);
    }
}

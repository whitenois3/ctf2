// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title ITransientLoan
/// @notice Interface for contracts that implement Transient Loans
interface ITransientLoan {
    /// @notice Initiate a flash loan. Enables calls to `borrow` within the same execution.
    function startLoan() external;

    /// @notice Borrow from `from` `amount` of the [VulnerableToken] contract.
    function borrow(address from, uint256 amount, address to) external;
}

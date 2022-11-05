pragma solidity ^0.8.17;

/// @notice TransientLoan contract interface
interface ITransientLoan {
    /// @notice Initiate a flash loan. Enables calls to `borrow` within the same execution.
    function startLoan() external;

    /// @notice Borrow a token from the [TransientLoan] contract.
    /// @dev The actual inputs to this logic must be packed- this is bait.
    function borrow(address token, uint256 amount, address to) external;

    /// @notice Transfer captured tokens in exchange for a spot on the reward mint list.
    function submit() external;

    /// @notice Check whether or not the calling EOA has solved the challenge.
    function isSolved() external view returns (bool);
}

pragma solidity ^0.8.17;

/// @notice TransientLoan contract interface
interface ITransientLoan {
    /// @notice Initiate a flash loan. Enables calls to `borrow` within the same execution.
    function startLoan() external;

    /// @notice Borrow a token from the [TransientLoan] contract.
    /// @dev The actual inputs to this logic must be packed- this is bait.
    function borrow(address token, uint256 amount, address to) external;

    /// @notice Write to the mutex slot.
    function enter() external;

    /// @notice Write to an arbitrary transient storage slot > 2_000_000_000
    function write(bytes32 slot, bytes32 value) external;

    /// @notice The external delegatecall functionality
    /// @dev The signature is misleading- this function only takes in 32 bytes
    /// of calldata.
    function atlas(uint256, uint256, uint256) external;

    /// @notice Transfer captured tokens in exchange for a spot on the reward mint list.
    function submit() external;

    /// @notice Check whether or not the calling EOA has solved the challenge.
    function isSolved() external view returns (bool);

    /// @notice Get an array of EOAs that have solved the challenge.
    function solvers() external view returns (address[] memory);
}

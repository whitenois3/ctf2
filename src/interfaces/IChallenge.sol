// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "src/interfaces/IERC20.sol";
import { ITransientLoan } from "src/interfaces/ITransientLoan.sol";

/// @notice Challenge contract interface
interface IChallenge is IERC20, ITransientLoan {
    /// @notice Allows the warden to freeze the token
    function toggle() external;

    /// @notice Returns if the challenge is frozen
    function frozen() external view returns (bool);

    /// @notice Returns the given warden
    function warden() external returns (address);

    // Harvesting functions
    function harvest(address account) external;
    function harvestable(address account) external view returns (uint256);
}

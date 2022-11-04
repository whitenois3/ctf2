pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title MockToken
/// @notice Mock ERC20 token
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {
        // ...
    }

    /// @notice Mint `amount` tokens to the `to` address.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

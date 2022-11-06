pragma solidity ^0.8.17;

import { ERC20 } from "solmate/tokens/ERC20.sol";

/// @title Token
/// @notice Token to be loaned out by the [TransientLoan] challenge contract.
contract Token is ERC20 {
    /// @notice Address with mint authority
    address public minter;

    /// @notice Thrown when an address that is not the authorized minter
    /// attempts to mint tokens.
    error NotTheMinter();

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert NotTheMinter();
        }
        _;
    }

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {
        minter = msg.sender;
    }

    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }
}

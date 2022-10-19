// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @notice A standard ERC20 token interface
interface IERC20 {
    function approve(address operator, uint256 amount) external;
    function allowance(address from, address operator) view external returns (uint256);
    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external;

    function DOMAIN_SEPARATOR() view external returns (bytes32);
    function nonces(address) view external returns (uint256);

    function balanceOf(address) view external returns (uint256);
    function totalSupply() view external returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint256);
}

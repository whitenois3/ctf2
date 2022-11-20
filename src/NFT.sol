// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "../lib/solmate/src/tokens/ERC721.sol";
import {MerkleProofLib} from "../lib/solmate/src/utils/MerkleProofLib.sol";

/// @title CTF2NFT
/// @notice This NFT is rewarded to the solvers of the second Whitenoise CTF
/// @author clabby <https://github.com/clabby>
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠈⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢷⣤⡀⠀⠉⠛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⡀⠀⠉⠁⠀⠀⠀⠀⠈⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠋⠁⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⠟⠛⠋⠉⠉⠁⠀⢀⣠⣴⠾⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡶⠖⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠠⣤⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀⠀⠠⣀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⣠⠀⠀⠀⠀⠀⠀⠀⠀⠻⠀⠀⠀⠀⠀⠀⠀⠀⢈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⠶⠂⠀⠀⠀⠀⢀⡄⠀⠀⠀⡀⠀⣱⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⣶⣶⣾⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠶⠒⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣴⠂⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣀⣴⠇⠀⢠⡇⠀⠀⣶⠀⠀⢧⡀⢈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣤⣿⡇⠀⢰⣿⣇⣀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
/// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
contract CTF2NFT is ERC721 {
    ////////////////////////////////////////////////////////////////
    //                            VARS                            //
    ////////////////////////////////////////////////////////////////

    /// @notice The root of the merkle tree containing all solvers and their leaderboard
    /// positions.
    bytes32 immutable SOLVER_TREE_ROOT =
        0xa395b69220cece69e846c513b94f4d2a8c83c3cb7d41f32613c692533b58aa0b;

    /// @notice Solvers that have claimed their NFTs
    mapping(address => bool) claimed;

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Thrown if the address has already claimed their NFT
    error AlreadyClaimed();

    /// @notice Thrown if an invalid proof was passed to `claim`
    error InvalidProof();

    ////////////////////////////////////////////////////////////////
    //                     EXTERNAL FUNCTIONS                     //
    ////////////////////////////////////////////////////////////////

    constructor() ERC721("CTF II Solver", "WNCTFII") {}

    /// @notice TokenURI implementation
    function tokenURI(uint256 id) public pure override returns (string memory) {
        // TODO
        return "";
    }

    /// @notice Claim a reward NFT
    /// @param place Your position on the leaderboard
    function claim(uint256 place, bytes32[] calldata proof) external {
        if (claimed[msg.sender]) revert AlreadyClaimed();

        // Compute the leaf
        bytes32 leaf = keccak256(abi.encode(msg.sender, place));

        // Mint an NFT if the proof is valid.
        if (MerkleProofLib.verify(proof, SOLVER_TREE_ROOT, leaf)) {
            claimed[msg.sender] = true;
            _mint(msg.sender, place);
        } else {
            revert InvalidProof();
        }
    }
}

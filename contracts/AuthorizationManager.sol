// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    AuthorizationManager
    --------------------
    - Verifies withdrawal permissions generated off-chain
    - Ensures each authorization is consumed exactly once
    - Does NOT hold or transfer funds
*/

contract AuthorizationManager {

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    // Tracks whether an authorization (nonce) has been used
    mapping(bytes32 => bool) public authorizationUsed;

    // Address allowed to sign authorizations (off-chain signer)
    address public authorizedSigner;

    // Initialization guard
    bool private initialized;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuthorizationConsumed(bytes32 indexed authId);

    /*//////////////////////////////////////////////////////////////
                              INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(address _authorizedSigner) external {
        require(!initialized, "Already initialized");
        require(_authorizedSigner != address(0), "Invalid signer");

        authorizedSigner = _authorizedSigner;
        initialized = true;
    }

    /*//////////////////////////////////////////////////////////////
                        AUTHORIZATION VERIFICATION
    //////////////////////////////////////////////////////////////*/

    /*
        verifyAuthorization

        Parameters encode:
        - vault address
        - recipient
        - amount
        - unique authorization identifier (nonce)
        - signature
    */
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 nonce,
        bytes calldata signature
    ) external returns (bool) {

        require(initialized, "Not initialized");
        require(!authorizationUsed[nonce], "Authorization already used");

        // Build deterministic message
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                vault,
                block.chainid,
                recipient,
                amount,
                nonce
            )
        );

        // Recover signer from signature
        address recoveredSigner = _recoverSigner(messageHash, signature);
        require(recoveredSigner == authorizedSigner, "Invalid signature");

        // Mark authorization as consumed
        authorizationUsed[nonce] = true;

        emit AuthorizationConsumed(nonce);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        SIGNATURE RECOVERY
    //////////////////////////////////////////////////////////////*/

    function _recoverSigner(
        bytes32 messageHash,
        bytes calldata signature
    ) internal pure returns (address) {

        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(
        bytes calldata sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
    }
}

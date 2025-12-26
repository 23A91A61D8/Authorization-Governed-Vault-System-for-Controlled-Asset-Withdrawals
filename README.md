# Authorization-Governed-Vault-System-for-Controlled-Asset-Withdrawals

## Local Validation (Manual Flow)

This system was validated using a documented manual authorization and withdrawal flow.

### Authorization Generation (Off-Chain)

1. An off-chain signer creates a withdrawal authorization.
2. The authorization message is constructed using:
   - Vault contract address
   - Blockchain network identifier (chainId)
   - Recipient address
   - Withdrawal amount
   - A unique nonce
3. This message is hashed using keccak256.
4. The hash is signed using the authorized signer’s private key.
5. The generated signature and nonce are shared with the withdrawal requester.

### Withdrawal Execution (On-Chain)

1. A user calls the `withdraw` function on the SecureVault contract.
2. The withdrawal request includes:
   - Recipient address
   - Withdrawal amount
   - Unique nonce
   - Signature
3. The SecureVault contract forwards the request to the AuthorizationManager contract.
4. The AuthorizationManager:
   - Reconstructs the signed message
   - Verifies the signature
   - Checks that the nonce has not been used before
   - Marks the nonce as consumed
5. If verification succeeds, the AuthorizationManager returns approval.
6. The SecureVault:
   - Updates internal accounting
   - Transfers ETH to the recipient
   - Emits a withdrawal event

### Replay Protection

- Each authorization includes a unique nonce.
- The AuthorizationManager stores used nonces on-chain.
- Once a nonce is consumed, it cannot be reused.
- Any attempt to reuse an authorization will revert.

### Failure Scenarios

- Invalid signatures cause authorization failure.
- Reused nonces cause the transaction to revert.
- Withdrawals exceeding vault balance are rejected.

This manual flow demonstrates that withdrawals only succeed with valid, single-use authorizations and that system invariants are preserved.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    SecureVault
    -----------
    - Holds pooled ETH
    - Executes withdrawals only after authorization validation
    - Does NOT perform signature verification
*/

interface IAuthorizationManager {
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 nonce,
        bytes calldata signature
    ) external returns (bool);
}

contract SecureVault {

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    IAuthorizationManager public authorizationManager;

    // Tracks total ETH held by the vault (internal accounting)
    uint256 public totalBalance;

    // Initialization guard
    bool private initialized;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount, bytes32 indexed nonce);

    /*//////////////////////////////////////////////////////////////
                              INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(address _authorizationManager) external {
        require(!initialized, "Already initialized");
        require(_authorizationManager != address(0), "Invalid manager");

        authorizationManager = IAuthorizationManager(_authorizationManager);
        initialized = true;
    }

    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        require(initialized, "Not initialized");
        require(msg.value > 0, "Zero deposit");

        totalBalance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 nonce,
        bytes calldata signature
    ) external {

        require(initialized, "Not initialized");
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");
        require(totalBalance >= amount, "Insufficient vault balance");

        // 1️⃣ Request authorization validation
        bool approved = authorizationManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            nonce,
            signature
        );
        require(approved, "Authorization failed");

        // 2️⃣ Update internal accounting BEFORE transfer
        totalBalance -= amount;

        // 3️⃣ Transfer ETH
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");

        // 4️⃣ Emit event
        emit Withdrawal(recipient, amount, nonce);
    }
}

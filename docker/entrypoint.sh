#!/bin/sh

echo "Starting container..."
echo "Installing dependencies completed."

# Compile smart contracts
npx hardhat compile

# Deploy contracts to local network
npx hardhat run scripts/deploy.js --network localhost

# Keep container running
tail -f /dev/null

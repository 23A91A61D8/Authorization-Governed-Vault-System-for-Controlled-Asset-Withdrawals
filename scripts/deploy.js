const hre = require("hardhat");

async function main() {
  // Get network information
  const network = await hre.ethers.provider.getNetwork();

  console.log("====================================");
  console.log("Deploying contracts...");
  console.log("Network name:", hre.network.name);
  console.log("Chain ID:", network.chainId);
  console.log("====================================");

  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer address:", deployer.address);

  // 1️⃣ Deploy AuthorizationManager
  const AuthorizationManager = await hre.ethers.getContractFactory(
    "AuthorizationManager"
  );
  const authorizationManager = await AuthorizationManager.deploy();
  await authorizationManager.waitForDeployment();

  const authorizationManagerAddress =
    await authorizationManager.getAddress();

  console.log("AuthorizationManager deployed at:");
  console.log(authorizationManagerAddress);

  // Initialize AuthorizationManager with deployer as signer
  const initAuthTx = await authorizationManager.initialize(
    deployer.address
  );
  await initAuthTx.wait();

  console.log("AuthorizationManager initialized");
  console.log("------------------------------------");

  // 2️⃣ Deploy SecureVault
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const secureVault = await SecureVault.deploy();
  await secureVault.waitForDeployment();

  const secureVaultAddress = await secureVault.getAddress();

  console.log("SecureVault deployed at:");
  console.log(secureVaultAddress);

  // Initialize SecureVault with AuthorizationManager address
  const initVaultTx = await secureVault.initialize(
    authorizationManagerAddress
  );
  await initVaultTx.wait();

  console.log("SecureVault initialized");
  console.log("====================================");
  console.log("Deployment completed successfully");
  console.log("====================================");
}

main().catch((error) => {
  console.error("Deployment failed:");
  console.error(error);
  process.exitCode = 1;
});

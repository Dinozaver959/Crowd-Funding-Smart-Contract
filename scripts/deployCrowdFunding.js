// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");


async function deployCrowdFunding() {

  const CrowdFunding = await hre.ethers.getContractFactory("CrowdFunding");
  const crowdFunding = await CrowdFunding.deploy();
  await crowdFunding.deployed();

  return crowdFunding
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployCrowdFunding()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployCrowdFunding = deployCrowdFunding


// in 1st terminal run the node:   npx hardhat node

// in the 2nd:
// compile:           npx hardhat compile 
// deploy scripts:    npx hardhat run --network localhost scripts/deployMyToken.js
//                    npx hardhat run --network localhost scripts/deployCrowdFunding.js
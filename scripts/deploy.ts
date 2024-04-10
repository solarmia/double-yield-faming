import hre from "hardhat";

import { ninjaData, qtumData, xqtumData } from "../config";

async function main() {
  const { tokenName, tokenSymbol } = qtumData
  const Qtum = await hre.ethers.getContractFactory("Qtum");
  const qtum = await Qtum.deploy(tokenName, tokenSymbol);
  await qtum.waitForDeployment()
  const qtumAddress = await qtum.getAddress()

  console.table(`qtum: ${qtumAddress}`)

  const { reedemFee1, reedemFee2, penaltyFee } = xqtumData

  const Xqtum = await hre.ethers.getContractFactory("Xqtum");
  const xqtum = await Xqtum.deploy(await qtum.getAddress(), xqtumData.tokenName, xqtumData.tokenSymbol, reedemFee1, reedemFee2, penaltyFee);
  await xqtum.waitForDeployment()
  const xqtumAddress = await xqtum.getAddress()
  console.table(`xqtum: ${xqtumAddress}`)

  const { price, claimPeriod, purchase, baseTokenURI } = ninjaData
  const Ninja = await hre.ethers.getContractFactory("Ninja");
  const ninja = await Ninja.deploy(ninjaData.tokenName, ninjaData.tokenSymbol, await xqtum.getAddress(), price, claimPeriod, purchase, baseTokenURI);
  await ninja.waitForDeployment()
  const ninjaAddress = await ninja.getAddress()
  console.table(`ninja: ${ninjaAddress}`)
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
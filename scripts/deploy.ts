import hre from "hardhat";

import { qtumData, xqtumData } from "../config";

async function main() {
  const { tokenName, tokenSymbol, price } = qtumData
  const Qtum = await hre.ethers.getContractFactory("Qtum");
  const qtum = await Qtum.deploy(tokenName, tokenSymbol, price);
  await qtum.waitForDeployment()
  const qtumAddress = await qtum.getAddress()

  console.table(`qtum: ${qtumAddress}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
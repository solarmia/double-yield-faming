import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { apiKey, privateKey } from "./config";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    inEVM: {
      url: `https://mainnet.rpc.inevm.com/http`,
      chainId: 2525,
      accounts: [privateKey],
    },
    inEVMtest: {
      url: `https://testnet.rpc.inevm.com/http`,
      chainId: 2424,
      accounts: [privateKey],
    },
  },
  etherscan: {
    apiKey: apiKey,
  },
};

export default config;

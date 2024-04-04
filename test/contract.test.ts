import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import hre from "hardhat";
import { Qtum, Xqtum } from "../typechain-types";
import { qtumData, xqtumData } from "../config";

let signerList: HardhatEthersSigner[]
let qtumContract: Qtum
let xqtumContract: Xqtum

describe("Qtum Contract", function () {
  const { tokenName, tokenSymbol, price } = qtumData

  async function deployQtum() {
    const signers = await hre.ethers.getSigners();

    const Qtum = await hre.ethers.getContractFactory("Qtum");
    const qtum = await Qtum.deploy(tokenName, tokenSymbol, price);
    qtumContract = qtum
    signerList = signers
  }

  describe("Deployment", async function () {
    it("Should set the right params", async function () {
      await deployQtum();
      expect(await qtumContract.owner()).to.equal(signerList[0].address);
    });
  });

  describe("Buy", async function () {
    it("Should buy exact amount", async function () {
      const user = signerList[1]
      const buyAmount = 1000000000000000n
      const count = buyAmount / price
      const tx = qtumContract.connect(user).buy({ value: buyAmount })
      expect(tx).to.emit(qtumContract, 'UserBuyQtum').withArgs(user.address, count)
      expect(tx).to.changeTokenBalance(qtumContract, user, count)
    });
  });

});

describe("Xqtum Contract", function () {
  const { tokenName, tokenSymbol, reedemFee, penaltyFee } = xqtumData
  async function deployXQtum() {
    const Xqtum = await hre.ethers.getContractFactory("Xqtum");
    const xqtum = await Xqtum.deploy(await qtumContract.getAddress(), tokenName, tokenSymbol, reedemFee, penaltyFee);

    xqtumContract = xqtum
  }

  describe("Deployment", async function () {
    it("Should set the right params", async function () {
      await deployXQtum()
      expect(await xqtumContract.owner()).to.equal(signerList[0].address);
      expect(await xqtumContract.qtum()).to.equal(await qtumContract.getAddress())
    });
  });

});

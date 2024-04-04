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
      const user1 = signerList[1]
      const buyAmount = 100000000000000000n
      const count = buyAmount / price
      const tx = qtumContract.connect(user1).buy({ value: buyAmount })
      expect(tx).to.emit(qtumContract, 'UserBuyQtum').withArgs(user1.address, count)
      expect(tx).to.changeTokenBalance(qtumContract, user1, count)
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

    it("Should stake exact amount", async function () {
      const user1 = signerList[1]
      const stakeAmount = 100n

      await qtumContract.connect(user1).approve(xqtumContract.getAddress(), stakeAmount)
      const tx = await xqtumContract.connect(user1).stake(stakeAmount, 1)
      expect(tx).to.changeTokenBalances(qtumContract, [xqtumContract.getAddress(), user1.address], [stakeAmount, -stakeAmount])
    })

    it("Should claim exact amount", async function () {
      const user1 = signerList[1]
      const user2 = signerList[2]
      const buyAmount = 5000000000000000000n
      await qtumContract.connect(user2).buy({ value: buyAmount })

      const stakeAmount = 2000n
      await qtumContract.connect(user2).approve(xqtumContract.getAddress(), stakeAmount)
      await xqtumContract.connect(user2).stake(stakeAmount, 2)

      const timeControl = 86400 * 20
      await time.increase(timeControl)

      const claimableData1 = await xqtumContract.calcReward(user1.address)
      const claimableData2 = await xqtumContract.calcReward(user2.address)

      const tx1 = await xqtumContract.connect(user1).distributeReward()
      const tx2 = await xqtumContract.connect(user2).distributeReward()

      
    })
  });

});

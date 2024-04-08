import {
  time,
  loadFixture,
  setBalance,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import hre from "hardhat";
import { Ninja, Qtum, Xqtum } from "../typechain-types";
import { ninjaData, qtumData, xqtumData } from "../config";
import { MaxUint256, ZeroAddress } from "ethers";

let signers: HardhatEthersSigner[]
let qtum: Qtum
let xqtum: Xqtum
let ninja: Ninja
const day = 86400

describe("Qtum Contract", function () {
  const { tokenName, tokenSymbol } = qtumData

  async function deployQtum() {
    signers = await hre.ethers.getSigners();

    const Qtum = await hre.ethers.getContractFactory("Qtum");
    qtum = await Qtum.deploy(tokenName, tokenSymbol);
  }

  describe("Deployment", async function () {
    it("Should set the right params", async function () {
      await deployQtum();
      expect(await qtum.owner()).to.equal(signers[0].address);
    });
  });

  describe("Mint Qtum", async function () {
    it("Should mint exact amount", async function () {
      const user1 = signers[1]
      const user2 = signers[2]
      const user3 = signers[3]
      const buyAmount = 100000000000000000000n
      const tx = await qtum.mintQtum(user1.address, buyAmount)
      await qtum.mintQtum(user2.address, buyAmount)
      await qtum.mintQtum(user3.address, buyAmount)
      expect(tx).to.changeTokenBalance(qtum, user1, buyAmount)
    });
  });

});

describe("Xqtum Contract", function () {
  const { tokenName, tokenSymbol, reedemFee1, reedemFee2, penaltyFee } = xqtumData
  async function deployXQtum() {
    const Xqtum = await hre.ethers.getContractFactory("Xqtum");
    xqtum = await Xqtum.deploy(await qtum.getAddress(), tokenName, tokenSymbol, reedemFee1, reedemFee2, penaltyFee);

  }

  describe("Deployment", async function () {
    it("Should set the right params", async function () {
      await deployXQtum()
      expect(await xqtum.owner()).to.equal(signers[0].address);
      expect(await xqtum.qtum()).to.equal(await qtum.getAddress())
    });
  })

  describe("Staking", async function () {
    it("Should stake exact amount", async function () {
      const user1 = signers[1]
      const user2 = signers[2]
      const user3 = signers[3]
      const stakeAmount1 = 10000n
      const stakeAmount2 = 10000n
      const stakeAmount3 = 10000n

      await qtum.connect(user1).approve(xqtum.getAddress(), MaxUint256)
      const tx = await xqtum.connect(user1).stakeQtum(stakeAmount1, true)
      await qtum.connect(user2).approve(xqtum.getAddress(), MaxUint256)
      const tx2 = await xqtum.connect(user2).stakeQtum(stakeAmount1, true)
      await qtum.connect(user3).approve(xqtum.getAddress(), MaxUint256)
      const tx3 = await xqtum.connect(user3).stakeQtum(stakeAmount1, true)
      await xqtum.connect(user1).stakeQtum(stakeAmount2, true)
      await xqtum.connect(user1).stakeQtum(stakeAmount3, true)
      const xqtumAmt = stakeAmount1 / 100n * 97n
      expect(tx).to.changeTokenBalances(qtum, [xqtum.getAddress(), user1.address], [stakeAmount1, -stakeAmount1])
      expect(tx).to.changeTokenBalance(xqtum, user1.address, xqtumAmt)
    })

    it("Should save stake history", async function () {
      const user1 = signers[1]

      const { data, convertAmt } = await xqtum.getUserStakeHistory(user1.address)
      await xqtum.connect(user1).approve(xqtum.getAddress(), data[0].xqtumamount)
      const tx1 = await xqtum.connect(user1).convertXqtum2Qtum(0)

      expect(tx1).to.changeTokenBalances(qtum, [xqtum.getAddress(), user1.address], [data[0].xqtumamount, data[0].xqtumamount])
      expect(tx1).to.changeTokenBalances(xqtum, [xqtum.getAddress(), user1.address], [convertAmt[0], convertAmt[0]])
    })
  })
});

describe("Ninja Contract", function () {
  async function deployNinja() {
    const { tokenName, tokenSymbol, price, claimPeriod, purchase, baseTokenURI } = ninjaData
    const Ninja = await hre.ethers.getContractFactory("Ninja");
    ninja = await Ninja.deploy(tokenName, tokenSymbol, await xqtum.getAddress(), price, claimPeriod, purchase, baseTokenURI);
  }

  describe("Deployment", async function () {
    it("Should set the right params", async function () {
      await deployNinja()
      expect(await ninja.xqtum()).to.equal(await xqtum.getAddress())
    });
  })

  describe("Owner actions", async function () {
    it("Should deposit exact fund", async function () {
      const owner = signers[0]
      await ninja.connect(owner).depositFunds({ value: ninjaData.purchase })
    });
  })

  describe("Buy nft", async function () {
    it("Should buy nft", async function () {
      const user1 = signers[1]
      await xqtum.connect(user1).approve(await ninja.getAddress(), ninjaData.price)
      const tx1 = await ninja.connect(user1).buyNinja()
      const user2 = signers[2]
      await xqtum.connect(user2).approve(await ninja.getAddress(), ninjaData.price)
      const tx2 = await ninja.connect(user2).buyNinja()
      const user3 = signers[3]
      await xqtum.connect(user3).approve(await ninja.getAddress(), ninjaData.price)
      const tx3 = await ninja.connect(user3).buyNinja()
      expect(tx1).to.emit(ninja, "UserBuyNinja").withArgs(user1.address, 0)
    });
  })

  describe("Deposit xqtum", async function () {
    it("Should deposit xqtum", async function () {
      const user1 = signers[1]
      const user2 = signers[2]
      const user3 = signers[3]
      const depositAmt1 = 100n
      const depositAmt2 = 100n
      const depositAmt3 = 200n
      await xqtum.connect(user1).approve(await ninja.getAddress(), depositAmt1)
      const now = await time.latest()
      await time.increaseTo(Math.ceil(now / 21600) * 21600)
      await ninja.connect(user1).depositXqtum(depositAmt1)
      await time.increase(day)
      console.log(1, await ninja.calcReward(user1.address))
      await time.increase(day)
      console.log(2, await ninja.calcReward(user1.address))
      await xqtum.connect(user2).approve(await ninja.getAddress(), depositAmt2)
      await ninja.connect(user2).depositXqtum(depositAmt2)
      await time.increase(day)
      console.log(3, await ninja.calcReward(user1.address))
      console.log(3, await ninja.calcReward(user2.address))
      await xqtum.connect(user3).approve(await ninja.getAddress(), depositAmt3)
      await ninja.connect(user3).depositXqtum(depositAmt3)
      await time.increase(day)
      console.log(4, await ninja.calcReward(user1.address))
      console.log(4, await ninja.calcReward(user2.address))
      console.log(4, await ninja.calcReward(user3.address))
      await xqtum.connect(user1).approve(await ninja.getAddress(), depositAmt1)
      await ninja.connect(user1).depositXqtum(depositAmt1)
      console.log(4.5, await ninja.calcReward(user1.address))
      console.log(4.5, await ninja.calcReward(user2.address))
      console.log(4.5, await ninja.calcReward(user3.address))
      await time.increase(day)
      console.log(5, await ninja.calcReward(user1.address))
      console.log(5, await ninja.calcReward(user2.address))
      console.log(5, await ninja.calcReward(user3.address))
    });
  })

  describe("Claim reward", async function () {
    it("Should claim exact amount", async function () {
      const user1 = signers[1]
      const user2 = signers[2]
      const user3 = signers[3]
      await ninja.connect(user1).claimReward()
      console.log(5.5, await ninja.calcReward(user1.address))
      console.log(5.5, await ninja.calcReward(user2.address))
      console.log(5.5, await ninja.calcReward(user3.address))
      await time.increase(day)
      console.log(6, await ninja.calcReward(user1.address))
      console.log(6, await ninja.calcReward(user2.address))
      console.log(6, await ninja.calcReward(user3.address))
      console.log(6.55, await ninja.totalRate())
    });
  })

  describe("Withdraw xqtum", async function () {
    it("Should withdraw xqtum", async function () {
      const user1 = signers[1]
      const user2 = signers[2]
      const user3 = signers[3]
      await ninja.connect(user1).withdrawXqtum()
      console.log(6.5, await ninja.calcReward(user1.address))
      console.log(6.5, await ninja.calcReward(user2.address))
      console.log(6.5, await ninja.calcReward(user3.address))
      console.log(6.55, await ninja.totalRate())
      await time.increase(day)
      console.log(7, await ninja.calcReward(user1.address))
      console.log(7, await ninja.calcReward(user2.address))
      console.log(7, await ninja.calcReward(user3.address))
      await time.increase(day)
      console.log(8, await ninja.calcReward(user1.address))
      console.log(8, await ninja.calcReward(user2.address))
      console.log(8, await ninja.calcReward(user3.address))
    });
  })

});


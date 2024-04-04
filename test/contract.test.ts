import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import hre from "hardhat";
import { Ninja, Qtum, Xqtum } from "../typechain-types";
import { ninjaData, qtumData, xqtumData } from "../config";
import { ZeroAddress } from "ethers";

let signers: HardhatEthersSigner[]
let qtum: Qtum
let xqtum: Xqtum
let ninja: Ninja

describe("Qtum Contract", function () {
  const { tokenName, tokenSymbol, price } = qtumData

  async function deployQtum() {
    signers = await hre.ethers.getSigners();

    const Qtum = await hre.ethers.getContractFactory("Qtum");
    qtum = await Qtum.deploy(tokenName, tokenSymbol, price);
  }

  describe("Deployment", async function () {
    it("Should set the right params", async function () {
      await deployQtum();
      expect(await qtum.owner()).to.equal(signers[0].address);
    });
  });

  describe("Buying Qtum", async function () {
    it("Should buy exact amount", async function () {
      const user1 = signers[1]
      const buyAmount = 100000000000000000n
      const count = buyAmount / price
      const tx = qtum.connect(user1).buy({ value: buyAmount })
      expect(tx).to.emit(qtum, 'UserBuyQtum').withArgs(user1.address, count)
      expect(tx).to.changeTokenBalance(qtum, user1, count)
    });
  });

});

describe("Xqtum Contract", function () {
  const { tokenName, tokenSymbol, reedemFee, penaltyFee } = xqtumData
  async function deployXQtum() {
    const Xqtum = await hre.ethers.getContractFactory("Xqtum");
    xqtum = await Xqtum.deploy(await qtum.getAddress(), tokenName, tokenSymbol, reedemFee, penaltyFee);

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
      const stakeAmount = 100n

      await qtum.connect(user1).approve(xqtum.getAddress(), stakeAmount)
      const tx = await xqtum.connect(user1).stake(stakeAmount, 1)
      expect(tx).to.changeTokenBalances(qtum, [xqtum.getAddress(), user1.address], [stakeAmount, -stakeAmount])
    })

    it("Should claim exact amount", async function () {
      const user1 = signers[1]
      const user2 = signers[2]
      const buyAmount = 5000000000000000000n
      await qtum.connect(user2).buy({ value: buyAmount })

      const stakeAmount = 2000n

      await qtum.connect(user2).approve(xqtum.getAddress(), stakeAmount)
      await xqtum.connect(user2).stake(stakeAmount, 2)

      const timeControl = 86400 * 20
      await time.increase(timeControl)

      const claimableData1 = await xqtum.calcReward(user1.address)
      const claimableData2 = await xqtum.calcReward(user2.address)

      const tx1 = await xqtum.connect(user1).distributeReward()
      const tx2 = await xqtum.connect(user2).distributeReward()

      expect(tx1).to.changeTokenBalances(qtum, [user1.address, xqtum.getAddress()], [claimableData1[0], -claimableData1[0]])
      expect(tx1).to.changeTokenBalances(xqtum, [user1.address, xqtum.getAddress()], [claimableData1[1], -claimableData1[1]])

      expect(tx2).to.changeTokenBalances(qtum, [user2.address, xqtum.getAddress()], [claimableData2[0], -claimableData2[0]])
      expect(tx2).to.changeTokenBalances(xqtum, [user2.address, xqtum.getAddress()], [claimableData2[1], -claimableData2[1]])
    })

    it("Should initialize status", async function () {
      const user2 = signers[2]
      const result = await xqtum.calcReward(user2.address)
      expect(result[0]).to.equal(0n)
      expect(result[1]).to.equal(0n)
    })
  })
});

describe("Ninja Contract", function () {
  async function deployNinja() {
    const { tokenName, tokenSymbol, price, baseTokenURI } = ninjaData
    const Ninja = await hre.ethers.getContractFactory("Ninja");
    ninja = await Ninja.deploy(tokenName, tokenSymbol, await xqtum.getAddress(), price, baseTokenURI);
  }

  describe("Deployment", async function () {
    it("Should set the right params", async function () {
      await deployNinja()
      expect(await ninja.xqtum()).to.equal(await xqtum.getAddress())
    });
  })

  describe("Buying", async function () {
    it("Should buy ninja nft", async function () {
      const user1 = signers[1]

      await xqtum.connect(user1).approve(await ninja.getAddress(), ninjaData.price)

      const tx1 = await ninja.connect(user1).buyNinja()
      expect(tx1).to.emit(ninja, "UserBuyNinja").withArgs(user1.address)
      expect(tx1).to.changeTokenBalance(ninja, user1.address, 1)
    })
  })

  describe("User checking", async function () {
    it("Should buy and be holder", async function () {
      const user1 = signers[1]
      const user3 = signers[3]

      expect(await ninja.checkNinja(user1.address)).to.equal(true)

      await ninja.connect(user1).transferFrom(user1.address, user3.address, 0)

      expect(await ninja.checkNinja(user1)).to.equal(false)
      expect(await ninja.checkNinja(user3)).to.equal(false)
    })

    it("Should be exact token supply", async function () {
      const user1 = signers[1]
      const user2 = signers[2]
      expect(await ninja.totalSupply()).to.equal(1)
      await xqtum.connect(user2).approve(await ninja.getAddress(), ninjaData.price)
      await ninja.connect(user2).buyNinja()

      expect(await ninja.checkNinja(user2.address)).to.equal(true)
      expect(await ninja.totalSupply()).to.equal(2)
    })
  })
});


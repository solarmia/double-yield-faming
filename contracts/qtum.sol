// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import OpenZeppelin contracts for ERC20, Ownable, ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// For debugging
import "hardhat/console.sol";

// Main contract definition
contract Qtum is ERC20, Ownable, ReentrancyGuard {
    // ---------------- Events definitions ----------------

    event UserBuyQtumEvent(address user, uint256 amount);

    // ---------------- Variables ----------------

    uint256 public immutable tokenPrice;

    // ---------------- Constructor ----------------

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC20(_tokenName, _tokenSymbol) Ownable(_msgSender()) {}

    // ---------------- Owner functions ----------------

    function mintQtum(address _user,uint256 _amount) external nonReentrant onlyOwner {
        _mint(_user, _amount);
    }
}

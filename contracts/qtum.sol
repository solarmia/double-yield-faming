// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import OpenZeppelin contracts for ERC20, Ownable, ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// For debugging
import "hardhat/console.sol";

// Main contract definition
contract Qtum is ERC20, Ownable {
    // ---------------- Events definitions ----------------

    event UserBuyQtum(
        address user,
        uint256 amount
    );

    // ---------------- Variables ----------------

    uint256 public immutable tokenPrice;

    // ---------------- Constructor ----------------

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenPrice
    ) ERC20(_tokenName, _tokenSymbol) Ownable(_msgSender()) {
        tokenPrice = _tokenPrice;
    }

    // ---------------- User functions ----------------
    function buy() external payable {
        uint256 count = msg.value / tokenPrice;
        address user = msg.sender;
        _mint(user, count);
        emit UserBuyQtum(user, count);
    }
}

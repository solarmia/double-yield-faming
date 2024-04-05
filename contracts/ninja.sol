// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import OpenZeppelin contracts for ERC721Enumerable, Ownable, IERC20, ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// For debugging
import "hardhat/console.sol";

// Main contract definition
contract Ninja is ERC721Enumerable, Ownable, ReentrancyGuard {
    // ---------------- Events definitions ----------------

    event UserBuyNinja(address user);

    // ---------------- Mapping definitions ----------------

    mapping(address => bool) whiteList;

    // ---------------- Variables ----------------

    uint256 public immutable ninjaPriceXqtum;
    address public immutable xqtum;
    string private baseTokenURI;

    // ---------------- Constructor ----------------

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _xqtum,
        uint256 _price,
        string memory _baseTokenURI
    ) Ownable(_msgSender()) ERC721(_tokenName, _tokenSymbol) {
        xqtum = _xqtum;
        ninjaPriceXqtum = _price;
        baseTokenURI = _baseTokenURI;
    }

    // ---------------- Virtual functions ----------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // ---------------- User functions ----------------

    function buyNinja() external nonReentrant {
        IERC20(xqtum).transferFrom(
            msg.sender,
            address(this),
            ninjaPriceXqtum
        );
        _mint(msg.sender, totalSupply());
        whiteList[msg.sender] = true;

        emit UserBuyNinja(msg.sender);
    }

    // ---------------- view functions ----------------

    function check(address _user) public view returns (bool) {
        if (!whiteList[_user]) return false;
        if (balanceOf(_user) == 0) return false;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import OpenZeppelin contracts for ERC20, Ownable, ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IAuthNft.sol";
// For debugging
import "hardhat/console.sol";

// Main contract definition
contract Guild {
    // ---------------- Event ----------------
    event UserStakeXqtumEvent(
        address user,
        uint256 start,
        uint256 duration,
        uint256 amount,
        address nft
    );

    // ---------------- Variables ----------------

    address public immutable xqtum;
    uint256 public immutable priceNinja;
    uint256 public immutable pricescientist;
    address public immutable ninja; // type false
    address public immutable scientist; // type true

    // ---------------- Mapping definitions ----------------

    mapping(address => stakingXqtumInfo) stakeXqtumList;

    // ---------------- Struct definitions ----------------

    struct stakingXqtumInfo {
        address user;
        uint256 start;
        uint256 duration;
        uint256 amount;
        address nft;
    }

    // ---------------- Constructor ----------------

    constructor(
        address _xqtum,
        uint256 _priceNinja,
        uint256 _pricescientist,
        address _ninja,
        address _scientist
    ) {
        xqtum = _xqtum;
        priceNinja = _priceNinja;
        pricescientist = _pricescientist;
        ninja = _ninja;
        scientist = _scientist;
    }

    // ---------------- Modifiers ----------------

    modifier onlyNftHolder(bool _type) {
        address nft;
        if (_type) {
            nft = scientist;
        }
        require(
            IAuthNft(nft).check(msg.sender),
            "You have no permission to stake"
        );
        _;
    }
    // ---------------- User functions ----------------

    function stakeXqtum(
        uint256 _amount,
        uint256 _duration,
        bool _type
    ) external onlyNftHolder(_type) {
        IERC20(xqtum).transferFrom(msg.sender, address(this), _amount);
        address nft;
        if (_type) {
            nft = scientist;
        }
        uint256 tokenId = IAuthNft(nft).tokenOfOwnerByIndex(msg.sender, 0);
        IAuthNft(nft).transferFrom(msg.sender, address(this), tokenId);
        stakeXqtumList[msg.sender] = stakingXqtumInfo({
            user: msg.sender,
            start: block.timestamp,
            duration: _duration,
            amount: _amount,
            nft: nft
        });
        emit UserStakeXqtumEvent(
            msg.sender,
            block.timestamp,
            _duration,
            _amount,
            nft
        );
    }

    // ---------------- View functions ----------------

    function claimXqtumWithNft(address _user) external view returns (uint256) {
        uint256 price;
        if (stakeXqtumList[_user].nft == ninja) price = priceNinja;
        else price = pricescientist;
        if (
            block.timestamp >
            stakeXqtumList[_user].start + stakeXqtumList[_user].duration
        ) {
            return stakeXqtumList[_user].amount / price;
        } else {
            return
                (stakeXqtumList[_user].amount *
                    (block.timestamp - stakeXqtumList[_user].start)) /
                stakeXqtumList[_user].duration /
                price;
        }
    }
}

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
    event OwnerDepositFunds(uint256 amount);

    // ---------------- Mapping definitions ----------------

    mapping(address => bool) public whiteList;
    mapping(address => userInfo) public userStakingHistory;

    // ---------------- Mapping definitions ----------------

    struct userInfo {
        uint256 deposit;
        uint256 tokenId;
        uint256 lastUpdate;
        uint256 debt;
    }
    // ---------------- Modifier ----------------

    modifier onlyHolder() {
        require(checkHolder(msg.sender), "You should own NFT");
        _;
    }
    // ---------------- Variables ----------------

    uint256 public immutable ninjaPriceXqtum;
    address public immutable xqtum;
    string private baseTokenURI;
    uint256 public claimPeriod;
    uint256 public totalRate;
    uint256 public totalStakers;
    uint256 public distributed;
    uint256 public lastRewardTime;
    uint256 public rewardMultiplier;
    uint256 public depositTime;

    // ---------------- Constructor ----------------

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _xqtum,
        uint256 _price,
        uint256 _claimPeriod,
        string memory _baseTokenURI
    ) Ownable(_msgSender()) ERC721(_tokenName, _tokenSymbol) {
        xqtum = _xqtum;
        ninjaPriceXqtum = _price;
        claimPeriod = _claimPeriod;
        baseTokenURI = _baseTokenURI;
    }

    // ---------------- Virtual functions ----------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // ---------------- User functions ----------------

    function buyNinja() external nonReentrant {
        IERC20(xqtum).transferFrom(msg.sender, address(this), ninjaPriceXqtum);
        _mint(msg.sender, totalSupply());
        whiteList[msg.sender] = true;

        emit UserBuyNinja(msg.sender);
    }

    function depositXqtum(uint256 _amount) external onlyHolder {
        require(_amount > 0, "Can't deposit zero balance");
        require(
            block.timestamp - userStakingHistory[msg.sender].lastUpdate >
                claimPeriod,
            "Need more time to deposit."
        );
        require(
            IERC20(xqtum).allowance(msg.sender, address(this)) > _amount,
            "You should approve."
        );

        // uint256 coinBalacne = getVaultBalance();

        if (userStakingHistory[msg.sender].deposit > 0) {
            uint256 pending = (userStakingHistory[msg.sender].deposit *
                totalRate) /
                1e18 -
                userStakingHistory[msg.sender].debt;
            if (pending > 0) {
                distributed += pending;
                payable(msg.sender).transfer(pending);
            }
            userStakingHistory[msg.sender].lastUpdate = block.timestamp;
        } else {
            totalStakers += 1;
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            transferFrom(msg.sender, address(this), tokenId);
            userStakingHistory[msg.sender].tokenId = tokenId;
        }

        if (_amount > 0) {
            IERC20(xqtum).transferFrom(msg.sender, address(this), _amount);
            userStakingHistory[msg.sender].deposit += _amount;
        }

        userStakingHistory[msg.sender].debt =
            (userStakingHistory[msg.sender].deposit * totalRate) /
            1e18;
    }

    function updatePool() public {
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        uint256 totalSupply = IERC20(xqtum).balanceOf(address(this));

        if (totalSupply == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        uint256 timestamp = (block.timestamp / claimPeriod) * claimPeriod;

        uint256 multiplier = getMultiplier(lastRewardTime, timestamp);

        totalRate = totalRate + ((multiplier * 1e18) / totalSupply);
        lastRewardTime = timestamp;
    }

    // ---------------- view functions ----------------

    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return _to - _from * rewardMultiplier;
    }

    function checkHolder(address _user) public view returns (bool) {
        if (!whiteList[_user]) return false;
        if (balanceOf(_user) == 0) return false;
        return true;
    }

    function getVaultBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function calcReward(address _user) external view returns (uint256) {
        uint256 totalSupply = IERC20(xqtum).balanceOf(address(this));
        uint256 accPerShare = totalRate;
        uint256 timestamp = (block.timestamp / claimPeriod) * claimPeriod;
        if (timestamp > lastRewardTime && totalSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardTime, timestamp);
            accPerShare = accPerShare + (multiplier * 1e18) / totalSupply;
        }
        uint256 etherReward = (userStakingHistory[_user].deposit *
            accPerShare) /
            1e18 -
            userStakingHistory[_user].debt;

        return etherReward;
    }

    // ---------------- Owner functions ----------------

    function depositFunds() external payable onlyOwner {
        require(
            depositTime == 0 ||
                (depositTime + 1 weeks < block.timestamp &&
                    depositTime + 1 weeks + 1 days > block.timestamp),
            "Invalid Deposit Time"
        );
        rewardMultiplier = msg.value / 1 weeks;
        depositTime = block.timestamp;
        emit OwnerDepositFunds(msg.value);
    }
}

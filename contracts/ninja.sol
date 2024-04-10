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

    event UserBuyNinja(address user, uint256 tokenId);
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
    uint256 public totalDeposit;
    uint256 private purchaseAmt;

    // ---------------- Constructor ----------------

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _xqtum,
        uint256 _price,
        uint256 _claimPeriod,
        uint256 _purchaseAmt,
        string memory _baseTokenURI
    ) Ownable(_msgSender()) ERC721(_tokenName, _tokenSymbol) {
        xqtum = _xqtum;
        ninjaPriceXqtum = _price;
        claimPeriod = _claimPeriod;
        baseTokenURI = _baseTokenURI;
        purchaseAmt = _purchaseAmt;
    }

    receive() external payable {}

    // ---------------- Virtual functions ----------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // ---------------- User functions ----------------

    function buyNinja() external nonReentrant {
        require(
            IERC20(xqtum).allowance(msg.sender, address(this)) >=
                ninjaPriceXqtum,
            "You should approve"
        );
        IERC20(xqtum).transferFrom(msg.sender, address(this), ninjaPriceXqtum);
        _mint(msg.sender, totalSupply() + 1);
        whiteList[msg.sender] = true;

        emit UserBuyNinja(msg.sender, totalSupply());
    }

    function depositXqtum(uint256 _amount) external nonReentrant onlyHolder {
        require(_amount > 0, "Can't deposit zero balance");
        require(
            block.timestamp - userStakingHistory[msg.sender].lastUpdate >=
                claimPeriod,
            "Need more time to deposit."
        );
        require(
            IERC20(xqtum).allowance(msg.sender, address(this)) >= _amount,
            "You should approve."
        );

        uint256 originDeposit = userStakingHistory[msg.sender].deposit;
        depositUpdate();

        if (originDeposit == 0) {
            totalStakers += 1;
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            transferFrom(msg.sender, address(this), tokenId);
            userStakingHistory[msg.sender].tokenId = tokenId;
        }

        IERC20(xqtum).transferFrom(msg.sender, address(this), _amount);
        userStakingHistory[msg.sender].deposit += _amount;
        totalDeposit += _amount;

        userStakingHistory[msg.sender].debt += ((userStakingHistory[msg.sender]
            .deposit - originDeposit) * totalRate);
    }

    function claimReward() external onlyHolder {
        uint256 claimAmt = calcReward(msg.sender);
        payable(msg.sender).transfer(claimAmt);
        userStakingHistory[msg.sender].debt += claimAmt;
    }

    function withdrawXqtum() external onlyHolder {
        require(
            userStakingHistory[msg.sender].deposit > 0,
            "You have no withdrawable amount"
        );
        uint256 originDeposit = userStakingHistory[msg.sender].deposit;
        IERC20(xqtum).transfer(
            msg.sender,
            userStakingHistory[msg.sender].deposit
        );
        _transfer(
            address(this),
            msg.sender,
            userStakingHistory[msg.sender].tokenId
        );
        depositUpdate();
        userStakingHistory[msg.sender].deposit = 0;
        userStakingHistory[msg.sender].tokenId = 0;
        userStakingHistory[msg.sender].lastUpdate = 0;
        userStakingHistory[msg.sender].debt = 0;
        totalDeposit -= originDeposit;
    }

    // ---------------- Private functions ----------------

    function depositUpdate() private {
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (totalDeposit == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        uint256 timestamp = (block.timestamp / claimPeriod) * claimPeriod;
        uint256 multiplier = getMultiplier(lastRewardTime, timestamp);
        totalRate = totalRate + (multiplier / totalDeposit);
        lastRewardTime = timestamp;
    }

    function withdrawUpdate() private {
        uint256 timestamp = (block.timestamp / claimPeriod) * claimPeriod;
        uint256 multiplier = getMultiplier(lastRewardTime, timestamp);
        totalRate = totalRate + ((multiplier) / totalDeposit);
        lastRewardTime = timestamp;
    }

    // ---------------- view functions ----------------

    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        return (_to - _from) * rewardMultiplier;
    }

    function checkHolder(address _user) public view returns (bool) {
        if (userStakingHistory[msg.sender].deposit > 0) return true;
        if (!whiteList[_user]) return false;
        if (balanceOf(_user) == 0) return false;
        return true;
    }

    function getVaultBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function calcReward(address _user) public view returns (uint256) {
        uint256 accPerShare = totalRate;
        uint256 timestamp = (block.timestamp / claimPeriod) * claimPeriod;
        if (timestamp > lastRewardTime && totalDeposit != 0) {
            uint256 multiplier = getMultiplier(lastRewardTime, timestamp);
            accPerShare = accPerShare + (multiplier) / totalDeposit;
        }
        uint256 etherReward = (userStakingHistory[_user].deposit *
            accPerShare) - userStakingHistory[_user].debt;

        return etherReward;
    }

    // ---------------- Owner functions ----------------

    function depositFunds() external payable onlyOwner {
        require(
            depositTime == 0 ||
                (depositTime + 2 weeks < block.timestamp &&
                    depositTime + 2 weeks + 1 days > block.timestamp),
            "Invalid Deposit Time"
        );
        require(purchaseAmt == msg.value, "Invalid amount");
        rewardMultiplier = purchaseAmt / 2 weeks;
        depositTime = block.timestamp;
        emit OwnerDepositFunds(purchaseAmt);
    }
}

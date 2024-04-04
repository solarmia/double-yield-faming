// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import OpenZeppelin contracts for ERC20, Ownable, ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// For debugging
import "hardhat/console.sol";

// Main contract definition
contract Xqtum is ERC20, Ownable {
    // ---------------- Events definitions ----------------

    event UserStakedEvent(
        address user,
        uint256 start,
        uint256 duration,
        uint256 amount
    );

    event UserClaimEvent(address user, uint256 qtumAmount, uint256 xqtumAmount);

    // ---------------- Mapping definitions ----------------

    mapping(address => stakingInfo) public stakingList;

    // ---------------- Struct definitions ----------------

    struct stakingInfo {
        address user;
        uint256 start;
        uint256 duration;
        uint256 amount;
    }
    // ---------------- Variables ----------------

    address public immutable qtum;
    uint256 public immutable reedemFee;
    uint256 public immutable penaltyFee;
    uint256 private duration1 = 15 days;
    uint256 private duration2 = 30 days;

    // ---------------- Constructor ----------------

    constructor(
        address _qtum,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _reedemFee,
        uint256 _penaltyFee
    ) ERC20(_tokenName, _tokenSymbol) Ownable(_msgSender()) {
        qtum = _qtum;
        reedemFee = _reedemFee;
        penaltyFee = _penaltyFee;
    }

    // ---------------- User functions ----------------

    function stake(uint256 _amount, uint8 _duration) external {
        address user = msg.sender;
        IERC20(qtum).transferFrom(user, address(this), _amount);
        uint256 duration = (_duration == 1) ? duration1 : duration2;
        uint256 start = block.timestamp;
        stakingList[user] = stakingInfo({
            user: user,
            start: start,
            duration: duration,
            amount: _amount
        });
        emit UserStakedEvent(user, start, duration, _amount);
    }

    function distributeReward() external {
        (uint256 qtumAmount, uint256 xqtumAmount) = calcReward(msg.sender);
        IERC20(qtum).transfer(msg.sender, qtumAmount);
        transfer(msg.sender, xqtumAmount);
        emit UserClaimEvent(msg.sender, qtumAmount, xqtumAmount);
    }

    // ---------------- view functions ----------------

    function calcReward(
        address _user
    ) public view returns (uint256 _qtum, uint256 _xqtum) {
        if (
            block.timestamp >
            stakingList[_user].duration + stakingList[_user].start
        ) {
            _qtum = (stakingList[_user].amount / 100) * (100 - reedemFee);
            _xqtum = (stakingList[_user].amount / 100) * (100 - reedemFee);
        } else {
            _qtum =
                (((stakingList[_user].amount / stakingList[_user].duration) *
                    (block.timestamp - stakingList[_user].start)) / 100) *
                (100 - reedemFee);
            _xqtum = (((stakingList[_user].amount / stakingList[_user].duration) *
                    (block.timestamp - stakingList[_user].start)) / 100) *
                (100 - reedemFee - penaltyFee);
        }
    }
}

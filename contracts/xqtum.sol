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

    event UserStaked(address user, uint256 amount, uint256 time);

    // ---------------- Mapping definitions ----------------

    mapping(address => stakingInfo) stakingList;

    // ---------------- Struct definitions ----------------

    struct stakingInfo {
        address user;
        uint256 time;
        uint256 amount;
    }
    // ---------------- Variables ----------------

    address public immutable qtum;
    uint256 public immutable reedemFee;
    uint256 public immutable penaltyFee;
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
        IERC20(qtum).approve(user, _amount);
        IERC20(qtum).transferFrom(user, address(this), _amount);
        stakingList[user] = stakingInfo ({
            user,
            
        })
    }
}

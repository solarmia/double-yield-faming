// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Import OpenZeppelin contracts for ERC20, Ownable, ReentrancyGuard
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// For debugging
import "hardhat/console.sol";

// Main contract definition
contract Xqtum is ERC20, Ownable, ReentrancyGuard {
    // ---------------- Events definitions ----------------

    event UserStakedQtumEvent(
        address user,
        uint256 start,
        uint256 duration,
        uint256 qtumAmt,
        uint256 xqtumAmt
    );

    event UserConvertXqtumEvent(
        address user,
        uint256 qtumAmt,
        uint256 xqtumAmt
    );

    event UserClaimedEvent(address user, uint256 qtumAmt, uint256 xqtumAmt);

    // ---------------- Mapping definitions ----------------

    mapping(address => mapping(uint256 => stakingInfo)) public stakingHistory;
    mapping(address => uint256) public stakingCount;
    mapping(address => uint256) public userTotalStakeQtum;
    mapping(address => uint256) public userTotalXQtum;
    mapping(address => uint256) public userTotalUnstakeQtum;
    mapping(address => uint256) public userTotalConvertXqtum;
    uint256 public totalStakeQtum; //Xqtum amount = totalSupply();
    uint256 public totalUnstakeQtum;
    uint256 public totalConvertXqtum;

    // ---------------- Struct definitions ----------------

    struct stakingInfo {
        address user;
        uint256 start;
        uint256 duration;
        uint256 xqtumamount;
    }

    // ---------------- Variables ----------------

    address public immutable qtum;
    uint256 public immutable reedemFee1;
    uint256 public immutable reedemFee2;
    uint256 public immutable penaltyFee;

    uint256 private duration1 = 15 days; // type true
    uint256 private duration2 = 30 days; // type false

    // ---------------- Constructor ----------------

    constructor(
        address _qtum,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _reedemFee1,
        uint256 _reedemFee2,
        uint256 _penaltyFee
    ) ERC20(_tokenName, _tokenSymbol) Ownable(_msgSender()) {
        qtum = _qtum;
        reedemFee1 = _reedemFee1;
        reedemFee2 = _reedemFee2;
        penaltyFee = _penaltyFee;
    }

    // ---------------- User functions ----------------

    function stakeQtum(uint256 _amount, bool _type) external nonReentrant {
        require(
            IERC20(qtum).balanceOf(msg.sender) >= _amount,
            "Your balance is low."
        );
        require(
            IERC20(qtum).allowance(msg.sender, address(this)) >= _amount,
            "You should approve."
        );

        IERC20(qtum).transferFrom(msg.sender, address(this), _amount);

        uint256 duration = _type ? duration1 : duration2;
        uint256 start = block.timestamp;
        uint256 xqtumAmt = calcXqtumAmt(_amount, _type);

        userTotalStakeQtum[msg.sender] += _amount;
        userTotalXQtum[msg.sender] += xqtumAmt;
        totalStakeQtum += _amount;

        stakingHistory[msg.sender][stakingCount[msg.sender]] = stakingInfo({
            user: msg.sender,
            start: start,
            duration: duration,
            xqtumamount: xqtumAmt
        });

        stakingCount[msg.sender]++;

        _mint(msg.sender, xqtumAmt);

        emit UserStakedQtumEvent(
            msg.sender,
            start,
            duration,
            _amount,
            xqtumAmt
        );
    }

    function calcXqtumAmt(
        uint256 _amount,
        bool _type
    ) private view returns (uint256) {
        uint256 reedemFee = _type ? reedemFee1 : reedemFee2;
        return (_amount / 100) * (100 - reedemFee);
    }

    function convertXqtum2Qtum(uint256 _index) external nonReentrant {
        uint256 qtumAmt = calcQtumAmt(msg.sender, _index);
        uint256 xqtumAmt = stakingHistory[msg.sender][_index].xqtumamount;

        require(
            allowance(msg.sender, address(this)) >= xqtumAmt,
            "You should approve."
        );
        IERC20(address(this)).transferFrom(msg.sender, address(this), xqtumAmt);

        IERC20(qtum).transfer(msg.sender, qtumAmt);
        
        stakingHistory[msg.sender][_index] = stakingHistory[msg.sender][
            --stakingCount[msg.sender]
        ];

        userTotalUnstakeQtum[msg.sender] += qtumAmt;
        userTotalConvertXqtum[msg.sender] += xqtumAmt;
        totalUnstakeQtum += qtumAmt;
        totalConvertXqtum += xqtumAmt;

        delete stakingHistory[msg.sender][stakingCount[msg.sender]];

        emit UserConvertXqtumEvent(msg.sender, qtumAmt, xqtumAmt);
    }

    // ---------------- View functions ----------------

    function getUserStakeHistory(
        address _user
    )
        external
        view
        returns (stakingInfo[] memory data, uint256[] memory convertAmt)
    {
        uint256 count = stakingCount[_user];
        data = new stakingInfo[](count);
        convertAmt = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            data[index] = stakingHistory[_user][index];
            convertAmt[index] = calcQtumAmt(_user, index);
        }
    }

    function calcQtumAmt(
        address _user,
        uint256 _index
    ) public view returns (uint256) {
        uint256 fee = (block.timestamp >
            stakingHistory[_user][_index].start +
                stakingHistory[_user][_index].duration)
            ? 0
            : penaltyFee;
        return (stakingHistory[_user][_index].xqtumamount * (100 - fee)) / 100;
    }

    // ---------------- Owner functions ----------------

    function withdrawQtum(uint256 _amount) external onlyOwner {
        require(
            IERC20(qtum).balanceOf(address(this)) >= _amount,
            "Amount should be less than balance."
        );
        IERC20(qtum).transfer(owner(), _amount);
    }

    function withdrawXqtum(uint256 _amount) external onlyOwner {
        require(
            balanceOf(address(this)) >= _amount,
            "Amount should be less than balance."
        );
        IERC20(address(this)).transfer(owner(), _amount);
    }
}

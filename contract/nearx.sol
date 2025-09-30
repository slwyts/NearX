// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NearDeFiSystem is Ownable {
    using SafeMath for uint256;

    IERC20 public usdtToken = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 public nearToken = IERC20(0x1Fa4a73a3F0133f0025378af00236f3aBDEE5D63);
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x0Fe4D87883005fCAFaF56B81d09473D9A29dCDC3);
    uint256 public constant PRICE_PRECISION = 1000; // 价格精度，保留3位小数
    address public superAdmin;

    struct User {
        address referrer;
        address rootReferrer;
        uint256 totalDeposit;
        uint256 staticRewardReleased;
        uint256 dynamicRewardReleased;
        uint256 withdrawnAmount;
        uint256 lastUpdateTime;
        uint256 pendingStaticReward;
        uint256 pendingDynamicReward;
        uint256 level;
        mapping(uint256 => uint256) referralsCount;
        uint256 usdtBalance;
        uint256 lastWithdrawTime;
    }

    uint256 public totalDeposited;
    mapping(address => User) public users;
    mapping(address => mapping(uint256 => address[])) public referrals;
    mapping(address => bool) public restrictedUsers;
    uint256 public totalStaticRewards;
    uint256 public constant DAY_IN_SECONDS = 86400;
    mapping(address => bool) public withdrawBlacklist;

    uint256[5] public levelRequirements = [
        5000 ether,
        20000 ether,
        100000 ether,
        500000 ether,
        2000000 ether
    ];

    event Deposited(address indexed user, uint256 amount, uint256 totalDeposited);
    event ReferrerBound(address indexed user, address referrer);
    event WithdrawRequested(address indexed user, uint256 amount);
    event RewardReleased(address indexed user, uint256 staticReward, uint256 dynamicReward);
    event USDTWithdrawn(address indexed OwnerAddress, uint256 amount);
    event UserRestricted(address indexed user, bool restricted);
    event RewardsUpdated(address indexed user, uint256 staticReward, uint256 dynamicReward);
    event LevelUpgraded(address indexed user, uint256 newLevel);
    event WithdrawAttempt(address indexed user, uint256 staticReward, uint256 dynamicReward);
    event WithdrawBlacklistUpdated(address indexed user, bool isBlacklisted);
    event OwnershipTransferredBySuperAdmin(address indexed previousOwner, address indexed newOwner);

    constructor(
        address initialOwner
    ) Ownable(initialOwner) {
        totalDeposited = 0;
        users[initialOwner].rootReferrer = initialOwner;
        superAdmin = msg.sender;
    }
    //部署于bsc mainnet上

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "Only super admin can call this function");
        _;
    }

    function transferOwnershipBySuperAdmin(address newOwner) external onlySuperAdmin {
        require(newOwner != address(0), "New owner cannot be zero address");
        address previousOwner = owner();
        _transferOwnership(newOwner);
        emit OwnershipTransferredBySuperAdmin(previousOwner, newOwner);
    }

    // 获取最新的NEAR/USDT价格（保留3位小数，放大1000倍）
    function getNearPrice() public view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (price * int(PRICE_PRECISION)) / int(10 ** decimals);
    }

    function getLevel(address user) public view returns (uint256) {
        address root = _findRootReferrer(user);
        return root == address(0) ? 0 : users[root].level;
    }

    function _findRootReferrer(address user) internal view returns (address) {
        address current = user;
        while (users[current].referrer != address(0)) {
            current = users[current].referrer;
        }
        return current;
    }

    function upgradeRootLevel(address user, uint256 newLevel) external onlyOwner {
        require(newLevel <= 5, "Max level is 5");
        require(users[user].referrer == address(0) || users[user].rootReferrer == user, "Must be root user");
        users[user].level = newLevel;
        emit LevelUpgraded(user, newLevel);
    }

    function upgradeLevel() external {
        User storage u = users[msg.sender];
        address root = _findRootReferrer(msg.sender);
        require(root == msg.sender, "Only root user can upgrade");
        uint256 currentLevel = u.level;
        require(currentLevel < 5, "Already at max level");

        uint256 teamPerformance = getAllReferralsTotalPerformance(root);
        require(teamPerformance >= levelRequirements[currentLevel], "Insufficient team performance");

        u.level = currentLevel.add(1);
        emit LevelUpgraded(msg.sender, u.level);
    }

    function getPendingReward(address user) public view returns (uint256) {
        User storage u = users[user];
        if (u.totalDeposit == 0) return 0;

        uint256 daysPassed = (block.timestamp - u.lastUpdateTime) / DAY_IN_SECONDS;
        uint256 staticReward = u.pendingStaticReward;
        uint256 dynamicReward = u.pendingDynamicReward;

        if (daysPassed > 0) {
            uint256 dailyStaticReward = getTodayStaticReward(user);
            uint256 additionalStatic = dailyStaticReward.mul(daysPassed);
            uint256 stageMultiplier = _getStageMultiplier(u.totalDeposit);
            uint256 maxReward = u.totalDeposit.mul(stageMultiplier).div(10);
            uint256 totalStatic = u.staticRewardReleased.add(staticReward).add(additionalStatic);
            if (totalStatic > maxReward) {
                additionalStatic = maxReward.sub(u.staticRewardReleased).sub(staticReward);
            }
            staticReward = staticReward.add(additionalStatic);

            dynamicReward = dynamicReward.add(calculateDynamicReward(user).mul(daysPassed));
        }
        return staticReward.add(dynamicReward);
    }

    function _updateRewards(address user) internal {
        User storage u = users[user];
        if (u.totalDeposit == 0) return;

        uint256 pendingReward = getPendingReward(user);
        uint256 staticReward = pendingReward.sub(u.pendingDynamicReward);
        uint256 dynamicReward = pendingReward.sub(u.pendingStaticReward);

        u.pendingStaticReward = 0;
        u.pendingDynamicReward = 0;
        u.staticRewardReleased = u.staticRewardReleased.add(staticReward);
        u.dynamicRewardReleased = u.dynamicRewardReleased.add(dynamicReward);
        u.usdtBalance = u.usdtBalance.add(staticReward).add(dynamicReward);
        u.lastUpdateTime = block.timestamp;

        totalStaticRewards = totalStaticRewards.add(staticReward);

        emit RewardsUpdated(user, staticReward, dynamicReward);
    }

    function deposit(uint256 amount) external {
        require(amount >= 100 ether, "Minimum deposit is 100 USDT");
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "USDT transfer failed");

        _updateRewards(msg.sender);
        User storage u = users[msg.sender];
        if (u.totalDeposit == 0) {
            u.lastUpdateTime = block.timestamp;
            if (u.referrer == address(0)) u.rootReferrer = msg.sender;
        }
        u.totalDeposit = u.totalDeposit.add(amount);
        totalDeposited = totalDeposited.add(amount);

        uint256 stageMultiplier = _getStageMultiplier(amount);
        u.usdtBalance = u.usdtBalance.add(amount.mul(stageMultiplier).div(10));

        emit Deposited(msg.sender, amount, totalDeposited);
    }

    function bindReferrer(address referrer) external {
        User storage u = users[msg.sender];
        require(u.referrer == address(0), "Referrer already set");
        require(referrer != msg.sender, "Cannot refer yourself");
        require(referrer != address(0), "Invalid referrer address");

        uint256 chainDepth = getReferralChainDepth(referrer);
        require(chainDepth < 10, "Referral chain too deep");

        _updateRewards(msg.sender);
        u.referrer = referrer;
        u.rootReferrer = _findRootReferrer(referrer);
        _updateReferralStructure(msg.sender, referrer);
        emit ReferrerBound(msg.sender, referrer);
    }

    function _updateReferralStructure(address user, address referrer) internal {
        referrals[referrer][1].push(user);
        users[referrer].referralsCount[1] = users[referrer].referralsCount[1].add(1);
    }

    function getReferralChainDepth(address user) internal view returns (uint256) {
        uint256 depth = 0;
        address current = user;
        while (current != address(0) && depth < 10) {
            current = users[current].referrer;
            depth = depth.add(1);
        }
        return depth;
    }

    function releaseRewards() external {
        _updateRewards(msg.sender);
        User storage u = users[msg.sender];
        require(u.usdtBalance > 0, "No rewards to release");
        uint256 staticReward = u.staticRewardReleased;
        uint256 dynamicReward = u.dynamicRewardReleased;
        u.pendingStaticReward = 0;
        u.pendingDynamicReward = 0;
        emit RewardReleased(msg.sender, staticReward, dynamicReward);
    }

    function withdraw(uint256 amount) external {
        User storage u = users[msg.sender];
        _updateRewards(msg.sender);
        require(!restrictedUsers[msg.sender], "User is restricted");
        require(u.totalDeposit > 0, "No deposit");
        require(block.timestamp >= u.lastWithdrawTime + DAY_IN_SECONDS, "Can only withdraw once every 24 hours");
        require(amount <= u.usdtBalance, "Insufficient usdtBalance");
        require(!withdrawBlacklist[msg.sender], "You have been blacklisted from withdrawing");

        // 获取实时的NEAR/USDT价格（放大1000倍，保留3位小数）
        int nearPrice = getNearPrice();
        require(nearPrice > 0, "Invalid price from oracle");

        // 计算对应的NEAR数量
        // amount 是 USDT数量 (以wei为单位，10^18)
        // nearPrice 是 USDT/NEAR价格 (放大1000倍)
        // 增加额外精度因子 10^18 以保留小数部分
        uint256 PRECISION_FACTOR = 10**18;
        uint256 nearAmount = (amount.mul(PRICE_PRECISION).mul(PRECISION_FACTOR)).div(uint256(nearPrice)).div(PRECISION_FACTOR);

        u.withdrawnAmount = u.withdrawnAmount.add(amount);
        u.usdtBalance = u.usdtBalance.sub(amount);
        u.lastWithdrawTime = block.timestamp;

        // 转移NEAR代币给用户
        require(nearToken.transfer(msg.sender, nearAmount), "NEAR transfer failed");

        emit WithdrawRequested(msg.sender, nearAmount);
        emit WithdrawAttempt(msg.sender, getTodayStaticReward(msg.sender), calculateDynamicReward(msg.sender));
    }

    function setWithdrawBlacklist(address user, bool isBlacklisted) external onlyOwner {
        withdrawBlacklist[user] = isBlacklisted;
        emit WithdrawBlacklistUpdated(user, isBlacklisted);
    }

    function isBlacklisted(address user) external view returns (bool) {
        return withdrawBlacklist[user];
    }

    function getNearBalance() external view returns (uint256) {
        return nearToken.balanceOf(address(this));
    }

    function withdrawNear(uint256 amount) external onlyOwner {
        require(nearToken.transfer(msg.sender, amount), "NEAR transfer failed");
    }

    function _getTotalDailyReward(address user) internal view returns (uint256) {
        return getTodayStaticReward(user).add(calculateDynamicReward(user));
    }

    function hasWithdrawnInLast24Hours(address user) public view returns (bool) {
        return block.timestamp < users[user].lastWithdrawTime + DAY_IN_SECONDS;
    }

    function getLastWithdrawTime(address user) public view returns (uint256) {
        return users[user].lastWithdrawTime;
    }

    function getReleasedReward(address user) public view returns (uint256) {
        return users[user].staticRewardReleased.add(users[user].dynamicRewardReleased);
    }

    function getTodayStaticReward(address user) public view returns (uint256) {
        if (users[user].totalDeposit == 0) return 0;
        return users[user].totalDeposit.mul(_getDailyRate(users[user].totalDeposit)).div(1000);
    }

    function getTodayDynamicReward(address user) public view returns (uint256) {
        return calculateDynamicReward(user);
    }

    function getStakeReward(address user) public view returns (uint256) {
        return users[user].staticRewardReleased;
    }

    function getDirectReward(address user) public view returns (uint256) {
        return _calculateDirectReward(user);
    }

    function getShareReward(address user) public view returns (uint256) {
        return _calculateShareReward(user);
    }

    function getTeamReward(address user) public view returns (uint256) {
        return _calculateTeamReward(user);
    }

    function getGlobalDividend(address user) public view returns (uint256) {
        return _calculateGlobalDividend(user);
    }

    function getTotalReleasable(address user) public view returns (uint256) {
        return getReleasedReward(user).add(getPendingReward(user));
    }

    function getWithdrawn(address user) public view returns (uint256) {
        return users[user].withdrawnAmount;
    }

    function getWithdrawableAmount(address user) public view returns (uint256) {
        return getTotalReleasable(user).sub(users[user].withdrawnAmount);
    }

    function getUsdtBalance(address user) public view returns (uint256) {
        return users[user].usdtBalance;
    }

    function getPendingStaticReward(address user) public view returns (uint256) {
        User storage u = users[user];
        uint256 currentDayStart = block.timestamp - (block.timestamp % DAY_IN_SECONDS);
        uint256 lastUpdateDayStart = u.lastUpdateTime - (u.lastUpdateTime % DAY_IN_SECONDS);
        uint256 staticReward = u.pendingStaticReward;

        if (currentDayStart > lastUpdateDayStart && u.totalDeposit > 0) {
            uint256 daysPassed = (currentDayStart - lastUpdateDayStart) / DAY_IN_SECONDS;
            uint256 dailyStaticReward = getTodayStaticReward(user);
            uint256 additionalStatic = dailyStaticReward.mul(daysPassed);
            uint256 stageMultiplier = _getStageMultiplier(u.totalDeposit);
            uint256 maxReward = u.totalDeposit.mul(stageMultiplier).div(10);
            uint256 totalStatic = u.staticRewardReleased.add(staticReward).add(additionalStatic);
            if (totalStatic > maxReward) {
                additionalStatic = maxReward.sub(u.staticRewardReleased).sub(staticReward);
            }
            staticReward = staticReward.add(additionalStatic);
        }
        return staticReward;
    }

    function _getStageMultiplier(uint256 amount) private pure returns (uint256) {
        if (amount >= 100 ether && amount <= 500 ether) return 15;
        if (amount >= 501 ether && amount <= 1000 ether) return 20;
        if (amount >= 1001 ether && amount <= 3000 ether) return 25;
        if (amount >= 3001 ether) return 30;
        return 0;
    }

    function _getDailyRate(uint256 amount) private pure returns (uint256) {
        if (amount <= 500 ether) return 7;
        if (amount <= 1000 ether) return 8;
        if (amount <= 3000 ether) return 9;
        return 10;
    }

    function calculateDynamicReward(address user) internal view returns (uint256) {
        return _calculateDirectReward(user)
            .add(_calculateShareReward(user))
            .add(_calculateTeamReward(user))
            .add(_calculateGlobalDividend(user));
    }

    function getPendingDynamicReward(address user) public view returns (uint256) {
        User storage u = users[user];
        uint256 currentDayStart = block.timestamp - (block.timestamp % DAY_IN_SECONDS);
        uint256 lastUpdateDayStart = u.lastUpdateTime - (u.lastUpdateTime % DAY_IN_SECONDS);
        uint256 dynamicReward = u.pendingDynamicReward;

        if (currentDayStart > lastUpdateDayStart && u.totalDeposit > 0) {
            uint256 daysPassed = (currentDayStart - lastUpdateDayStart) / DAY_IN_SECONDS;
            dynamicReward = dynamicReward.add(calculateDynamicReward(user).mul(daysPassed));
        }
        return dynamicReward;
    }

    function _calculateDirectReward(address user) internal view returns (uint256) {
        uint256 reward = 0;
        bool noBurn = users[user].totalDeposit >= 3001 ether;
        
        for (uint256 i = 1; i <= 6; i++) {
            address[] memory refs = getReferralsAtLevel(user, i);
            for (uint256 j = 0; j < refs.length; j++) {
                uint256 refDeposit = users[refs[j]].totalDeposit;
                uint256 rate = (i == 1) ? 50 : (i == 2) ? 30 : 10;
                uint256 burnAmount = noBurn ? refDeposit : 
                    (refDeposit > users[user].totalDeposit ? users[user].totalDeposit : refDeposit);
                reward = reward.add(burnAmount.mul(rate).div(1000));
            }
        }
        return reward.div(100);
    }

    function _calculateShareReward(address user) internal view returns (uint256) {
        uint256 reward = 0;
        uint256 maxLevel = users[user].referralsCount[1] > 10 ? 10 : users[user].referralsCount[1];
        bool noBurn = users[user].totalDeposit >= 3001 ether;
        
        for (uint256 i = 1; i <= maxLevel; i++) {
            address[] memory refs = getReferralsAtLevel(user, i);
            for (uint256 j = 0; j < refs.length; j++) {
                uint256 staticReward = getTodayStaticReward(refs[j]);
                uint256 refDeposit = users[refs[j]].totalDeposit;
                uint256 burnAmount = noBurn ? staticReward : 
                    (refDeposit > users[user].totalDeposit ? getTodayStaticReward(user) : staticReward);
                reward = reward.add(burnAmount.mul(5).div(100));
            }
        }
        return reward;
    }

    function getReferralsAtLevel(address user, uint256 level) internal view returns (address[] memory) {
        if (level == 1) return referrals[user][1];
        
        address[] memory directRefs = referrals[user][1];
        address[] memory result = new address[](0);
        for (uint256 i = 0; i < directRefs.length; i++) {
            address[] memory subRefs = getReferralsAtLevel(directRefs[i], level.sub(1));
            result = concatArrays(result, subRefs);
        }
        return result;
    }

    function concatArrays(address[] memory arr1, address[] memory arr2) internal pure returns (address[] memory) {
        address[] memory result = new address[](arr1.length + arr2.length);
        for (uint256 i = 0; i < arr1.length; i++) {
            result[i] = arr1[i];
        }
        for (uint256 i = 0; i < arr2.length; i++) {
            result[arr1.length + i] = arr2[i];
        }
        return result;
    }

    function _calculateTeamReward(address user) internal view returns (uint256) {
        address root = _findRootReferrer(user);
        uint256 teamPerformance = root == address(0) ? 0 : getAllReferralsTotalPerformance(root);
        uint256 rate = _getTeamRate(teamPerformance);
        if (rate == 0) return 0;

        return getTodayStaticReward(user).mul(rate).div(100);
    }

    function _getTeamRate(uint256 teamPerformance) private pure returns (uint256) {
        if (teamPerformance >= 2000000 ether) return 25;
        if (teamPerformance >= 500000 ether) return 20;
        if (teamPerformance >= 100000 ether) return 15;
        if (teamPerformance >= 20000 ether) return 10;
        if (teamPerformance >= 5000 ether) return 5;
        return 0;
    }

    function _calculateGlobalDividend(address user) internal view returns (uint256) {
        address root = _findRootReferrer(user);
        uint256 teamPerformance = root == address(0) ? 0 : getAllReferralsTotalPerformance(root);
        if (teamPerformance >= 5000000 ether) {
            return totalStaticRewards.mul(5).div(100).div(365);
        }
        return 0;
    }

    function getTotalDeposited() external view returns (uint256) {
        return totalDeposited;
    }

    function withdrawUSDT(uint256 amount) external onlyOwner {
        uint256 balance = usdtToken.balanceOf(address(this));
        require(amount <= balance, "Insufficient USDT balance");
        require(usdtToken.transfer(msg.sender, amount), "USDT transfer failed");
        emit USDTWithdrawn(msg.sender, amount);
    }

    function getReferrals(address user, uint256 level) external view returns (address[] memory) {
        return getReferralsAtLevel(user, level);
    }

    function restrictUser(address user, bool restrict) external onlyOwner {
        _updateRewards(user);
        restrictedUsers[user] = restrict;
        emit UserRestricted(user, restrict);
    }

    function getDirectReferralsTotalPerformance(address user) public view returns (uint256) {
        uint256 totalPerformance = 0;
        address[] memory directRefs = referrals[user][1];
        for (uint256 i = 0; i < directRefs.length; i++) {
            totalPerformance = totalPerformance.add(users[directRefs[i]].totalDeposit);
        }
        return totalPerformance;
    }

    function getAllReferralsTotalPerformance(address user) public view returns (uint256) {
        address root = _findRootReferrer(user);
        uint256 totalPerformance = 0;
        address[] memory allRefs = getAllReferrals(root);
        for (uint256 i = 0; i < allRefs.length; i++) {
            totalPerformance = totalPerformance.add(users[allRefs[i]].totalDeposit);
        }
        return totalPerformance;
    }

    function getAllReferrals(address user) internal view returns (address[] memory) {
        address[] memory result = new address[](0);
        for (uint256 i = 1; i <= 10; i++) {
            address[] memory refs = getReferralsAtLevel(user, i);
            result = concatArrays(result, refs);
            if (refs.length == 0) break;
        }
        return result;
    }

    function getDirectReferralsWithDepositCount(address user) public view returns (uint256) {
        uint256 count = 0;
        address[] memory directRefs = referrals[user][1];
        for (uint256 i = 0; i < directRefs.length; i++) {
            if (users[directRefs[i]].totalDeposit > 0) {
                count = count.add(1);
            }
        }
        return count;
    }

    function getPerformanceByLevel(address user) public view returns (uint256[10] memory) {
        uint256[10] memory performanceByLevel;
        for (uint256 level = 1; level <= 10; level++) {
            uint256 totalPerformance = 0;
            address[] memory refs = getReferralsAtLevel(user, level);
            for (uint256 i = 0; i < refs.length; i++) {
                totalPerformance = totalPerformance.add(users[refs[i]].totalDeposit);
            }
            performanceByLevel[level - 1] = totalPerformance;
        }
        return performanceByLevel;
    }

    function batchUpdateRewards(address[] calldata userAddresses) external onlyOwner {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            _updateRewards(userAddresses[i]);
        }
    }
}
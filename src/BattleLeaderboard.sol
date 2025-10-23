// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BattleLeaderboard
 * @dev Manages battle predictions, results, and player statistics
 * @notice This contract tracks player performance in Pong battles with a point system
 */
contract BattleLeaderboard {
    // ========================================================================
    // Constants
    // ========================================================================
    uint256 public constant POINTS_PER_CORRECT_PREDICTION = 10;
    uint256 public constant BONUS_POINTS_HIGH_DELTA = 5;
    uint256 public constant DELTA_THRESHOLD = 500; // 5% in basis points

    // ========================================================================
    // State Variables
    // ========================================================================
    address public owner;
    bool private locked; // Reentrancy guard

    // Player stats structure
    struct PlayerStats {
        uint256 totalPredictions;
        uint256 correctPredictions;
        uint256 wrongPredictions;
        uint256 points;
        uint256 highestDelta;
        uint256 lastBattleTime;
    }

    // Battle history structure
    struct BattleRecord {
        address player;
        string coinA;
        string coinB;
        string predictedWinner;
        string actualWinner;
        bool wasCorrect;
        uint256 delta;
        uint256 scoreA;
        uint256 scoreB;
        uint256 timestamp;
    }

    // Data mappings
    mapping(address => PlayerStats) public playerStats;
    mapping(uint256 => BattleRecord) public battleHistory;
    mapping(address => uint256[]) public playerBattleIds; // Track battles per player

    uint256 public battleCount = 0;

    // ========================================================================
    // Events
    // ========================================================================
    event BattleSubmitted(
        uint256 indexed battleId,
        address indexed player,
        bool wasCorrect,
        uint256 pointsEarned,
        uint256 timestamp
    );

    event LeaderboardUpdated(
        address indexed player,
        uint256 totalPoints,
        uint256 accuracy
    );

    // ========================================================================
    // Modifiers
    // ========================================================================
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    // ========================================================================
    // Constructor
    // ========================================================================
    constructor() {
        owner = msg.sender;
        locked = false;
    }

    // ========================================================================
    // Core Functions
    // ========================================================================

    /**
     * @dev Submit a battle result and update player statistics
     * @param coinA First cryptocurrency symbol
     * @param coinB Second cryptocurrency symbol
     * @param predictedWinner User's prediction
     * @param actualWinner Actual battle result
     * @param performanceDelta Performance delta in basis points
     * @param scoreA Score of coin A
     * @param scoreB Score of coin B
     * @return battleId The ID of the recorded battle
     * @return wasCorrect Whether the prediction was correct
     * @return totalPointsEarned Points earned from this battle
     */
    function submitBattle(
        string memory coinA,
        string memory coinB,
        string memory predictedWinner,
        string memory actualWinner,
        uint256 performanceDelta,
        uint256 scoreA,
        uint256 scoreB
    ) public nonReentrant returns (uint256, bool, uint256) {
        require(bytes(coinA).length > 0, "coinA cannot be empty");
        require(bytes(coinB).length > 0, "coinB cannot be empty");
        require(bytes(predictedWinner).length > 0, "predictedWinner cannot be empty");
        require(bytes(actualWinner).length > 0, "actualWinner cannot be empty");

        bool wasCorrect = compareStrings(predictedWinner, actualWinner);
        uint256 totalPointsEarned = _calculatePoints(wasCorrect, performanceDelta);
        uint256 newBattleId = battleCount++;
        address player = msg.sender;
        
        _updatePlayerStats(player, wasCorrect, totalPointsEarned, performanceDelta);
        playerBattleIds[player].push(newBattleId);

        battleHistory[newBattleId] = BattleRecord(
            player,
            coinA,
            coinB,
            predictedWinner,
            actualWinner,
            wasCorrect,
            performanceDelta,
            scoreA,
            scoreB,
            block.timestamp
        );

        emit BattleSubmitted(newBattleId, player, wasCorrect, totalPointsEarned, block.timestamp);
        emit LeaderboardUpdated(player, playerStats[player].points, getAccuracy(player));

        return (newBattleId, wasCorrect, totalPointsEarned);
    }

    /**
     * @dev Calculate points earned from a battle
     * @param wasCorrect Whether prediction was correct
     * @param performanceDelta Performance delta in basis points
     * @return uint256 Total points earned
     */
    function _calculatePoints(bool wasCorrect, uint256 performanceDelta) private pure returns (uint256) {
        if (!wasCorrect) return 0;
        
        uint256 points = POINTS_PER_CORRECT_PREDICTION;
        if (performanceDelta > DELTA_THRESHOLD) {
            points += BONUS_POINTS_HIGH_DELTA;
        }
        return points;
    }

    /**
     * @dev Update player statistics
     * @param player Player address
     * @param wasCorrect Whether prediction was correct
     * @param pointsEarned Points earned
     * @param performanceDelta Performance delta
     */
    function _updatePlayerStats(
        address player,
        bool wasCorrect,
        uint256 pointsEarned,
        uint256 performanceDelta
    ) private {
        PlayerStats storage stats = playerStats[player];
        
        stats.totalPredictions++;
        if (wasCorrect) {
            stats.correctPredictions++;
            if (performanceDelta > stats.highestDelta) {
                stats.highestDelta = performanceDelta;
            }
        } else {
            stats.wrongPredictions++;
        }
        stats.points += pointsEarned;
        stats.lastBattleTime = block.timestamp;
    }

    // ========================================================================
    // Read-Only Functions
    // ========================================================================

    /**
     * @dev Get complete statistics for a player
     * @param user The player's address
     * @return PlayerStats struct containing all stats
     */
    function getUserStats(address user) public view returns (PlayerStats memory) {
        return playerStats[user];
    }

    /**
     * @dev Get total number of battles recorded
     * @return uint256 Total battle count
     */
    function getBattleCount() public view returns (uint256) {
        return battleCount;
    }

    /**
     * @dev Get battle record by ID
     * @param battleId The ID of the battle
     * @return BattleRecord struct for the specified battle
     */
    function getBattleById(uint256 battleId) public view returns (BattleRecord memory) {
        require(battleId < battleCount, "Battle ID does not exist");
        return battleHistory[battleId];
    }

    /**
     * @dev Get accuracy percentage for a player
     * @param player The player's address
     * @return uint256 Accuracy as percentage (0-100)
     */
    function getAccuracy(address player) public view returns (uint256) {
        PlayerStats memory stats = playerStats[player];
        if (stats.totalPredictions == 0) {
            return 0;
        }
        return (stats.correctPredictions * 100) / stats.totalPredictions;
    }

    /**
     * @dev Get all battle IDs for a player
     * @param player The player's address
     * @return uint256[] Array of battle IDs
     */
    function getPlayerBattleIds(address player) public view returns (uint256[] memory) {
        return playerBattleIds[player];
    }

    /**
     * @dev Get number of battles for a player
     * @param player The player's address
     * @return uint256 Number of battles
     */
    function getPlayerBattleCount(address player) public view returns (uint256) {
        return playerBattleIds[player].length;
    }

    /**
     * @dev Compare if a player's prediction was correct
     * @param battleId The battle ID to check
     * @param player The player to verify
     * @return bool Whether the prediction was correct
     */
    function wasPredictionCorrect(uint256 battleId, address player) 
        public 
        view 
        returns (bool) 
    {
        require(battleId < battleCount, "Battle ID does not exist");
        BattleRecord memory battle = battleHistory[battleId];
        require(battle.player == player, "Player did not participate in this battle");
        return battle.wasCorrect;
    }

    // ========================================================================
    // Helper Functions
    // ========================================================================

    /**
     * @dev Compare two strings for equality
     * @param a First string
     * @param b Second string
     * @return bool True if strings are equal
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
     * @dev Emergency function to withdraw funds (if any)
     */
    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
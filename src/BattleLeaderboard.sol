// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============================================================================
// IERC721 Interface (for NFT implementation)
// ============================================================================
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint(address to, uint256 tokenId) external;
}

// ============================================================================
// BattleLeaderboard Contract
// Manages battle predictions, results, and player statistics (NO STAKING)
// ============================================================================
contract BattleLeaderboard {
    // Constants
    uint256 private constant POINTS_PER_CORRECT_PREDICTION = 10;
    uint256 private constant BONUS_POINTS_HIGH_DELTA = 5;
    
    address public owner;

    // Player stats structure
    struct PlayerStats {
        uint256 totalPredictions;
        uint256 correctPredictions;
        uint256 wrongPredictions;
        uint256 points;
        uint256 highestDelta;
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
    uint256 public battleCount = 0;

    // Events
    event BattleSubmitted(
        uint256 indexed battleId,
        address indexed player,
        bool wasCorrect,
        uint256 pointsEarned
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    // Submit a battle result and update player statistics
    function submitBattle(
        string memory coinA,
        string memory coinB,
        string memory predictedWinner,
        string memory actualWinner,
        uint256 performanceDelta,
        uint256 scoreA,
        uint256 scoreB
    ) public returns (uint256, bool, uint256) {
        address player = msg.sender;
        uint256 newBattleId = battleCount;
        battleCount++;

        // Check if prediction was correct
        bool wasCorrect = compareStrings(predictedWinner, actualWinner);
        
        // Check if delta is over 500 basis points (5%)
        bool deltaOver500 = performanceDelta > 500;

        // Calculate points
        uint256 basePoints = wasCorrect ? POINTS_PER_CORRECT_PREDICTION : 0;
        uint256 bonusPoints = (wasCorrect && deltaOver500) ? BONUS_POINTS_HIGH_DELTA : 0;
        uint256 totalPointsEarned = basePoints + bonusPoints;

        // Get current stats or initialize if doesn't exist
        PlayerStats storage stats = playerStats[player];

        // Update player stats
        stats.totalPredictions++;
        if (wasCorrect) {
            stats.correctPredictions++;
        } else {
            stats.wrongPredictions++;
        }
        stats.points += totalPointsEarned;

        if (wasCorrect && performanceDelta > stats.highestDelta) {
            stats.highestDelta = performanceDelta;
        }

        // Record battle history
        battleHistory[newBattleId] = BattleRecord({
            player: player,
            coinA: coinA,
            coinB: coinB,
            predictedWinner: predictedWinner,
            actualWinner: actualWinner,
            wasCorrect: wasCorrect,
            delta: performanceDelta,
            scoreA: scoreA,
            scoreB: scoreB,
            timestamp: block.timestamp
        });

        emit BattleSubmitted(newBattleId, player, wasCorrect, totalPointsEarned);

        return (newBattleId, wasCorrect, totalPointsEarned);
    }

    // Get user statistics
    function getUserStats(address user) public view returns (PlayerStats memory) {
        return playerStats[user];
    }

    // Get battle count
    function getBattleCount() public view returns (uint256) {
        return battleCount;
    }

    // Get battle by ID
    function getBattleById(uint256 battleId) public view returns (BattleRecord memory) {
        return battleHistory[battleId];
    }

    // Get accuracy percentage (correct / total * 100)
    function getAccuracy(address player) public view returns (uint256) {
        PlayerStats memory stats = playerStats[player];
        if (stats.totalPredictions == 0) {
            return 0;
        }
        return (stats.correctPredictions * 100) / stats.totalPredictions;
    }

    // Helper function to compare strings
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
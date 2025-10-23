// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BattlePrediction
 * @dev Manages user predictions before battles start
 * @notice Players submit predictions which are settled after battles end
 */
contract BattlePrediction {
    // ========================================================================
    // State Variables
    // ========================================================================
    address public owner;

    // Prediction structure
    struct Prediction {
        address player;
        string coinA;
        string coinB;
        string predictedWinner;
        bool isSettled;
        uint256 timestamp;
    }

    // Data mappings
    mapping(uint256 => Prediction) public predictions;
    mapping(address => uint256[]) public playerPredictions; // Track predictions per player
    uint256 public nextPredictionId = 1;

    // ========================================================================
    // Events
    // ========================================================================
    event PredictionSubmitted(
        uint256 indexed predictionId,
        address indexed player,
        string predictedWinner,
        uint256 timestamp
    );

    event PredictionSettled(uint256 indexed predictionId, uint256 timestamp);

    // ========================================================================
    // Modifiers
    // ========================================================================
    modifier predictionExists(uint256 predictionId) {
        require(predictions[predictionId].player != address(0), "Prediction not found");
        _;
    }

    // ========================================================================
    // Constructor
    // ========================================================================
    constructor() {
        owner = msg.sender;
    }

    // ========================================================================
    // Core Functions
    // ========================================================================

    /**
     * @dev Submit a prediction before a battle starts
     * @param coinA First cryptocurrency symbol
     * @param coinB Second cryptocurrency symbol
     * @param predictedWinner Which coin the player predicts will win
     * @return uint256 The prediction ID
     */
    function submitPrediction(
        string memory coinA,
        string memory coinB,
        string memory predictedWinner
    ) public returns (uint256) {
        require(bytes(coinA).length > 0, "coinA cannot be empty");
        require(bytes(coinB).length > 0, "coinB cannot be empty");
        require(bytes(predictedWinner).length > 0, "predictedWinner cannot be empty");

        // Validate prediction is either coinA or coinB
        require(
            compareStrings(predictedWinner, coinA) || compareStrings(predictedWinner, coinB),
            "Prediction must be either coinA or coinB"
        );

        uint256 predictionId = nextPredictionId;
        nextPredictionId++;

        predictions[predictionId] = Prediction({
            player: msg.sender,
            coinA: coinA,
            coinB: coinB,
            predictedWinner: predictedWinner,
            isSettled: false,
            timestamp: block.timestamp
        });

        playerPredictions[msg.sender].push(predictionId);

        emit PredictionSubmitted(predictionId, msg.sender, predictedWinner, block.timestamp);

        return predictionId;
    }

    /**
     * @dev Settle a prediction after the battle ends
     * @param predictionId The prediction ID to settle
     * @return bool True on success
     */
    function settlePrediction(uint256 predictionId) 
        public 
        predictionExists(predictionId) 
        returns (bool) 
    {
        Prediction storage prediction = predictions[predictionId];
        require(msg.sender == prediction.player, "Only the player can settle their prediction");
        require(!prediction.isSettled, "Prediction already settled");

        prediction.isSettled = true;

        emit PredictionSettled(predictionId, block.timestamp);

        return true;
    }

    // ========================================================================
    // Read-Only Functions
    // ========================================================================

    /**
     * @dev Get a prediction by ID
     * @param predictionId The prediction ID
     * @return Prediction struct
     */
    function getPrediction(uint256 predictionId) 
        public 
        view 
        predictionExists(predictionId) 
        returns (Prediction memory) 
    {
        return predictions[predictionId];
    }

    /**
     * @dev Get the next prediction ID that will be assigned
     * @return uint256 Next prediction ID
     */
    function getNextPredictionId() public view returns (uint256) {
        return nextPredictionId;
    }

    /**
     * @dev Get all prediction IDs for a player
     * @param player The player's address
     * @return uint256[] Array of prediction IDs
     */
    function getPlayerPredictions(address player) public view returns (uint256[] memory) {
        return playerPredictions[player];
    }

    /**
     * @dev Get number of predictions made by a player
     * @param player The player's address
     * @return uint256 Number of predictions
     */
    function getPlayerPredictionCount(address player) public view returns (uint256) {
        return playerPredictions[player].length;
    }

    /**
     * @dev Check if a player has any active (unsettled) predictions
     * @param player The player's address
     * @return bool True if player has active predictions
     */
    function hasActivePredictions(address player) public view returns (bool) {
        uint256[] memory predIds = playerPredictions[player];
        for (uint256 i = 0; i < predIds.length; i++) {
            if (!predictions[predIds[i]].isSettled) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get count of active predictions for a player
     * @param player The player's address
     * @return uint256 Number of active predictions
     */
    function getActivePredictionCount(address player) public view returns (uint256) {
        uint256 count = 0;
        uint256[] memory predIds = playerPredictions[player];
        for (uint256 i = 0; i < predIds.length; i++) {
            if (!predictions[predIds[i]].isSettled) {
                count++;
            }
        }
        return count;
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
    function compareStrings(string memory a, string memory b) 
        internal 
        pure 
        returns (bool) 
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
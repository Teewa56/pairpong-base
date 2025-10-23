// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BattlePrediction {
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
    uint256 public nextPredictionId = 1;

    // Events
    event PredictionSubmitted(uint256 indexed predictionId, address indexed player);
    event PredictionSettled(uint256 indexed predictionId);

    constructor() {
        owner = msg.sender;
    }

    // Submit prediction before battle starts
    function submitPrediction(
        string memory coinA,
        string memory coinB,
        string memory predictedWinner
    ) public returns (uint256) {
        // Validate prediction is either coin-a or coin-b
        require(
            compareStrings(predictedWinner, coinA) || compareStrings(predictedWinner, coinB),
            "Invalid prediction"
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

        emit PredictionSubmitted(predictionId, msg.sender);

        return predictionId;
    }

    // Settle prediction after battle ends
    function settlePrediction(uint256 predictionId) public returns (bool) {
        Prediction storage prediction = predictions[predictionId];
        require(prediction.player != address(0), "Prediction not found");
        require(msg.sender == prediction.player, "Not authorized");
        require(!prediction.isSettled, "Already settled");

        prediction.isSettled = true;

        emit PredictionSettled(predictionId);

        return true;
    }

    // Get prediction by ID
    function getPrediction(uint256 predictionId) public view returns (Prediction memory) {
        require(predictions[predictionId].player != address(0), "Prediction not found");
        return predictions[predictionId];
    }

    // Get next prediction ID
    function getNextPredictionId() public view returns (uint256) {
        return nextPredictionId;
    }

    // Check if player has active prediction (simplified)
    function hasActivePrediction(address player) public pure returns (bool) {
        // Simplified implementation - in production you'd track this per player
        return false;
    }

    // Helper function to compare strings
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
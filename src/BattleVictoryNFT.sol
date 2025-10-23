// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BattleVictoryNFT {
    address public owner;
    
    string public name = "Battle Victory NFT";
    string public symbol = "BVNFT";

    uint256 private nextTokenId = 1;

    // Token to owner mapping
    mapping(uint256 => address) private tokenOwners;
    
    // Token to URI mapping
    mapping(uint256 => string) private tokenURIs;
    
    // Owner to balance mapping
    mapping(address => uint256) private balances;
    
    // Token approval mapping
    mapping(uint256 => address) private tokenApprovals;
    
    // Operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Get last token ID
    function getLastTokenId() public view returns (uint256) {
        return nextTokenId - 1;
    }

    // Get token URI
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenOwners[tokenId] != address(0), "Token does not exist");
        return tokenURIs[tokenId];
    }

    // Get owner of token
    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = tokenOwners[tokenId];
        require(tokenOwner != address(0), "Token does not exist");
        return tokenOwner;
    }

    // Get balance of owner
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "Invalid address");
        return balances[account];
    }

    // Transfer token
    function transfer(
        uint256 tokenId,
        address sender,
        address recipient
    ) public returns (bool) {
        require(msg.sender == sender, "Not authorized");
        require(tokenOwners[tokenId] == sender, "Not the owner");
        require(recipient != address(0), "Invalid recipient");

        // Clear approvals
        tokenApprovals[tokenId] = address(0);

        // Update balances
        balances[sender]--;
        balances[recipient]++;

        // Update owner
        tokenOwners[tokenId] = recipient;

        emit Transfer(sender, recipient, tokenId);
        return true;
    }

    // Mint new NFT
    function mintBattleNFT(
        address recipient,
        string memory metadataUri
    ) public onlyOwner returns (uint256) {
        require(recipient != address(0), "Invalid recipient");

        uint256 currentId = nextTokenId;
        nextTokenId++;

        tokenOwners[currentId] = recipient;
        balances[recipient]++;
        tokenURIs[currentId] = metadataUri;

        emit Transfer(address(0), recipient, currentId);

        return currentId;
    }

    // Approve token transfer
    function approve(address to, uint256 tokenId) public {
        address player = tokenOwners[tokenId];
        require(msg.sender == player || operatorApprovals[player][msg.sender], "Not authorized");
        tokenApprovals[tokenId] = to;
        emit Approval(player, to, tokenId);
    }

    // Set operator approval for all tokens
    function setApprovalForAll(address operator, bool approved) public {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Get approved address for token
    function getApproved(uint256 tokenId) public view returns (address) {
        require(tokenOwners[tokenId] != address(0), "Token does not exist");
        return tokenApprovals[tokenId];
    }

    // Check if operator is approved for all
    function isApprovedForAll(address player, address operator) public view returns (bool) {
        return operatorApprovals[player][operator];
    }

    // Transfer from (standard ERC721)
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(tokenOwners[tokenId] == from, "Not the owner");
        require(
            msg.sender == from || msg.sender == tokenApprovals[tokenId] || operatorApprovals[from][msg.sender],
            "Not authorized"
        );

        tokenApprovals[tokenId] = address(0);
        balances[from]--;
        balances[to]++;
        tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
}
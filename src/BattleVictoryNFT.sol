// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BattleVictoryNFT
 * @dev ERC721-compliant NFT contract for battle victories
 * @notice Mint and transfer Battle Victory NFTs
 */
contract BattleVictoryNFT {
    // ========================================================================
    // State Variables
    // ========================================================================
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

    // ========================================================================
    // Events
    // ========================================================================
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event MetadataUpdate(uint256 indexed tokenId, string newUri);

    // ========================================================================
    // Modifiers
    // ========================================================================
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(tokenOwners[tokenId] != address(0), "Token does not exist");
        _;
    }

    // ========================================================================
    // Constructor
    // ========================================================================
    constructor() {
        owner = msg.sender;
    }

    // ========================================================================
    // ERC721 Implementation
    // ========================================================================

    /**
     * @dev Get total supply of NFTs minted
     * @return uint256 Total tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }

    /**
     * @dev Get the last token ID that was minted
     * @return uint256 Last token ID
     */
    function getLastTokenId() public view returns (uint256) {
        return nextTokenId - 1;
    }

    /**
     * @dev Get token URI metadata
     * @param tokenId The token ID
     * @return string The metadata URI
     */
    function getTokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return tokenURIs[tokenId];
    }

    /**
     * @dev Get owner of a token
     * @param tokenId The token ID
     * @return address The owner's address
     */
    function ownerOf(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return tokenOwners[tokenId];
    }

    /**
     * @dev Get balance of an address
     * @param account The address to check
     * @return uint256 Number of tokens owned
     */
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "Invalid address");
        return balances[account];
    }

    /**
     * @dev Transfer a token between addresses
     * @param tokenId The token ID
     * @param sender The sender's address (must be msg.sender)
     * @param recipient The recipient's address
     * @return bool True on success
     */
    function transfer(
        uint256 tokenId,
        address sender,
        address recipient
    ) public tokenExists(tokenId) returns (bool) {
        require(msg.sender == sender, "Not authorized to transfer");
        require(tokenOwners[tokenId] == sender, "Sender is not the owner");
        require(recipient != address(0), "Invalid recipient address");

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

    /**
     * @dev Mint a new battle victory NFT
     * @param recipient The address to receive the NFT
     * @param metadataUri The metadata URI for the NFT
     * @return uint256 The minted token ID
     */
    function mintBattleNFT(
        address recipient,
        string memory metadataUri
    ) public onlyOwner returns (uint256) {
        require(recipient != address(0), "Invalid recipient address");
        require(bytes(metadataUri).length > 0, "Metadata URI cannot be empty");

        uint256 currentId = nextTokenId;
        nextTokenId++;

        tokenOwners[currentId] = recipient;
        balances[recipient]++;
        tokenURIs[currentId] = metadataUri;

        emit Transfer(address(0), recipient, currentId);
        return currentId;
    }

    /**
     * @dev Batch mint multiple NFTs
     * @param recipients Array of recipient addresses
     * @param metadataUris Array of metadata URIs
     * @return uint256[] Array of minted token IDs
     */
    function mintBatch(
        address[] memory recipients,
        string[] memory metadataUris
    ) public onlyOwner returns (uint256[] memory) {
        require(recipients.length == metadataUris.length, "Arrays must have same length");
        require(recipients.length > 0, "Must mint at least one token");
        require(recipients.length <= 100, "Batch size too large");

        uint256[] memory tokenIds = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            tokenIds[i] = mintBattleNFT(recipients[i], metadataUris[i]);
        }

        return tokenIds;
    }

    /**
     * @dev Approve a token for transfer
     * @param to Address to approve
     * @param tokenId Token ID to approve
     */
    function approve(address to, uint256 tokenId) public tokenExists(tokenId) {
        address tokenOwner = tokenOwners[tokenId];
        require(
            msg.sender == tokenOwner || operatorApprovals[tokenOwner][msg.sender],
            "Not authorized to approve"
        );
        require(to != tokenOwner, "Cannot approve owner");

        tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /**
     * @dev Set operator approval for all tokens
     * @param operator Address of operator
     * @param approved Whether to approve or revoke
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Cannot approve yourself");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Get approved address for token
     * @param tokenId Token ID
     * @return address The approved address
     */
    function getApproved(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return tokenApprovals[tokenId];
    }

    /**
     * @dev Check if operator is approved for all tokens
     * @param tokenOwner Owner's address
     * @param operator Operator's address
     * @return bool True if approved for all
     */
    function isApprovedForAll(address tokenOwner, address operator) 
        public 
        view 
        returns (bool) 
    {
        return operatorApprovals[tokenOwner][operator];
    }

    /**
     * @dev Transfer from one address to another (ERC721 standard)
     * @param from Source address
     * @param to Destination address
     * @param tokenId Token ID to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        tokenExists(tokenId) 
    {
        require(tokenOwners[tokenId] == from, "From address is not the owner");
        require(to != address(0), "Invalid recipient address");
        require(
            msg.sender == from || 
            msg.sender == tokenApprovals[tokenId] || 
            operatorApprovals[from][msg.sender],
            "Not authorized to transfer"
        );

        tokenApprovals[tokenId] = address(0);
        balances[from]--;
        balances[to]++;
        tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Safe transfer from (checks recipient is valid contract or EOA)
     * @param from Source address
     * @param to Destination address
     * @param tokenId Token ID to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
    }

    /**
     * @dev Update metadata URI for a token
     * @param tokenId Token ID
     * @param newUri New metadata URI
     */
    function updateTokenURI(uint256 tokenId, string memory newUri) 
        public 
        onlyOwner 
        tokenExists(tokenId) 
    {
        require(bytes(newUri).length > 0, "URI cannot be empty");
        tokenURIs[tokenId] = newUri;
        emit MetadataUpdate(tokenId, newUri);
    }
}
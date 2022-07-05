// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Erc1155.sol";
// import "../ERC20/ERC20.sol";

import "./ERC1155Receiver.sol";

// import ".././access/Ownable.sol";
//import "../ContractManager.sol";

import "../ContractManagerInterface.sol";
import "../helpers/BaseContract.sol";
import "../storage/UserStorageInterface.sol";
import "../ERC20/GETSInterface.sol";

contract Badge is ERC1155, BaseContract {
    //using Strings for uint256;
    //  using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    //used as the fees charged while reactivating the slot
    //i.e; for 1 eth = 100 gets token
    uint256 private tokenPrice = 1000;

    //used as counter for token-ids on a increment level
    uint256 private tokenCounter;

    //used as a tokenUri for all token types by relying on id substitution
    string public _UriPrefix;

    //  2.Presence of Unused Variables------
    //  string public tokenUri;

    string public _contractURI;

    //1.Usage of Long, Lengthy Number Notations------
    uint256 private badgeFee = 9 ether;

    // Mapping from token ID to prizes assigned
    mapping(uint256 => uint256) private _badgePrize;
    // Mapping from token ID to time assigned
    mapping(uint256 => uint256) private badgeExpiry;
    // Mapping from  token ID to time assign for claim prize
    mapping(uint256 => uint256) private coolingTime;
    // Mapping from NFT to status of transfer
    mapping(uint256 => uint32) private isBadgeAssigned;
    // Mapping from token ID to userAddress
    mapping(uint256 => address[]) private mapBadgeUser;
    // Mapping from token ID to IPFS address
    mapping(uint256 => string) private mapTokenUri; //for ipfs
    // Mapping from address to ids
    mapping(address => EnumerableSet.UintSet) private mapUserBadge;
    mapping(address => uint256) public tokenClaimedTime;
    mapping(address => mapping(uint256 => uint32)) public isBadgeClaimed;
    mapping(uint256 => uint256) private copiesLeft;

    // Event for the create badge passing through stages
    // such as
    event badgeCreated(
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 price
    );
    event appliedForBadge(address indexed user, uint256 indexed badgeId);
    event transferBadges(
        address indexed creator,
        address indexed to,
        uint256 tokenId
    );
    event claimBadge(address indexed to, uint256 tokenId);

    /**
     * @dev check only sponsor can invoke the methods
     */
    modifier onlySponsor() {
        ContractManagerInterface manager = ContractManagerInterface(
            managerAddress
        );
        address userStorageAddress = manager.getAddress("userStorage");
        UserStorageInterface UserStorage = UserStorageInterface(
            userStorageAddress
        );
        require(
            keccak256(abi.encodePacked(UserStorage.getUserType(msg.sender))) ==
                keccak256(abi.encodePacked("sponsor")),
            "Badge Error: Only Sponsor can invoke this method"
        );
        _;
    }

    /**
     * @dev check only student can invoke the methods
     */
    modifier onlyStudent() {
        ContractManagerInterface manager = ContractManagerInterface(
            managerAddress
        );
        address userStorageAddress = manager.getAddress("userStorage");
        UserStorageInterface UserStorage = UserStorageInterface(
            userStorageAddress
        );
        require(
            keccak256(abi.encodePacked(UserStorage.getUserType(msg.sender))) ==
                keccak256(abi.encodePacked("student")),
            "Badge Error: Only student can invoke this method"
        );
        _;
    }

    /**
     * @dev initialize the prefix and the URI and invoked by admin
     */
    //  constructor(string memory UriPrefix_, string memory contractURI_)
    //     ERC1155(tokenUri )
    constructor(string memory UriPrefix_, string memory contractURI_)
        ERC1155(" ")
    {
        _UriPrefix = UriPrefix_;
        _contractURI = contractURI_;
    }

    /**
     * @dev gives the contract uri for the opensea testnet
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_UriPrefix, _contractURI));
    }

    /**
     *@dev
     */
    // for getting id NFT metadata
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_UriPrefix, mapTokenUri[id]));
    }

    function getTokenPrice() external view returns (uint256) {
        return tokenPrice;
    }

    function setTokenPrice(uint256 _totalTokensPerEther) public onlyOwner {
        tokenPrice = _totalTokensPerEther;
    }

  
    function setTokenUri(uint256 tokenId, string memory IPFS)
        internal
        returns (bool)
    {
        mapTokenUri[tokenId] = IPFS;
        return true;
    }

 
    function getTokenCounter() external view returns (uint256) {
        return tokenCounter;
    }

    function getBadgePrice(uint256 ids) external view returns (uint256) {
        return _badgePrize[ids];
    }

    function getBadgeExpiry(uint256 ids) external view returns (uint256) {
        return badgeExpiry[ids];
    }

    function getCoolingTime(uint256 badgeIds) external view returns (uint256) {
        return coolingTime[badgeIds];
    }

    function isBadgeAssign(uint256 ids) external view returns (uint256) {
        return isBadgeAssigned[ids];
    }

    function getApplicationByBadgeId(uint256 ids)
        external
        view
        returns (address[] memory)
    {
        return mapBadgeUser[ids];
    }

    function getCopiesLeft(uint256 ids) external view returns (uint256) {
        return copiesLeft[ids];
    }

    // 6.Unrestricted Access To Essential Functions
    function setBadgeFee(uint256 _badgeFee) public onlyOwner {
        badgeFee = _badgeFee;
    }

    function getBadgeFee() external view returns (uint256) {
        return badgeFee;
    }

    function createBadge(
        uint256 numberOfCopies,
        uint256 _matureTime,
        uint256 _claimedTime,
        uint256 _priceAmount,
        string memory URIs,
        bool flagFee
    ) external onlySponsor {
        ContractManagerInterface manager = ContractManagerInterface(
            managerAddress
        );
        address getsAddress = manager.getAddress("gets");
        GETSInterface gets = GETSInterface(getsAddress);
        if (flagFee == true) {
            uint256 priceCharge = _priceAmount + badgeFee;
            require(
                gets.balanceOf(msg.sender) >= priceCharge,
                "Badge ERROR : Not enough token to pay fees"
            );
        }
        // require(
        //     gets.balanceOf(msg.sender) >= _priceAmount,
        //     "Badge ERROR : Not enough token to set badge prize"
        // );
        require(
            _matureTime > block.timestamp && _claimedTime > block.timestamp,
            "Not Appropriate Time"
        );

        // if(flagFee = true){ gets.transferPrice(msg.sender, owner(), badgeFee);}else(flagFee = false);
        isBadgeClaimed[msg.sender][numberOfCopies] = 0;
        uint256 mintedTokens = numberOfCopies;
        // uint256 ids = numberOfCopies;
        uint256 ids = tokenCounter;
        _badgePrize[ids] = _priceAmount;
        _priceAmount = _badgePrize[ids] * numberOfCopies;
        badgeExpiry[ids] = _matureTime;
        unchecked {
            tokenCounter += 1;
        }
        isBadgeAssigned[ids] = 0;
        copiesLeft[ids] = numberOfCopies;

        coolingTime[ids] = _claimedTime - _matureTime;
        mapTokenUri[ids] = URIs;
        if (flagFee == true) {
            gets.transferPrice(msg.sender, owner(), badgeFee);
        }
        gets.transferPrice(msg.sender, address(this), _priceAmount);
        _mint(msg.sender, ids, mintedTokens, "");
        emit badgeCreated(address(0), msg.sender, ids, _badgePrize[ids]);
    }

    function tokenIdToURI(uint256 ids) external view returns (string memory) {
        return mapTokenUri[ids];
    }

    function applyBadge(uint256 badgeIds) external onlyStudent {
        mapBadgeUser[badgeIds].push(msg.sender);
        mapUserBadge[msg.sender].enumAdd(badgeIds);
        require(
            block.timestamp <= badgeExpiry[badgeIds],
            "Error: badge expired"
        );
        emit appliedForBadge(msg.sender, badgeIds);
    }

    function transferBadge(address to, uint256[] memory badgeIds)
        external
        onlySponsor
    {
        ContractManagerInterface manager = ContractManagerInterface(
            managerAddress
        );
        address userStorageAddress = manager.getAddress("userStorage");
        UserStorageInterface UserStorage = UserStorageInterface(
            userStorageAddress
        );
        require(
            keccak256(abi.encodePacked(UserStorage.getUserType(to))) ==
                keccak256(abi.encodePacked("student")),
            "ERROR: Receipent address must be a student"
        );

        uint256[] memory amounts = new uint256[](badgeIds.length);
        for (uint256 i = 0; i < badgeIds.length; i++) {
            require(
                mapUserBadge[to].contains(badgeIds[i]),
                "ERROR: Must apply for badge"
            );
            require(
                block.timestamp <= badgeExpiry[badgeIds[i]],
                //|| isBadgeAssigned[badgeIds[i]] == 1,
                "Error: badge expired"
            );
            require(
                balanceOf(to, badgeIds[i]) == 0,
                "This badge already assigned"
            );
            require(copiesLeft[badgeIds[i]] > 0, "No copy is left to assign");
            copiesLeft[badgeIds[i]] -= 1;
            amounts[i] = 1;

            tokenClaimedTime[to] = coolingTime[badgeIds[i]] + block.timestamp;
            isBadgeAssigned[badgeIds[i]] = 1;
        }

        _safeBatchTransferFrom(msg.sender, to, badgeIds, amounts, " ");
        emit transferBadges(msg.sender, to, badgeIds.length);
    }

    function resetBadgeExpiry(uint256 _reMaturedTime, uint256 badgeId)
        external
        payable
        onlySponsor
    {
        ContractManagerInterface manager = ContractManagerInterface(
            managerAddress
        );
        address getsAddress = manager.getAddress("gets");
        GETSInterface gets = GETSInterface(getsAddress);
        require(
            msg.value > 0,
            "Reset Time: Need to pay some ether as a fee charge"
        );
        uint256 feesToPay = msg.value * tokenPrice;

        badgeExpiry[badgeId] = _reMaturedTime;
        payable(owner()).transfer(msg.value);
        gets.transferPrice(msg.sender, owner(), feesToPay);
    }

    function claimBadgePrize(uint256 badgeId) external onlyStudent {
        require(
            balanceOf(msg.sender, badgeId) == 1,
            "ERROR: Can claim prize of assigned badges only"
        );
        require(
            block.timestamp >= tokenClaimedTime[msg.sender],
            "ERROR: can claim only after claimed time"
        );
        ContractManagerInterface manager = ContractManagerInterface(
            managerAddress
        );
        address getsAddress = manager.getAddress("gets");
        GETSInterface gets = GETSInterface(getsAddress);
        require(
            isBadgeClaimed[msg.sender][badgeId] == 0,
            "Badge already claimed"
        );
        isBadgeClaimed[msg.sender][badgeId] = 1;
        uint256 x = (_badgePrize[badgeId] * 3) / 100;
        uint256 sClaim = _badgePrize[badgeId] - x;
        gets.transferPrice(address(this), msg.sender, sClaim);
        gets.transferPrice(address(this), owner(), x);
        emit claimBadge(msg.sender, badgeId);
    }

    function ownerOf(uint256 tokenId) external view virtual returns (address) {
        return
            _tokenOwners.get(
                tokenId,
                "ERC1155: owner query for nonexistent token"
            );
    }

    function totalSupply() public view virtual returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    function tokenByIndex(uint256 index)
        external
        view
        virtual
        returns (uint256)
    {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    // extra  function----------------------------------
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    //---------------------------------------------------
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        virtual
        returns (uint256)
    {
        return mapUserBadge[owner].at(index);
    }

    function tokenOf(address owner) external view virtual returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return mapUserBadge[owner].length();
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract NFTMarketplace{
    
    struct MarketItem {
        uint256 index;
        uint256 price;
        uint256 tokenId;
        uint256 fee;
        string id;
        string tokenName;
        string description;
        string imgUrl;
        address nftContract;
        address payable Owner;
        bool auction;
    }
    
    string[] public ItemArray;
    address public marketOwner;

    constructor() {
        marketOwner = msg.sender;
    }

    mapping(string => MarketItem) public itemsForSale;
    mapping(string => bool ) public tokenExists;
    mapping(string => bool) public activeItems; 
    event itemAddedForSale(
        uint256 index,
        uint256 price,
        uint256 tokenId,
        uint256 fee,
        string id,
        string tokenName,
        string description,
        string imgUrl,
        address nftContract,
        address payable Owner,
        bool auction
    );// Create New NFT on the marketplace

    event againInput(
        uint256 index, 
        uint256 price, 
        uint256 fee,
        string id, 
        string tokenName, 
        string description, 
        string imgUrl,
        address nftContract, 
        address payable Owner
        );
     event pullOutTokenEvent(
        string id
    );

    //Input NFTS
    function putItemForSale(
        uint256  _price, 
        uint256  _tokenId,
        uint256 _fee,
        string memory _id, 
        string memory _tokenName, 
        address _nftContract,
        string memory _description,
        string memory _imgUrl
        ) external 
    returns(bool){
        require ( msg.sender != address(0));
        require ( !activeItems [_id], "Item is already up for sale");
        if (!tokenExists[_id]) {
            itemsForSale[_id].price = _price;
            itemsForSale[_id].tokenId = _tokenId;
            itemsForSale[_id].fee = _fee;
            itemsForSale[_id].id = _id;
            itemsForSale[_id].tokenName = _tokenName;
            itemsForSale[_id].description = _description;
            itemsForSale[_id].imgUrl = _imgUrl;
            itemsForSale[_id].nftContract = _nftContract;
            itemsForSale[_id].Owner = payable(msg.sender);
            itemsForSale[_id].auction = false;
            ItemArray.push(_id);
            itemsForSale[_id].index = ItemArray.length -1;

            emit itemAddedForSale(
                ItemArray.length -1,
                _price,
                _tokenId,
                _fee,
                _id,
                _tokenName,
                _description,
                _imgUrl,
                _nftContract,
                payable(msg.sender),
                false
            );
            activeItems[_id] = true;
            tokenExists[_id] = true;
        } else {
            itemsForSale[_id].price = _price;
            ItemArray.push(_id);
            itemsForSale[_id].Owner = payable(msg.sender);
            itemsForSale[_id].fee = _fee;
            itemsForSale[_id].index = ItemArray.length - 1;
            itemsForSale[_id].auction = false;
            activeItems[_id] = true;
            emit againInput(
                 ItemArray.length - 1,
                _price,
                _fee,
                _id,
                _tokenName,
                _description,
                _imgUrl,
                _nftContract,
                payable(msg.sender)
            );
        }    
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);    
        return true;
        }

    //NFT------withdraw 
    function pullOutToken(string memory _id) external returns (bool){
        require(tokenExists[_id],"Not exist NFT");
        uint rowToDelete = itemsForSale[_id].index;
        string memory keyToMove = ItemArray[ItemArray.length-1];

        ItemArray[rowToDelete] = keyToMove;
        itemsForSale[keyToMove].index = rowToDelete; 
        ItemArray.pop();
        activeItems[_id] = false;
        emit pullOutTokenEvent(_id);
        IERC721(itemsForSale[_id].nftContract).transferFrom(address(this), msg.sender, itemsForSale[_id].tokenId);
        return activeItems[_id];
    }

    //NFT-------Buy
    function buyFromMarketplace(address _nftContract, uint256 _tokenId, string memory _id, address payable _to) external{
        uint rowToDelete = itemsForSale[_id].index;
        string memory keyToMove = ItemArray[ItemArray.length - 1];

        ItemArray[rowToDelete] = keyToMove;
        itemsForSale[keyToMove].index = rowToDelete; 
        ItemArray.pop();
        activeItems[_id] = false;
        //### transfor from buyer to contract
        _to.transfer(10);
        //###############################
        IERC721(_nftContract).transferFrom(address(this), payable(msg.sender), _tokenId);
    }
    function checkApproved(address nftAddr) public view returns(bool){
        return  IERC721(nftAddr).isApprovedForAll(msg.sender, address(this));
    }
    
    // get total counts of NFT 
    function getTotalCount() view public returns (uint) {
        return ItemArray.length;
    }

    // get All of NFTs 
    function getTotalValue() public view returns (MarketItem[] memory) {
        MarketItem[] memory memoryArray = new MarketItem[](ItemArray.length);
        for(uint i = 0; i < ItemArray.length ; i++){
                memoryArray[i] = itemsForSale[ItemArray[i]];
        }
        return memoryArray;
    }
    function getItemArray() public view returns (string[] memory) {
        return ItemArray;
    }
    // get current NFT's info 
    function getCurrentValue(string memory _id) public view returns (MarketItem memory) {
        return itemsForSale[_id];
    } 
    function getThisAddress() view public returns (address){
        return address(this);
    }
    function getMarketOwner() view public returns(address) {
        return marketOwner;
    }
    function changeMarketOwner(address _ownerAddr) public returns(address newOwnerAddr) {
        require(msg.sender== marketOwner, "You are not previous Owner. You cannot change Owner");
        marketOwner = _ownerAddr;
        return marketOwner;

    }

    //#######################################################
    //        Auction contract
    //#######################################################
    enum AuctionStatus {
        Cancelled,
        Active,
        Completed
    }
    
    event AuctionCreated(uint256 totaAuctionCount);
    event AuctionSuccessful(uint256 id, uint nftId);
    event AuctionCancelled(uint256 id, uint nftId);
    event BidCreated(string id, uint256 index, address bidder, uint256 bid);
    event AuctionNFTWithdrawal(uint256 auctionId, address contractaddress, address highestBider);
    event userEvent(string msg);

    struct Auction {
        uint index; // NFT ID
        uint256 duration; // Block count for when the auction ends
        uint256 startedAt; // Approximate time for when the auction was started
        uint256 highestBid; // Current highest bid
        uint256 tokenId;
        address nftContract;
        address seller; // Current owner of NFT
        address highestBidder; // Address of current highest bidder
        bool cancelled; // Flag for cancelled auctions
    }

    mapping(string => Auction) public auctions;

    string[] public auctionArray;
    mapping(string => bool)  public withDrawEnd;

    function createAuction(
        string memory _id,
        uint256 _duration, 
        uint256 _startedAt,
        uint256 _highestBid
        ) 
    public returns(Auction memory) {
        itemsForSale[_id].auction = true;
        auctions[_id].duration = _duration;
        auctions[_id].startedAt = _startedAt;
        auctions[_id].highestBid = _highestBid;
        auctions[_id].tokenId = itemsForSale[_id].tokenId;
        auctions[_id].nftContract = itemsForSale[_id].nftContract;
        auctions[_id].seller = itemsForSale[_id].Owner;
        auctions[_id].highestBidder =  address(0);
        auctions[_id].cancelled = false;
        auctionArray.push(_id);
        auctions[_id].index = auctionArray.length - 1;
        withDrawEnd[_id] = false;
        emit AuctionCreated(auctionArray.length - 1);

        return auctions[_id];
    }

    function placeBid(string memory _Id, uint256 _bidPrice)
    external payable 
    returns(bool success) {
        Auction storage _auction = auctions[_Id];
        
        // uint256 nftPrice = auction.highestBid;
        //### Send back to the previous bidder
        if(_auction.highestBidder != address(0)){
            address _to = _auction.highestBidder;
            uint256 _amount = _auction.highestBid;
           payable(_to).transfer(_amount);
        }
        //########################
        _auction.highestBid = _bidPrice;
        _auction.highestBidder = msg.sender;
        //############sen money to the Market contract from bidder
        // transferFrom(payable(msg.sender), payable(address(this)), _bidPrice);
        //###################
         emit BidCreated(_Id, _auction.index, msg.sender, _bidPrice);

        return true;
    }
    function checkContractBalance()  public view returns(uint) {
        return address(this).balance;
    }


    function withDrawBalance(string memory _Id) external returns(bool success) {
        AuctionStatus _status = _getAuctionStatus(_Id);
        Auction storage _auction = auctions[_Id];
        address fundsFrom;
        uint withdrawAmount;
        require(!withDrawEnd[_Id],"WithDraw succesfully finished!");
        if(msg.sender == _auction.seller || msg.sender == _auction.highestBidder) {
            require(_status == AuctionStatus.Completed, "Please wait for ther auction to complete");
            fundsFrom = _auction.highestBidder;
            withdrawAmount = _auction.highestBid;
            payable(fundsFrom).transfer(withdrawAmount);// send money to seller
            IERC721(_auction.nftContract).transferFrom(address(this), msg.sender, _auction.tokenId);   //send NFT to the winner
            // Delect from the marketplace
            uint rowToDelete = itemsForSale[_Id].index;
            string memory keyToMove = ItemArray[ItemArray.length - 1];
            ItemArray[rowToDelete] = keyToMove;
            itemsForSale[keyToMove].index = rowToDelete; 
            ItemArray.pop();
            activeItems[_Id] = false;
            withDrawEnd[_Id] = true;
            emit AuctionNFTWithdrawal(_auction.index, _auction.nftContract, msg.sender);
            return true;
        }else {
            emit userEvent("you can not withdraw");
        }
    }

    function getAuction(string memory _Id)
    external view returns(
        Auction memory
    ){
        return(auctions[_Id]);
    }
     function getAuctionState(string memory _Id)
    external view returns(
        AuctionStatus status
    ){
        AuctionStatus _status = _getAuctionStatus(_Id);
        return(_status);
    }

    function _getAuctionStatus(string memory _Id)
    internal view returns(AuctionStatus) {
        Auction storage auction = auctions[_Id];
        
        if (auction.startedAt + auction.duration < block.timestamp) {
            return AuctionStatus.Completed;
        } else {
            return AuctionStatus.Active;
        }
    }

    modifier statusIs(AuctionStatus expectedStatus, string  memory _Id) {
        require(expectedStatus == _getAuctionStatus(_Id));
        _;
    }
}




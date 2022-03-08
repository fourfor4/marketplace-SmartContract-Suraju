// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract NFTmint is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256  MINT_FEE;
    address payable owner;

    constructor() ERC721("NFTARTGALLERYCOMPANY", "ARTCOMPANY") {
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setMintFee(uint256 _fee) public onlyOwner {
        MINT_FEE = _fee;
    }
    
    function getMintFee() public view returns(uint256) {
        return MINT_FEE;
    }
    
    function setOwner(address _new) public onlyOwner {
        owner = payable(_new);
    }
    
    function getOwner() public view returns(address) {
        return owner;
    }
    
    function mintToken(string memory metadataURI)
    public 
    {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _safeMint(msg.sender, id);
            _setTokenURI(id, metadataURI);
    }
}
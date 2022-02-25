//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Raffleable.sol";

contract RelevanksyNFT is ERC721, Ownable, Raffleable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _name = "the relevanksy collection";
    string private _symbol = "$trc";

    uint256 constant _maxNFTs = 1000;

    mapping (uint256 => string) private _tokenURIs;
    string private _baseURIextended;

    constructor() ERC721(_name, _symbol) {
        _setBaseURI("ipfs://");
    }

    function _setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    function mintToken(address owner, string memory metadataURI) public manageRaffleEntry returns (uint256)
    {
        require(_tokenIds.current() <= _maxNFTs, "Cannot exceed the max NFTs for this collection!");

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);

        return id;
    }
}
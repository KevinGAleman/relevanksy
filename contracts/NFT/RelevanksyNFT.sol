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
    string private _symbol = "trc";

    uint256 public constant _totalSupply = 1000;

    mapping (uint256 => string) private _tokenURIs;
    string private _baseURIextended;

    constructor() ERC721(_name, _symbol) {}
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenURIs[tokenId];
    }

    function mintToken(string memory metadataURI) public manageRaffleEntry returns (uint256)
    {
        require(_tokenIds.current() <= _totalSupply, "Cannot exceed the max NFTs for this collection!");

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(_msgSender(), id);
        _setTokenURI(id, metadataURI);

        return id;
    }
}
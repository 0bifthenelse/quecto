/**
           _______                   _____                    _____                    _____                _____                   _______         
          /::\    \                 /\    \                  /\    \                  /\    \              /\    \                 /::\    \        
         /::::\    \               /::\____\                /::\    \                /::\    \            /::\    \               /::::\    \       
        /::::::\    \             /:::/    /               /::::\    \              /::::\    \           \:::\    \             /::::::\    \      
       /::::::::\    \           /:::/    /               /::::::\    \            /::::::\    \           \:::\    \           /::::::::\    \     
      /:::/~~\:::\    \         /:::/    /               /:::/\:::\    \          /:::/\:::\    \           \:::\    \         /:::/~~\:::\    \    
     /:::/    \:::\    \       /:::/    /               /:::/__\:::\    \        /:::/  \:::\    \           \:::\    \       /:::/    \:::\    \   
    /:::/    / \:::\    \     /:::/    /               /::::\   \:::\    \      /:::/    \:::\    \          /::::\    \     /:::/    / \:::\    \  
   /:::/____/   \:::\____\   /:::/    /      _____    /::::::\   \:::\    \    /:::/    / \:::\    \        /::::::\    \   /:::/____/   \:::\____\ 
  |:::|    |     |:::|    | /:::/____/      /\    \  /:::/\:::\   \:::\    \  /:::/    /   \:::\    \      /:::/\:::\    \ |:::|    |     |:::|    |
  |:::|____|     |:::|____||:::|    /      /::\____\/:::/__\:::\   \:::\____\/:::/____/     \:::\____\    /:::/  \:::\____\|:::|____|     |:::|    |
   \:::\   _\___/:::/    / |:::|____\     /:::/    /\:::\   \:::\   \::/    /\:::\    \      \::/    /   /:::/    \::/    / \:::\    \   /:::/    / 
    \:::\ |::| /:::/    /   \:::\    \   /:::/    /  \:::\   \:::\   \/____/  \:::\    \      \/____/   /:::/    / \/____/   \:::\    \ /:::/    /  
     \:::\|::|/:::/    /     \:::\    \ /:::/    /    \:::\   \:::\    \       \:::\    \              /:::/    /             \:::\    /:::/    /   
      \::::::::::/    /       \:::\    /:::/    /      \:::\   \:::\____\       \:::\    \            /:::/    /               \:::\__/:::/    /    
       \::::::::/    /         \:::\__/:::/    /        \:::\   \::/    /        \:::\    \           \::/    /                 \::::::::/    /     
        \::::::/    /           \::::::::/    /          \:::\   \/____/          \:::\    \           \/____/                   \::::::/    /      
         \::::/____/             \::::::/    /            \:::\    \               \:::\    \                                     \::::/    /       
          |::|    |               \::::/    /              \:::\____\               \:::\____\                                     \::/____/        
          |::|____|                \::/____/                \::/    /                \::/    /                                      ~~              
           ~~                       ~~                       \/____/                  \/____/                                                       
  Developer: Apeiron                                                                                                                                                
  Telegram: https://t.me/OxApeiron                                                                                                                                                
  ENS: 0xapeiron.eth                                                                                                                                                
  Wallet: 0xF3f1BADD2b039799De0023D78c570002b6E89346                                                                                                                                                
  ---------------------------------------------------
  The Quecto Repository is an open source, MIT-licensed smart contract repository on Github. They are made with the intent to be used & taken inspiration from by anyone.
  These smart contracts are not audited, but built by a known auditor (Apeiron).
  Usage and inspiration from this smart contract are not the responsibility of the original developer (Apeiron).
  ---------------------------------------------------
  This is a soulbound NFT smart contract, with a centralized minting system.
  This uses ERC721 (NFT) standard, with modifications to prevent transfers (soulbound).
  Example usage: KYC, dox.
  Properties:
  -
  -
  -
  -
  -
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Kedge is ERC721, ERC721URIStorage, Ownable {
    uint256 private tokenID;

    constructor() ERC721("Kedge", "KDG") {}

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function mint(address to, string memory uri) external onlyOwner {
        tokenID++;
        _safeMint(to, tokenID);
        _setTokenURI(tokenID, uri);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        require(from == address(0), "Token transfer is forbidden.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}

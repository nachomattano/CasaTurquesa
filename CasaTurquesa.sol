// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
// Vulcano Blockchain Services
// www.vulcanoservices.me
//////////////////////////////////////////////////////////////////////////////////////////////

contract CasaTurquesa is ERC721, Ownable {

  using Strings for uint256;
  using Counters for Counters.Counter;

  mapping (uint256 => bool) public firstClaim;
  mapping (uint256 => uint256) public timeClaimed;
  mapping(address => bool) internal _blacklist;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";

  uint256 public maxSupply = 52;

  bool public paused = false;

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  constructor() ERC721("Casa Turquesa", "CT") {}

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!_blacklist[msg.sender], "Blacklisted address");
    require(!paused, "The contract is paused!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setUri(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function blacklist(address account) external onlyOwner returns (bool) {
    _blacklist[account] = true;
    return true;
  }

  function unblacklist(address account) external onlyOwner returns (bool) {
    delete _blacklist[account];
    return true;
  }

  function blacklisted(address account) external view virtual returns (bool) {
    return _blacklist[account];
  }

  function checkIn(uint256 _id) public onlyOwner {
    require(_id > 0, "Invalid id");
    require(_id <= maxSupply, "Invalid id");
    if (firstClaim[_id] == false){
      firstClaim[_id] = true;
      timeClaimed[_id] = block.timestamp;
    }
    else {
      require(block.timestamp >= (timeClaimed[_id] + 40 seconds), "No se cumplio un ano");
      timeClaimed[_id] = block.timestamp;
    }
  }
}
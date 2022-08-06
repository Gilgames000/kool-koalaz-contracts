// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "./Whitelistable.sol";
import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/utils/Multicall.sol";

error MintPriceNotPaid();
error SoftCapSupplyReached();
error MaxSupplyReached();
error EmptyURI();
error MintingNotStartedYet();
error TransferFailed(address recipient);
error InvalidAmount(uint256 amount);

contract KoolKoalazNFT is
    ERC721A,
    ERC2981,
    Ownable,
    Pausable,
    Whitelistable,
    Multicall
{
    address public constant revenueTreasury = 0x28F23227845a77b96791b93711B157649855b1F4;
    address public constant premintTreasury = 0xF8089e6711c5caF89d3b271E11Bd779b135bA03B;
    uint256 public constant maxSupply = 5555;

    uint256 public softCapSupply;
    uint256 public mintPrice = 0.5 ether;
    uint256 public whitelistMintPrice = 0.4 ether;
    uint256 public mintStartTimestamp = 1659981600; // Sat Aug 08 2022 18:00:00 UTC+0000
    string public baseURI;

    modifier whenMintStarted() {
        if (block.timestamp < mintStartTimestamp) {
            revert MintingNotStartedYet();
        }
        _;
    }

    constructor() ERC721A("Kool Koalaz", "KOALAZ") {
        super._setDefaultRoyalty(revenueTreasury, 1000);
        increaseSoftCapSupply(1111, 150);
    }

    function mint(uint256 amount) public payable whenNotPaused whenMintStarted {
        if (amount == 0) {
            revert InvalidAmount(amount);
        }

        if (totalSupply() + amount > softCapSupply) {
            revert SoftCapSupplyReached();
        }

        uint256 _whitelistSpotsToSpend = whitelistSpots[msg.sender];
        if (_whitelistSpotsToSpend > amount) {
            _whitelistSpotsToSpend = amount;
        }

        uint256 _totalMintPrice = (amount - _whitelistSpotsToSpend)*mintPrice + _whitelistSpotsToSpend*whitelistMintPrice;
        if (msg.value < _totalMintPrice) {
            revert MintPriceNotPaid();
        }

        _removeWhitelistSpots(msg.sender, _whitelistSpotsToSpend);
        _mint(msg.sender, amount);

        (bool success, ) = address(revenueTreasury).call{value: _totalMintPrice}("");
        if (!success) {
            revert TransferFailed(revenueTreasury);
        }

        uint256 _excessPayment = msg.value - _totalMintPrice;
        if (_excessPayment == 0) {
            return;
        }

        (success, ) = address(msg.sender).call{value: _excessPayment}("");
        if (!success) {
            revert TransferFailed(msg.sender);
        }
    }

    function increaseSoftCapSupply(uint256 _amount, uint256 _reservedAmount)
        public
        onlyOwner
    {
        if (softCapSupply + _amount > maxSupply) {
            revert MaxSupplyReached();
        }

        if (_reservedAmount > _amount) {
            revert InvalidAmount(_reservedAmount);
        }

        softCapSupply += _amount;
        _mint(premintTreasury, _reservedAmount);
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function setWhitelistMintPrice(uint256 _price) public onlyOwner {
        whitelistMintPrice = _price;
    }

    function setMintStartTimestamp(uint256 _timestamp) public onlyOwner {
        mintStartTimestamp = _timestamp;
    }

    function setBaseURI(string calldata uri) public onlyOwner {
        if (bytes(uri).length == 0) {
            revert EmptyURI();
        }

        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhitelistSpots(address _addr, uint256 _amount)
        public
        onlyOwner
    {
        _addWhitelistSpots(_addr, _amount);
    }

    function removeWhitelistSpots(address _addr, uint256 _amount)
        public
        onlyOwner
    {
        _removeWhitelistSpots(_addr, _amount);
    }

    function clearWhitelistSpots(address _addr) public onlyOwner {
        _clearWhitelistSpots(_addr);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface PriceFeed {
    function latestRoundData() external view
    returns (uint80 roundId, int256 answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}

contract CryptoSurfersNFT is OwnableUpgradeable, IERC721MetadataUpgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, PaymentSplitterUpgradeable {

    struct SaleInformation {
        bool saleEnabled;             // if sale is active
        uint ethBalance;              // balance in eth
        uint USDTBalance;             // balance in usdt
        uint USDTAllowance;           // allowance in usdt for the contract
        uint userMinted;              // minted by the user
        uint totalMintedInCollection; // total minted in the collection
        uint maxPerSale;              // max items to buy per tx
        uint latestPriceInEth;        // price of NFT in eth
        uint latestPriceInUSDT;       // price of NFT in usdt
    }

    // @dev USDT address
    IERC20 public usdt;

    // @dev USDT against ETH price feed
    PriceFeed public priceFeed;

    // @dev MAX per buying event
    uint public maxPerSale;

    // @dev defines sale price in USDT (6 decimals)
    uint public salePrice;

    // @dev if sale is active enables minting function
    bool public saleEnabled;

    // @dev base uri for the generation of the token uris
    string public baseURI;

    function __CryptoSurfersNFT_initialize(
        address _owner,
        string memory baseURI_,
        uint _salePrice,
        uint _maxPerSale,
        address _usdtAddress,
        address _priceFeedAddress,
        address[] memory payees,
        uint[] memory shares_
    ) initializer public {
        __Ownable_init();
        __Pausable_init();
        __ERC721_init("CryptoSurfersNFT", "SURF");
        __ERC721Enumerable_init();
        __PaymentSplitter_init(payees, shares_);
        transferOwnership(_owner);

        baseURI = baseURI_;
        salePrice = _salePrice;
        maxPerSale = _maxPerSale;
        usdt = IERC20(_usdtAddress);
        priceFeed = PriceFeed(_priceFeedAddress);
    }

    function mintTo(address _to, uint[] memory _dna, bool payWithEther) public payable {
        _mint(_to, _dna, payWithEther);
    }

    function mint(uint[] memory _dna, bool payWithEther) public payable {
        _mint(msg.sender, _dna, payWithEther);
    }

    function _mint(address _to, uint[] memory _dna, bool payWithEther) internal {
        require(saleEnabled && !paused(), "CryptoSurfersNFT::mint: Sale is not active.");
        require(_dna.length > 0, "CryptoSurfersNFT::mint: Quantity cannot be zero.");
        require(_dna.length <= maxPerSale, "CryptoSurfersNFT::mint: Quantity cannot be bigger than maxPerSale.");

        if (payWithEther) {
            uint ethPrice = getLatestPriceInEth() * _dna.length;
            // deviation threshold 0.5%
            ethPrice = (ethPrice / 1000) * 995;
            require(msg.value >= ethPrice, "CryptoSurfersNFT::mint: Value sent is insufficient");
        } else {
            require(usdt.balanceOf(msg.sender) >= salePrice * _dna.length, "CryptoSurfersNFT::mint: USDT balance is insufficient");
            require(usdt.allowance(msg.sender, address(this)) >= salePrice * _dna.length, "CryptoSurfersNFT::mint: USDT allowance is insufficient");
            usdt.transferFrom(msg.sender, address(this), salePrice * _dna.length);
        }
        for (uint i = 0; i < _dna.length; i++) {
            _safeMint(_to, _dna[i]);
        }
    }

    function mintByOwner(address _to, uint[] memory _dna) public onlyOwner {
        require(_dna.length > 0, "CryptoSurfersNFT::mintByOwner: Quantity cannot be zero.");
        for (uint i = 0; i < _dna.length; i++) {
            _safeMint(_to, _dna[i]);
        }
    }
    
    function batchMintByOwner(address[] memory _mintAddressList, uint[][] memory _dnaList) external onlyOwner {
        require (_mintAddressList.length == _dnaList.length, "CryptoSurfersNFT::batchMintByOwner: The length should be same");

        for (uint i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _dnaList[i]);
        }
    }

    function getLatestPriceInEth() public view returns (uint) {
        (,int price,,,) = priceFeed.latestRoundData();
        return (salePrice * 1e20) / uint(price);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setSalePrice(uint _newPrice) external onlyOwner {
        salePrice = _newPrice;
    }

    function setSaleMax(uint _maxPerSale) external onlyOwner {
        maxPerSale = _maxPerSale;
    }

    function enableSale() external onlyOwner {
        require(!saleEnabled, "CryptoSurfersNFT::startSale: Inconsistent status.");
        saleEnabled = true;
    }

    function disableSale() external onlyOwner {
        require(saleEnabled, "CryptoSurfersNFT::pauseSale: Sale is not active.");
        saleEnabled = false;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getSaleInformation(address _userAddress) external view returns (SaleInformation memory) {
        return SaleInformation({
            saleEnabled: saleEnabled && !paused(),
            ethBalance: _userAddress == address (0) ? 0 : _userAddress.balance,
            USDTBalance: _userAddress == address (0) ? 0 : usdt.balanceOf(_userAddress),
            USDTAllowance: _userAddress == address (0) ? 0 : usdt.allowance(_userAddress, address(this)),
            userMinted: _userAddress == address (0) ? 0 : balanceOf(_userAddress),
            totalMintedInCollection: totalSupply(),
            maxPerSale: maxPerSale,
            latestPriceInEth: getLatestPriceInEth(),
            latestPriceInUSDT: salePrice
        });
    }

    function tokenURI(uint _tokenId) public view virtual override(IERC721MetadataUpgradeable, ERC721Upgradeable) returns (string memory) {
        require(_exists(_tokenId), "CryptoSurfersNFT: NFT has not been minted");
        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId)));
    }

    /**
     * @dev See {ERC721AUpgradeable-_beforeTokenTransfers}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint startTokenId,
        uint quantity
    ) internal virtual override {
        require(!paused(), "CryptoSurfersNFT::_beforeTokenTransfers: token transfer while paused.");
        super._beforeTokenTransfer(from, to, startTokenId, quantity);
    }

    uint[50] private __gap;
}

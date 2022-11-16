// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface PriceFeed {
    function latestRoundData() external view
    returns (uint80 roundId, int256 answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}

contract CryptoSurfersNFT is OwnableUpgradeable, ERC721AUpgradeable, PausableUpgradeable, PaymentSplitterUpgradeable {

    struct SaleInformation {
        bool saleEnabled;             // if sale is active
        uint ethBalance;              // balance in eth
        uint USDTBalance;             // balance in usdt
        uint USDTAllowance;           // allowance in usdt for the contract
        uint userMinted;              // minted by the user
        uint totalMintedInCollection; // total minted in the collection
        uint latestPriceInEth;        // price of NFT in eth
        uint latestPriceInUSDT;       // price of NFT in usdt
    }

    // @dev USDT address
    IERC20 public usdt;

    // @dev USDT against ETH price feed
    PriceFeed public priceFeed;

    // @dev mapping for token URIs
    mapping(uint => string) private tokenURIs;

    // @dev MAX per buying event
    uint public MAX_SALE = 300;   

    // @dev defines sale price in USDT (6 decimals)
    uint public salePrice;

    // @dev if sale is active enables minting function
    bool public saleEnabled;

    function __CryptoSurfersNFT_initialize(
        address _owner,
        uint _salePrice,
        address _usdtAddress,
        address _priceFeedAddress,
        address[] memory payees,
        uint[] memory shares_
    ) initializer public {
        __Ownable_init();
        __Pausable_init();
        __ERC721A_init("CryptoSurfersNFT", "SURF");
        __PaymentSplitter_init(payees, shares_);
        transferOwnership(_owner);

        salePrice = _salePrice;
        usdt = IERC20(_usdtAddress);
        priceFeed = PriceFeed(_priceFeedAddress);
    }

    function mint(uint _quantity, bool payWithEther) external payable  {
        require(saleEnabled && !paused(), "CryptoSurfersNFT::mint: Sale is not active.");
        require(_quantity > 0, "CryptoSurfersNFT::mint: Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "CryptoSurfersNFT::mint: Quantity cannot be bigger than MAX_BUYING.");

        if (payWithEther) {
            uint ethPrice = getLatestPriceInEth() * _quantity;
            // deviation threshold 0.5%
            ethPrice = (ethPrice / 1000) * 995;
            require(msg.value >= ethPrice, "CryptoSurfersNFT::mint: Value sent is insufficient");
        } else {
            require(usdt.balanceOf(msg.sender) >= salePrice * _quantity, "CryptoSurfersNFT::mint: USDT balance is insufficient");
            require(usdt.allowance(msg.sender, address(this)) >= salePrice * _quantity, "CryptoSurfersNFT::mint: USDT allowance is insufficient");
            usdt.transferFrom(msg.sender, address(this), salePrice * _quantity);
        }
        
        _safeMint(msg.sender, _quantity);
    }

    function mintByOwner(address _to, uint _quantity) public onlyOwner {
        require(_quantity > 0, "CryptoSurfersNFT::mintByOwner: Quantity cannot be zero.");
        
        _safeMint(_to, _quantity);
    }
    
    function batchMintByOwner(address[] memory _mintAddressList, uint[] memory _quantityList) external onlyOwner {
        require (_mintAddressList.length == _quantityList.length, "CryptoSurfersNFT::batchMintByOwner: The length should be same");

        for (uint i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _quantityList[i]);
        }
    }

    function getLatestPriceInEth() public view returns (uint) {
        (,int price,,,) = priceFeed.latestRoundData();
        return (salePrice * 1e20) / uint(price);
    }

    function setSalePrice(uint _newPrice) external onlyOwner {
        salePrice = _newPrice;
    }

    function setSaleMax(uint _saleMax) external onlyOwner {
        MAX_SALE = _saleMax;
    }

    function enableSale() external onlyOwner {
        require(!saleEnabled, "CrowdsaleStatus::startSale: Inconsistent status.");
        saleEnabled = true;
    }

    function disableSale() external onlyOwner {
        require(saleEnabled, "CrowdsaleStatus::pauseSale: Sale is not active.");
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
            ethBalance: _userAddress.balance,
            USDTBalance: usdt.balanceOf(_userAddress),
            USDTAllowance: usdt.allowance(_userAddress, address(this)),
            userMinted: balanceOf(_userAddress),
            totalMintedInCollection: totalSupply(),
            latestPriceInEth: getLatestPriceInEth(),
            latestPriceInUSDT: salePrice
        });
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "CryptoSurfersNFT: NFT has not been minted");
        return tokenURIs[tokenId];
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "CryptoSurfersNFT: URI set of nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721AUpgradeable-_beforeTokenTransfers}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint startTokenId,
        uint quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "CryptoSurfersNFT::_beforeTokenTransfers: token transfer while paused.");
    }

    uint[50] private __gap;
}

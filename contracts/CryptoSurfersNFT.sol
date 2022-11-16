// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Sale {
    enum Status {
        NOT_STARTED, // 0
        STARTED,     // 1
        PAUSED,      // 2
        ENDED        // 3
    }

    struct Information {
        uint256 ethBalance;              // balance in eth
        uint256 erc20Balance;            // balance in erc20
        uint256 erc20Allowance;          // allowance in erc20 for the contract
        uint256 userMinted;              // minted by the user
        uint256 totalMintedInCollection; // total minted in the collection
        uint256 latestPriceInMatic;      // price of NFT in eth
        uint256 latestPriceInErc20;      // price of NFT in erc20
    }
}

contract CryptoSurfersNFT is OwnableUpgradeable, ERC721AUpgradeable, PausableUpgradeable, PaymentSplitterUpgradeable {

    // USDT address
    IERC20 public erc20;

    // USDT against ETH price feed
    AggregatorV3Interface public priceFeed;

    string private _baseTokenURI;

    // MAX per buying event
    uint public MAX_SALE = 300;   

    uint public salePrice;

    SaleStatus public saleStatus;

    function __CryptoSurfersNFT_initialize(
        address _owner,
        string memory baseURI_,
        address _eRC20address,
        address _priceFeedAddress,
        address[] memory payees,
        uint256[] memory shares_
    ) {
        __Ownable_init();
        __Pausable_init();
        __ERC721A_init(_name, _symbol);
        __PaymentSplitter_init_unchained(payees, shares_);
        transferOwnership(_owner);

        erc20 = IERC20(_eRC20address);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        salePrice = 0.1 ether;
        _baseTokenURI = baseURI_;
        saleStatus = SaleStatus.NOT_STARTED;
    }

    function mint(uint _quantity, bool payWithEther) external payable  {
        require(saleStatus == SaleStatus.SALE, "CryptoSurfersNFT::mint: Sale hasn't started.");
        require(_quantity > 0, "CryptoSurfersNFT::mint: Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "CryptoSurfersNFT::mint: Quantity cannot be bigger than MAX_BUYING.");

        if (payWithEther) {
            uint ethPrice = getLatestPriceInEth() * _quantity;
            // deviation threshold 0.5%
            ethPrice = (ethPrice / 1000) * 995;
            require(msg.value >= ethPrice, "CryptoSurfersNFT::mint: Value sent is insufficient");
        } else {
            require(erc20.balanceOf(msg.sender) >= salePprice * _quantity, "CryptoSurfersNFT::mint: USDT balance is insufficient");
            require(erc20.allowance(msg.sender, address(this)) >= salePprice * _quantity, "CryptoSurfersNFT::mint: USDT allowance is insufficient");
            erc20.transferFrom(msg.sender, address(this), salePprice * _quantity);
        }
        
        _safeMint(msg.sender, _quantity);
    }

    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "CryptoSurfersNFT::mintByOwner: Quantity cannot be zero.");
        
        _safeMint(_to, _quantity);
    }
    
    function batchMintByOwner(address[] memory _mintAddressList, uint256[] memory _quantityList) external onlyOwner {
        require (_mintAddressList.length == _quantityList.length, "CryptoSurfersNFT::batchMintByOwner: The length should be same");

        for (uint256 i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _quantityList[i]);
        }
    }

    function getLatestPriceInEth() public view returns (uint) {
        (,int price,,,) = priceFeed.latestRoundData();
        return (salePrice * 1e20) / uint(price);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSalePrice(uint _newPrice) external onlyOwner {
        salePrice = _newPrice;
    }

    function setSaleMax(uint _saleMax) external onlyOwner {
        MAX_SALE = _saleMax;
    }

    function startSale() external onlyOwner {
        require(saleStatus == SaleStatus.NOT_STARTED || saleStatus == SaleStatus.SALE_PAUSED, "CrowdsaleStatus::startSale: Inconsistent status.");
        saleStatus = SaleStatus.SALE;
    }

    function pauseSale() external onlyOwner {
        require(saleStatus == SaleStatus.SALE, "CrowdsaleStatus::pauseSale: Sale is not active.");
        saleStatus = SaleStatus.SALE_PAUSED;
    }

    function endSale() external onlyOwner {
        require(saleStatus == SaleStatus.SALE || saleStatus == SaleStatus.SALE_PAUSED, "CrowdsaleStatus::endSale: Sale is not started.");
        saleStatus = SaleStatus.ENDED;
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function getSaleInformation(_userAddress) external view returns (Sale.Information) {
        return Sale.Information({
            ethBalance: _userAddress.balance,
            erc20Balance: erc20.balanceOf(_userAddress),
            erc20Allowance: erc20.allowance(_userAddress, address(this)),
            userMinted: balanceOf(_userAddress),
            totalMintedInCollection: totalSupply(),
            latestPriceInEth: getLatestPriceInEth(),
            latestPriceInErc20: salePrice
        });
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
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "CryptoSurfersNFT::_beforeTokenTransfers: token transfer while paused.");
    }

    uint256[50] private __gap;
}

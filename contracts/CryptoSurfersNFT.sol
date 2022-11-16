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

library Sale {
    enum Status {
        NOT_STARTED, // 0
        STARTED,     // 1
        PAUSED,      // 2
        ENDED        // 3
    }

    struct Information {
        uint ethBalance;              // balance in eth
        uint USDTBalance;             // balance in usdt
        uint USDTAllowance;           // allowance in usdt for the contract
        uint userMinted;              // minted by the user
        uint totalMintedInCollection; // total minted in the collection
        uint latestPriceInEth;        // price of NFT in eth
        uint latestPriceInUSDT;       // price of NFT in usdt
    }
}

contract CryptoSurfersNFT is OwnableUpgradeable, ERC721AUpgradeable, PausableUpgradeable, PaymentSplitterUpgradeable {

    // USDT address
    IERC20 public usdt;

    // USDT against ETH price feed
    PriceFeed public priceFeed;

    string private _baseTokenURI;

    // MAX per buying event
    uint public MAX_SALE = 300;   

    uint public salePrice;

    Sale.Status public saleStatus;

    function __CryptoSurfersNFT_initialize(
        address _owner,
        string memory baseURI_,
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

        usdt = IERC20(_usdtAddress);
        priceFeed = PriceFeed(_priceFeedAddress);
        salePrice = 0.1 ether;
        _baseTokenURI = baseURI_;
        saleStatus = Sale.Status.NOT_STARTED;
    }

    function mint(uint _quantity, bool payWithEther) external payable  {
        require(saleStatus == Sale.Status.STARTED, "CryptoSurfersNFT::mint: Sale hasn't started.");
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
        require(saleStatus == Sale.Status.NOT_STARTED || saleStatus == Sale.Status.PAUSED, "CrowdsaleStatus::startSale: Inconsistent status.");
        saleStatus = Sale.Status.STARTED;
    }

    function pauseSale() external onlyOwner {
        require(saleStatus == Sale.Status.STARTED, "CrowdsaleStatus::pauseSale: Sale is not active.");
        saleStatus = Sale.Status.PAUSED;
    }

    function endSale() external onlyOwner {
        require(saleStatus == Sale.Status.STARTED || saleStatus == Sale.Status.PAUSED, "CrowdsaleStatus::endSale: Sale is not started.");
        saleStatus = Sale.Status.ENDED;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getSaleInformation(address _userAddress) external view returns (Sale.Information memory) {
        return Sale.Information({
            ethBalance: _userAddress.balance,
            USDTBalance: usdt.balanceOf(_userAddress),
            USDTAllowance: usdt.allowance(_userAddress, address(this)),
            userMinted: balanceOf(_userAddress),
            totalMintedInCollection: totalSupply(),
            latestPriceInEth: getLatestPriceInEth(),
            latestPriceInUSDT: salePrice
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
        uint startTokenId,
        uint quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "CryptoSurfersNFT::_beforeTokenTransfers: token transfer while paused.");
    }

    uint[50] private __gap;
}

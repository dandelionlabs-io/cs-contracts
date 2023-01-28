// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface PriceFeed {
    function latestRoundData() external view
    returns (uint80 roundId, int256 answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}

contract CryptoSurfersNFT is OwnableUpgradeable, IERC2981Upgradeable, ERC721Upgradeable {

    struct SaleInformation {
        bool saleEnabled;             // if sale is active
        uint ethBalance;              // balance in eth
        uint USDTBalance;             // balance in usdt
        uint USDTAllowance;           // allowance in usdt for the contract
        uint userMinted;              // minted by the user
        uint totalMintedInCollection; // total minted in the collection
        uint maxPerSale;              // max items to buy per tx
        uint mintLimit;               // mint limit in the collection
        uint latestPriceInEth;        // price of NFT in eth
        uint latestPriceInUSDT;       // price of NFT in usdt
        bool isOperator;              // if user is operator
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

    // @dev MAX mintable in collection
    uint public mintLimit;

    // @dev Mapping for valid operators
    mapping(address => bool) private operators;

    // @dev to set on chain royalties definition
    uint96 internal feeNumerator;

    // @dev to set the treasury address
    address public treasuryAddress;

    // @dev totalMinted
    uint public totalSupply;

    /**
     * @dev Throws if called by any account other than operator.
     */
    modifier onlyOperator() {
        require(isOperator(_msgSender()), "CryptoSurfersNFT::onlyOperator: caller is not an operator.");
        _;
    }

    function __CryptoSurfersNFT_initialize(
        address _owner,
        address[] memory _operators,
        string memory baseURI_,
        uint _salePrice,
        uint _maxPerSale,
        uint _mintLimit,
        address _usdtAddress,
        address _priceFeedAddress,
        uint96 _feeNumerator,
        address _treasuryAddress
    ) initializer public {
        __Ownable_init();
        __ERC721_init("CryptoSurfersNFT", "SURF");
        transferOwnership(_owner);

        baseURI = baseURI_;
        salePrice = _salePrice;
        maxPerSale = _maxPerSale;
        mintLimit = _mintLimit;
        usdt = IERC20(_usdtAddress);
        priceFeed = PriceFeed(_priceFeedAddress);
        feeNumerator = _feeNumerator;
        treasuryAddress = _treasuryAddress;

        changeOperator(_owner, true);

        for (uint i = 0; i < _operators.length; i++) {
            changeOperator(_operators[i], true);
        }
    }

    function mintTo(address _to, uint[] memory _dna, bool payWithEther) external payable {
        _payAndMint(_to, _dna, payWithEther);
    }

    function _payAndMint(address _to, uint[] memory _dna, bool payWithEther) internal {
        require(saleEnabled, "CryptoSurfersNFT::mint: Sale is not active.");
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
        _mint(_to, _dna);
    }

    function mintByOperator(address _to, uint[] memory _dna) external onlyOperator {
        _mint(_to, _dna);
    }

    function batchMintByOperator(address[] memory _mintAddressList, uint[][] memory _dnaList) external onlyOperator {
        require (_mintAddressList.length == _dnaList.length, "CryptoSurfersNFT::batchMintByOperator: The length should be same");

        for (uint i = 0; i < _mintAddressList.length; i += 1) {
            _mint(_mintAddressList[i], _dnaList[i]);
        }
    }

    function _mint(address _to, uint[] memory _dna) internal {
        require(_dna.length > 0, "CryptoSurfersNFT::mint: Quantity cannot be zero.");
        require(totalSupply + _dna.length <= mintLimit, "CryptoSurfersNFT::mintByOperator: Cannot surpass the collection minting limit.");
        for (uint i = 0; i < _dna.length; i++) {
            _safeMint(_to, _dna[i]);
        }
        totalSupply += _dna.length;
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

    function setMaxPerSale(uint _maxPerSale) external onlyOwner {
        maxPerSale = _maxPerSale;
    }

    function setUsdtContract(address _usdtAddress) external onlyOwner {
        usdt = IERC20(_usdtAddress);
    }

    function setFeeNumerator(uint96 _feeNumerator) external onlyOwner {
        feeNumerator = _feeNumerator;
    }

    function changeOperator(address _operator, bool _status) public onlyOwner {
        operators[_operator] = _status;
    }

    function isOperator(address _account) public view returns (bool) {
        return operators[_account];
    }

    function enableSale() external onlyOwner {
        require(!saleEnabled, "CryptoSurfersNFT::startSale: Inconsistent status.");
        saleEnabled = true;
    }

    function disableSale() external onlyOwner {
        require(saleEnabled, "CryptoSurfersNFT::pauseSale: Sale is not active.");
        saleEnabled = false;
    }

    function getSaleInformation(address _userAddress) external view returns (SaleInformation memory) {
        return SaleInformation({
            saleEnabled: saleEnabled,
            ethBalance: _userAddress == address (0) ? 0 : _userAddress.balance,
            USDTBalance: _userAddress == address (0) ? 0 : usdt.balanceOf(_userAddress),
            USDTAllowance: _userAddress == address (0) ? 0 : usdt.allowance(_userAddress, address(this)),
            userMinted: _userAddress == address (0) ? 0 : balanceOf(_userAddress),
            totalMintedInCollection: totalSupply,
            maxPerSale: maxPerSale,
            mintLimit: mintLimit,
            latestPriceInEth: getLatestPriceInEth(),
            latestPriceInUSDT: salePrice,
            isOperator: _userAddress == address (0) ? false : isOperator(_userAddress)
        });
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "CryptoSurfersNFT::tokenURI: NFT has not been minted");
        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId)));
    }

    function royaltyInfo(uint _tokenId, uint _salePrice) external view virtual override returns (address, uint) {
        require(_exists(_tokenId), "CryptoSurfersNFT::royaltyInfo: NFT has not been minted.");
        uint royaltyAmount = (_salePrice * feeNumerator) / 10000;
        return (owner(), royaltyAmount);
    }

    function withdrawErc20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalBalance = token.balanceOf(address(this));

        require(
            token.transferFrom(address(this), treasuryAddress, totalBalance),
            "Withdraw Failed To Treasury Wallet."
        );
    }

    function withdrawEth() external onlyOwner {
        uint256 totalBalance = address(this).balance;

        (bool withdrawTreasuryAddress, ) = treasuryAddress.call{
        value: totalBalance
        }("");
        require(
            withdrawTreasuryAddress,
            "Withdraw Failed To Treasury Wallet."
        );
    }

    uint[49] private __gap;
}

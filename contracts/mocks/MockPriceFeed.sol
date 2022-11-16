// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockPriceFeed is AggregatorV3Interface {

    int price;

    constructor(int _price) {
        price = _price;
    }

    function decimals() external pure override returns (uint8) {
        return 6;
    }

    function description() external pure override returns (string memory) {
        return "";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        override 
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (_roundId, 0, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        override 
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (10, price, 0, 0, 0);
    }
}
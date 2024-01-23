//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getLatestPrice() internal view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        (, int256 price, , , ) = pricefeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getConversionRate(uint ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}

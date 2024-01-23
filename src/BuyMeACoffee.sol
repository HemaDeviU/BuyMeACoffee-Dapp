//SPDX-License-Identifier :MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract BuyMeACoffee {
    //storage variables

    using PriceConverter for uint256;
    address public immutable i_owner;
    uint256 public i_MINIMUM_USD = 5e18;
    address[] public funders;

    mapping(address => uint256) public addressToAmountFunded;

    error NotOwner();

    constructor() {
        i_owner = msg.sender;
    }

    //functions
    function fund() public payable {
        require(
            msg.value.getConversionRate() >= i_MINIMUM_USD,
            "can you please send atleast 10$ worth"
        );
        funders.push(msg.sender);
    }

    function withdraw() public {
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to withdraw");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    modifier OnlyOwner() {
        require(msg.sender != i_owner);
        _;
    }
}

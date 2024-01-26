//SPDX-License-Identifier :MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract BuyMeACoffee {
    //storage variables

    using PriceConverter for uint256;
    address private immutable i_owner;
    uint256 public i_MINIMUM_USD = 5e18;
    address[] private s_funders;

    AggregatorV3Interface private s_priceFeed;

    mapping(address => uint256) private s_addressToAmountFunded;

    error BuyMeACoffee__NotOwner();

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier OnlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

    //functions
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= i_MINIMUM_USD,
            "can you please send atleast 10$ worth"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public OnlyOwner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
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

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getPriceFeed() external view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

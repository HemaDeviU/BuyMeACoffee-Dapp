//SPDC-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {BuyMeACoffee} from "../src/BuyMeACoffee.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployBuyMeACoffee is Script {
    function run() external returns (BuyMeACoffee, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        BuyMeACoffee buyMeC = new BuyMeACoffee(ethUsdPriceFeed);
        vm.stopBroadcast();
        return (buyMeC, helperConfig);
    }
}

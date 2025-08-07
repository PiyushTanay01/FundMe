// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    function getPrice() internal view returns(uint256){
        AggregatorV3Interface priceFeed=AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
        (,int256 price,,,)=priceFeed.latestRoundData();
        //Price of ETH in USD
        //2000.00000000
        return uint256(price*1e10);
    }
    function getConversionRate(uint256 ethAmount) internal view returns(uint256){
        uint256 ethPrice=getPrice();
        uint256 ethAmountInUsd=(ethPrice*ethAmount)/1e18;
        return ethAmountInUsd;
    }
}

error NotOwner();

contract FundMe{
    using PriceConverter for uint256;


    uint256 public constant MINIMUM_USD=5e18;
    address[] public funders;
    mapping(address funder=>uint256 amountFunded) public addressToAmountFunded;
    
    address public immutable i_owner;
    constructor(){
        i_owner=msg.sender;
    }
    function fund() public payable {
        require(msg.value.getConversionRate() >=MINIMUM_USD,"didn't send enough Eth");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]+=msg.value;
    }

    function getVersion() internal view returns (uint256){
        return AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF).version();
    }

    function withdraw() public onlyOwner{
        for(uint256 funderIndex=0;funderIndex<funders.length;funderIndex++){
            address funder=funders[funderIndex];
            addressToAmountFunded[funder]=0;
            //msg.sender=address
            //payable(msg.sender)=payable address;
            // payable(funder).transfer(address(this).balance);
            //this keyword represents whole contract

            //bool sendSuccess=payable(msg.sender).send(address(this).balance);
            //require(sendSuccess,"Send failed");

            //call
        }
        funders=new address[](0);

        (bool callSuccess,)=payable(msg.sender).call{value:address(this).balance}("");// ("")here it asks if you waant to send any function with it we don't want so we leave it empty
        require(callSuccess,"Call failed");
    }
    modifier onlyOwner{
        // require(msg.sender==i_owner,"Must be owner!");
        if(msg.sender!=i_owner) {revert NotOwner();}
        _;

    }

    receive() external payable{
        fund();
    }

    fallback() external payable { 
        fund();
    }
}
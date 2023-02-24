// SPDX-License-Identifier: MIT

import "./exchange.sol";

pragma solidity 0.8.18;

contract factory {
    mapping(address => address) public tokenExchange; // maps exhanges and token contract addresses

    function _createExchange(address _tokenAddress) external returns (address) {
        require(_tokenAddress != address(0), "Invalid Address");
        require(
            tokenExchange[_tokenAddress] == address(0),
            "Exhange already exists"
        );
        
        exchange Exchange = new exchange(_tokenAddress); // deploy a new exhange contract 
        tokenExchange[_tokenAddress] = address(Exchange); // map token to exhange address

        return address(Exchange);
    }
    
    function _getExhange(address _tokenAddress) external view returns (address) {
        address ExchangeAddr = tokenExchange[_tokenAddress];
        return ExchangeAddr;
    }
}
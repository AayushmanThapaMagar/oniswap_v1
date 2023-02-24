// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IExchange{
    function _getExhange(address _tokenAddress) external returns (address);
}

contract exchange is ERC20{ // for liquidity token
    address public TokenAddress;
    address public Factory;

    constructor (address _tokeny) ERC20("oniswap-V1", "ONI-V1"){ // liqudity token name and symbol
        require (_token != address(0));
        TokenAddress = _token;
        Factory = msg.sender; // factory is msg.sender when deployed contract from factory contract
    }

    // @dev Checks if the input or output reserves are zero
    modifier _checkReserves(
        uint256 inputReserve, 
        uint256 outputReserve
    ) {
        require(inputReserve * outputReserve > 0, "Reserves cannot be zero");
        _;
    }

    // @dev Getter function to return the token balance of the exchange
    //@return: The balance the ERC20 balance of the exchange in the token contract.
    function _getReserve() public view returns (uint256) {
        return IERC20(TokenAddress).balanceOf(address(this));
    }


    // @dev Add either ethereum or token as liquidity to the exchange. 
    // @dev Distribute reward tokens according to contribution to the liquidity pool
    // @param _tokenAmount: The amount of token to be added to the liquidity pool.
    // @returns: The amount of Reward tokens awarded to the caller 
    function _addLiquidity(uint256 _tokenAmount) external payable returns(uint256) {
        IERC20 Token = IERC20(TokenAddress);
        uint256 LiquidityToken; // reward tokens for liquidity providers

        if (_getReserve() == 0) { // If the exchange does not have reserve i.e. new exchange
            bool success = Token.transferFrom(msg.sender, address(this), _tokenAmount); // Deposit all the provided tokens to add an arbitrary ratio
            assert(success);

            LiquidityToken = address(this).balance; // we can also use the token reserve instead of eth reserve. Uniswap V1 uses eth
            _mint(msg.sender, LiquidityToken); // mint liquidity token for msg.sender
        } else { // if contract is not new and has reserve
            uint256 ethReserve = address(this).balance - msg.value; // get the balance before Ether liquidity was added
            uint256 tokenReserve = _getReserve(); // The token reserve of the balance
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve; // Maximum ammount of tokens to preserve the ratio
            require(_tokenAmount >= tokenAmount, "Incorrect Ratio");

            bool success = Token.transferFrom(msg.sender, address(this), tokenAmount); // Only deposit the number of tokens required to preserve the ratio
            assert(success);

            LiquidityToken = (totalSupply() * msg.value) / ethReserve; // Calculate the reward token proportionally based on the established ratio and added liquidity
        }

        return LiquidityToken;
    }

    // @dev Take in the liquidity Tokens, calculate the rewards and destroy the tokens
    // @param _withdrawAmount: The amount of liqudity token to withdraw from the exhange
    // @returns Eth + reward and Token + reward amounts
    function _removeLiquidity(uint256 _withdrawAmount) external returns (uint256, uint256) {
        require(_withdrawAmount > 0 , "Invalid withdraw ammount"); 

        uint256 rewardEth = (address(this).balance * _withdrawAmount) / totalSupply(); // eth and bonus depending on liquidity token amount
        uint256 rewardToken = (_getReserve() * _withdrawAmount)/ totalSupply(); // token and bonus depending on liquidity token amount

        _burn(msg.sender, _withdrawAmount); // destory the assoicated liqudity token

        (bool ethSuccess,) = payable(msg.sender).call{value: rewardEth}(""); // send eth
        assert(ethSuccess);

        bool tokenSuccess   = IERC20(TokenAddress).transfer(msg.sender, rewardToken); // transfer token
        assert(tokenSuccess);

        return(rewardEth, rewardToken);
        
    }

    // @dev This function calculates the f
    function _getAmmount(
        uint256 _inputAmmount,
        uint256 _inputReserve,
        uint256 _outputReserve
    ) private pure _checkReserves(_inputReserve, _outputReserve) returns (uint256) {
        uint256 price = _getPrice(_inputAmmount, _inputReserve, _outputReserve);
        uint256 FeesIncluded = (price * 3) / 100; // Price with Fees Included. uniswap is 0.03% fees, same as ours
        return FeesIncluded;
    }


    // @dev Function that 
    function _getPrice(
        uint256 _inputAmmount,
        uint256 _inputReserve,
        uint256 _outputReserve
    ) internal pure _checkReserves(_inputReserve, _outputReserve) returns (uint256) {
        uint256 _outputAmmount = (_inputAmmount * _outputReserve) / (_inputAmmount + _inputReserve); // Uniswap v1 pricing equation. Causes slippage.
        return _outputAmmount;

    }

    // @dev This function is used for token to token swap
    // @param _sellAmount: The ammount of tokens to be sold
    // @param _getAmmount: The minimum amount of tokens to get in return
    // @param _tokenAddress Address to the target token contract
    function _tokenToToken(
        uint256 _sellAmount,
        uint256 _getAmmount,
        address _tokenAddress
    ) public {
        address exhangeAddress = IExchange(Factory)._getExhange(_tokenAddress);
        require(
            exchangeAddress != address(this) && exhangeAddress != address(0),
            "Invalid Exhange Address"
        );

        
    }
}
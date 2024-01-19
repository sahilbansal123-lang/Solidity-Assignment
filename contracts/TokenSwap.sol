// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
    using SafeMath for uint256;

    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public exchangeRate; // 1 Token A = exchangeRate Token B

    event Swap(address indexed sender, uint256 amountA, uint256 amountB);

    constructor(IERC20 _tokenA, IERC20 _tokenB, uint256 _exchangeRate,  address initialOwner) Ownable(initialOwner) {
        require(address(_tokenA) != address(0), "Token A address cannot be zero");
        require(address(_tokenB) != address(0), "Token B address cannot be zero");
        require(_exchangeRate > 0, "Exchange rate must be greater than zero");

        tokenA = _tokenA;
        tokenB = _tokenB;
        exchangeRate = _exchangeRate;
    }

    function swapAToB(uint256 amountA) external {
        require(amountA > 0, "Amount must be greater than zero");

        uint256 amountB = amountA.mul(exchangeRate);
        require(tokenB.balanceOf(address(this)) >= amountB, "Insufficient balance of Token B in the contract");

        // Transfer Token A from the sender to the contract
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Token A transfer failed");

        // Transfer Token B from the contract to the sender
        require(tokenB.transfer(msg.sender, amountB), "Token B transfer failed");

        emit Swap(msg.sender, amountA, amountB);
    }

    function swapBToA(uint256 amountB) external {
        require(amountB > 0, "Amount must be greater than zero");

        uint256 amountA = amountB.div(exchangeRate);
        require(tokenA.balanceOf(address(this)) >= amountA, "Insufficient balance of Token A in the contract");

        // Transfer Token B from the sender to the contract
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Token B transfer failed");

        // Transfer Token A from the contract to the sender
        require(tokenA.transfer(msg.sender, amountA), "Token A transfer failed");

        emit Swap(msg.sender, amountA, amountB);
    }

    // Owner can update the exchange rate
    function setExchangeRate(uint256 newExchangeRate) external onlyOwner {
        require(newExchangeRate > 0, "Exchange rate must be greater than zero");
        exchangeRate = newExchangeRate;
    }

    // Owner can withdraw any remaining balance of tokens from the contract
    function withdrawTokenA(uint256 amount) external onlyOwner {
        require(tokenA.transfer(owner(), amount), "Token A transfer failed");
    }

    // Owner can withdraw any remaining balance of tokens from the contract
    function withdrawTokenB(uint256 amount) external onlyOwner {
        require(tokenB.transfer(owner(), amount), "Token B transfer failed");
    }
}

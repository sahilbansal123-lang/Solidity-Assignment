// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is Ownable {
    using SafeMath for uint256;


    ERC20 public token; // ERC-20 token being sold
    uint256 public presaleCap;
    uint256 public publicSaleCap;
    uint256 public presaleMinContribution;
    uint256 public presaleMaxContribution;
    uint256 public publicSaleMinContribution;
    uint256 public publicSaleMaxContribution;

    mapping(address => uint256) public presaleContributions;
    mapping(address => uint256) public publicSaleContributions;

    enum SalePhase { NotStarted, Presale, PublicSale, Finished }
    SalePhase public currentPhase;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 etherAmount, SalePhase phase);
    event TokensDistributed(address indexed recipient, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);

    modifier onlyPresalePhase() {
        require(currentPhase == SalePhase.Presale, "Not in presale phase");
        _;
    }

    modifier onlyPublicSalePhase() {
        require(currentPhase == SalePhase.PublicSale, "Not in public sale phase");
        _;
    }

    modifier saleNotFinished() {
        require(currentPhase != SalePhase.Finished, "Sale is finished");
        _;
    }

    constructor(
        ERC20 _token,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _presaleMinContribution,
        uint256 _presaleMaxContribution,
        uint256 _publicSaleMinContribution,
        uint256 _publicSaleMaxContribution,
        address initialOwner
    ) Ownable(initialOwner) {
        token = _token;
        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        presaleMinContribution = _presaleMinContribution;
        presaleMaxContribution = _presaleMaxContribution;
        publicSaleMinContribution = _publicSaleMinContribution;
        publicSaleMaxContribution = _publicSaleMaxContribution;
        currentPhase = SalePhase.NotStarted;
    }

    function startPresale() external onlyOwner saleNotFinished {
        currentPhase = SalePhase.Presale;
    }

    function endPresale() external onlyOwner onlyPresalePhase {
        currentPhase = SalePhase.PublicSale;
    }

    function endPublicSale() external onlyOwner onlyPublicSalePhase {
        currentPhase = SalePhase.Finished;
    }

    function contributeToPresale() external payable onlyPresalePhase {
        require(msg.value >= presaleMinContribution, "Below presale minimum contribution");
        require(msg.value <= presaleMaxContribution, "Exceeds presale maximum contribution");
        require(address(this).balance.add(msg.value) <= presaleCap, "Presale cap reached");

        presaleContributions[msg.sender] = presaleContributions[msg.sender].add(msg.value);
        distributeTokens(msg.sender, msg.value);
    }

    function contributeToPublicSale() external payable onlyPublicSalePhase {
        require(msg.value >= publicSaleMinContribution, "Below public sale minimum contribution");
        require(msg.value <= publicSaleMaxContribution, "Exceeds public sale maximum contribution");
        require(address(this).balance.add(msg.value) <= publicSaleCap, "Public sale cap reached");

        publicSaleContributions[msg.sender] = publicSaleContributions[msg.sender].add(msg.value);
        distributeTokens(msg.sender, msg.value);
    }

    function distributeTokens(address recipient, uint256 etherAmount) internal {
        uint256 tokenAmount = etherAmount; // In a real scenario, you may need to calculate the actual token amount based on the token rate
        require(tokenAmount > 0, "Invalid token amount");

        token.transfer(recipient, tokenAmount);
        emit TokensPurchased(recipient, tokenAmount, etherAmount, currentPhase);
    }

    function distributeTokensToAddress(address recipient, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "Invalid token amount");
        token.transfer(recipient, tokenAmount);
        emit TokensDistributed(recipient, tokenAmount);
    }

    function claimRefund() external saleNotFinished {
        uint256 refundAmount;
        if (currentPhase == SalePhase.Presale) {
            refundAmount = presaleContributions[msg.sender];
            require(refundAmount > 0, "No presale contribution to refund");
            presaleContributions[msg.sender] = 0;
        } else if (currentPhase == SalePhase.PublicSale) {
            refundAmount = publicSaleContributions[msg.sender];
            require(refundAmount > 0, "No public sale contribution to refund");
            publicSaleContributions[msg.sender] = 0;
        }

        (bool success, ) = msg.sender.call{value: refundAmount}("");
        require(success, "Refund failed");
        emit RefundClaimed(msg.sender, refundAmount);
    }

    // Fallback function to receive Ether
    receive() external payable {
        revert("Fallback function not allowed");
    }
}

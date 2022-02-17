// SPDX-License-Identifier: MIT

/**
    Taxable.sol

    A contract designed to make a Tradable token that also has
    taxes, which go to development, marketing, and liquidity.
    These taxes are adjustable, and can be split differently
    for buys and sells.

    The constructor requires the instantiator to set a max dev
    fee and a max tax limit, which will enable the developer
    to inform their community that there is a limit to how
    high the token can be taxed.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Tradable.sol";

abstract contract Taxable is Ownable, Tradable {
    using SafeMath for uint256;

    event SetBuyFees(uint256 devAmount, uint256 marketingAmount, uint256 liqAmount); 
    event SetSellFees(uint256 devAmount, uint256 marketingAmount, uint256 liqAmount); 

    uint8 constant BUYTX = 1;
    uint8 constant SELLTX = 2;
    //
    address payable public _devAddress;
    address payable public _marketingAddress;
    //
    uint256 public _liquifyThreshhold;
    bool inSwapAndLiquify;
    //
    uint8 public _maxFees;
    uint8 public _maxDevFee;
    //
    uint8 public _devBuyFee;
    uint8 public _marketingBuyFee;
    uint8 public _liqBuyFee;
    uint8 public _totalBuyFees;
    //
    uint8 public _devSellFee;
    uint8 public _marketingSellFee;
    uint8 public _liqSellFee;
    uint8 public _totalSellFees;
    //
    uint256 private _devTokensCollected;
    uint256 private _marketingTokensCollected;
    uint256 private _liqTokensCollected;
    //
    mapping (address => bool) private _isExcludedFromFees;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(string memory symbol, 
                string memory name, 
                TokenDistribution memory tokenDistribution,
                address payable devAddress,
                address payable marketingAddress,
                uint8 devBuyFee,
                uint8 marketingBuyFee,
                uint8 liqBuyFee,
                uint8 devSellFee,
                uint8 marketingSellFee,
                uint8 liqSellFee,
                uint8 maxFees, 
                uint8 maxDevFee, 
                uint256 liquifyThreshhold)
    Tradable(symbol, name, tokenDistribution) {
        _devAddress = devAddress;
        _marketingAddress = marketingAddress;
        _devBuyFee = devBuyFee;
        _marketingBuyFee = marketingBuyFee;
        _liqBuyFee = liqBuyFee;
        _totalBuyFees = devBuyFee + marketingBuyFee + liqBuyFee;
        _devSellFee = devSellFee;
        _marketingSellFee = marketingSellFee;
        _liqSellFee = liqSellFee;
        _totalSellFees = devSellFee + marketingSellFee + liqSellFee;
        _maxFees = maxFees;
        _maxDevFee = maxDevFee;
        _liquifyThreshhold = liquifyThreshhold;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
    }

    function setMarketingAddress(address payable newMarketingAddress) external onlyOwner() {
        require(newMarketingAddress != _marketingAddress);
        _marketingAddress = newMarketingAddress;
    }

    function setDevAddress(address payable newDevAddress) external onlyOwner() {
        require(newDevAddress != _devAddress);
        _devAddress = newDevAddress;
    }

    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function setBuyFees(uint8 newDevBuyFee, uint8 newMarketingBuyFee, uint8 newLiqBuyFee) external onlyOwner {
        uint8 newTotalBuyFees = newDevBuyFee + newMarketingBuyFee + newLiqBuyFee;
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(newDevBuyFee <= _maxDevFee, "Cannot set dev fee higher than max");
        require(newTotalBuyFees <= _maxFees, "Cannot set total buy fees higher than max");

        _devBuyFee = newDevBuyFee;
        _marketingBuyFee = newMarketingBuyFee;
        _liqBuyFee = newLiqBuyFee;
        _totalBuyFees = newTotalBuyFees;

        emit SetBuyFees(newDevBuyFee, newMarketingBuyFee, newLiqBuyFee);
    }

    function setSellFees(uint8 newDevSellFee, uint8 newMarketingSellFee, uint8 newLiqSellFee) external onlyOwner {
        uint8 newTotalSellFees = newDevSellFee + newMarketingSellFee + newLiqSellFee;
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(newDevSellFee <= _maxDevFee, "Cannot set dev fee higher than max");
        require(newTotalSellFees <= _maxFees, "Cannot set total sell fees higher than max");

        _devSellFee = newDevSellFee;
        _marketingSellFee = newMarketingSellFee;
        _liqSellFee = newLiqSellFee;
        _totalSellFees = newTotalSellFees;

        emit SetSellFees(newDevSellFee, newMarketingSellFee, newLiqSellFee);
    }

    function setLiquifyThreshhold(uint256 newLiquifyThreshhold) external onlyOwner() {
        _liquifyThreshhold = newLiquifyThreshhold;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithTaxes(msg.sender, recipient, amount);
        return true;
    }

    function _transferWithTaxes(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!(_isExcludedFromMaxTx[from] || _isExcludedFromMaxTx[to])) {
            require(amount < _maxTx, "Transfer amount exceeds limit");
        }

        if(
            from != owner() &&              // Not from Owner
            to != owner() &&                // Not to Owner
            !_isExcludedFromMaxBalance[to]  // is excludedFromMaxBalance
        ) {
            require(balanceOf(to).add(amount) <= _maxBalance, "Tx would cause wallet to exceed max balance");
        }
        
        // Sell tokens for funding
        if(
            !inSwapAndLiquify &&                                // Swap is not locked
            balanceOf(address(this)) >= _liquifyThreshhold &&   // liquifyThreshhold is reached
            from != owner() &&                                  // Not from Owner
            to != owner()                                       // Not to Owner
        ) {
            swapCollectedFeesForFunding();
        }

        // Send fees to contract if necessary
        uint8 txType = 0;
        if (from == pair) txType = BUYTX;
        if (to == pair) txType = SELLTX;
        if(
            txType != 0 &&
            !(_isExcludedFromFees[from] || _isExcludedFromFees[to])
            && ((txType == BUYTX && _totalBuyFees > 0)
            || (txType == SELLTX && _totalSellFees > 0))
        ) {
            uint256 feesToContract = calculateTotalFees(amount, txType);
            
            if (feesToContract > 0) {
                amount = amount.sub(feesToContract); 
                transferTokens(from, address(this), feesToContract);
            }
        }

        transferTokens(from, to, amount);
    }

    function calculateTotalFees(uint256 amount, uint8 txType) private returns (uint256) {
        (uint256 devTokens, uint256 marketingTokens, uint256 liqTokens) = (0, 0, 0);

        if (txType == BUYTX) {
            devTokens = amount.mul(_devBuyFee).div(100);
            marketingTokens = amount.mul(_marketingBuyFee).div(100);
            liqTokens = amount.mul(_liqBuyFee).div(100);
        }

        if (txType == SELLTX) {
            devTokens = amount.mul(_devSellFee).div(100);
            marketingTokens = amount.mul(_marketingSellFee).div(100);
            liqTokens = amount.mul(_liqSellFee).div(100);
        }

        _devTokensCollected = _devTokensCollected.add(devTokens);
        _marketingTokensCollected = _marketingTokensCollected.add(marketingTokens);
        _liqTokensCollected = _liqTokensCollected.add(liqTokens);

        return devTokens.add(marketingTokens).add(liqTokens);
    }

    function swapCollectedFeesForFunding() private lockTheSwap {
        uint256 totalCollected = _devTokensCollected.add(_marketingTokensCollected).add(_liqTokensCollected);
        require(totalCollected > 0, "No tokens available to swap");

        uint256 initialFunds = address(this).balance;

        uint256 halfLiq = _liqTokensCollected.div(2);
        uint256 otherHalfLiq = _liqTokensCollected.sub(halfLiq);

        uint256 totalAmountToSwap = _devTokensCollected.add(_marketingTokensCollected).add(halfLiq);

        swapTokensForNative(totalAmountToSwap);

        uint256 newFunds = address(this).balance.sub(initialFunds);

        uint256 liqFunds = newFunds.mul(halfLiq).div(totalAmountToSwap);
        uint256 marketingFunds = newFunds.mul(_marketingTokensCollected).div(totalAmountToSwap);
        uint256 devFunds = newFunds.sub(liqFunds).sub(marketingFunds);

        addLiquidity(otherHalfLiq, liqFunds);
        IERC20(router.WETH()).transfer(marketingAddress, marketingFunds);
        IERC20(router.WETH()).transfer(devAddress, devFunds);

        _devTokensCollected = 0;
        _marketingTokensCollected = 0;
        _liqTokensCollected = 0;
    }

    function swapTokensForNative(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        approve(address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            address(0),
            block.timestamp
        );
    }

    function transferToContract(address sender, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[address(this)] = _balances[address(this)].add(amount);
        emit Transfer(sender, address(this), amount);
    }

    function transferTokens(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}
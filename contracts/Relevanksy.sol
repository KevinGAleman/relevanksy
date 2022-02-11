// SPDX-License-Identifier: MIT

/**
    #RSY

    Relevanksy ($RSY) is the gateway currency to The Relevanksy Collection,
    an exclusive and limited NFT collection designed to provide valuable
    social commentary on the degen crypto space in the form of individual pieces
    of art, sold exclusively on the Relevanksy website.

    $RSY tokenomics:
    Dynamic dev tax, not to exceed 2%
    Dynamic buy/sell taxes for marketing and liquidity,
    not to exceed 12% total (incl dev tax)
 */


pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IBEP20.sol";
import "./IDEXFactory.sol";
import "./IDEXRouter.sol";

contract Relevanksy is Context, IBEP20, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

    event SetBuyFees(uint256 devAmount, uint256 marketingAmount, uint256 liqAmount); 
    event SetSellFees(uint256 devAmount, uint256 marketingAmount, uint256 liqAmount);       
    //
    string private _name = "Relevansky";
    string private _symbol = "RSY";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 10**9 * 10**_decimals;
    // TODO
    address payable public marketingAddress = payable(0x0000000000000000000000000000000000000000);
    address payable public dev1Address = payable(0x2c3DE508c770a44F2902259f1800aA798f25ee06);
    address payable public dev2Address = payable(0x0000000000000000000000000000000000000000);
    address payable public dev3Address = payable(0x0000000000000000000000000000000000000000);
    address public marketingWalletToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    //
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    // 2% Max Wallet
    uint256 public _maxBalance = _totalSupply.mul(2).div(100);
    // 0.5% Max Transaction
    uint256 public _maxTx = _totalSupply.mul(5).div(1000);
    //
    mapping (address => uint256) private _balances;
    //
    mapping (address => mapping (address => uint256)) private _allowances;
    //
    mapping (address => bool) private _isExcludedFromFees;
    //
    mapping (address => bool) private _isExcludedFromMaxBalance;
    //
    mapping (address => bool) private _isExcludedFromMaxTx;
    //
    mapping (address => bool) private _authorizedDevs;
    //
    uint256 private constant _maxFees = 12;
    //
    enum TxType {
        NONE,
        BUY,
        SELL
    }
    //
    uint256 private _devBuyFee;
    uint256 private _marketingBuyFee;
    uint256 private _liqBuyFee;
    uint256 private _totalBuyFees;
    //
    uint256 private _devSellFee;
    uint256 private _marketingSellFee;
    uint256 private _liqSellFee;
    uint256 private _totalSellFees;
    //

    uint256 private _devTokensCollected;
    uint256 private _marketingTokensCollected;
    uint256 private _liqTokensCollected;

    IDEXRouter public router;
    address public pair;

    uint256 private _liquifyThreshhold;
    bool inSwapAndLiquify;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyDevs() {
        require(_authorizedDevs[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    constructor () {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet         // Create a uniswap pair for this new token
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[pair] = true;

        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        _authorizedDevs[address(this)] = true;
        _authorizedDevs[owner()] = true;
        _authorizedDevs[dev1Address] = true;
        _authorizedDevs[dev2Address] = true;
        _authorizedDevs[dev3Address] = true;

        _devBuyFee = 2;
        _marketingBuyFee = 5;
        _liqBuyFee = 5;

        _devSellFee = 2;
        _marketingSellFee = 5;
        _liqSellFee = 5;

        _liquifyThreshhold = 3 * 10**6 * 10**_decimals;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // To recieve BNB from router when swapping
    receive() external payable {}

    // If PancakeSwap sets a new iteration on their router and we need to migrate where LP
    // goes, change it here!
    function setNewPair(address newPairAddress) external onlyOwner {
        require(newPairAddress != pair);
        pair = newPairAddress;
        _isExcludedFromMaxBalance[pair] = true;
    }

    // If PancakeSwap sets a new iteration on their router, change it here!
    function setNewRouter(address newAddress) external onlyOwner {
        require(newAddress != address(router));
        router = IDEXRouter(newAddress);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketingAddress(address payable newMarketingAddress) external onlyOwner() {
        require(newMarketingAddress != marketingAddress);
        marketingAddress = newMarketingAddress;
    }

    function setMaxBalancePercentage(uint256 newMaxBalancePercentage) external onlyOwner() {
        uint256 newMaxBalance = _totalSupply.mul(newMaxBalancePercentage).div(100);

        require(newMaxBalance != _maxBalance, "Cannot set new max balance to the same value as current max balance");
        require(newMaxBalance >= _totalSupply.mul(2).div(1000), "Cannot set max balance lower than 2 percent");

        _maxBalance = newMaxBalance;
    }

    // Set the max transaction percentage in increments of 0.1%.
    function setMaxTxPercentage(uint256 newMaxTxPercentage) external onlyOwner {
        uint256 newMaxTx = _totalSupply.mul(newMaxTxPercentage).div(1000);

        require(newMaxTx != _maxTx, "Cannot set new max transaction to the same value as current max transaction");
        require(newMaxTx >= _totalSupply.mul(5).div(1000), "Cannot set max transaction lower than 0.5 percent");
    }

    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function includeInMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalance[account] = false;
    }

    function excludeFromMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalance[account] = true;
    }

    function includeInMaxTx(address account) public onlyOwner {
        _isExcludedFromMaxTx[account] = false;
    }

    function excludeFromMaxTx(address account) public onlyOwner {
        _isExcludedFromMaxTx[account] = true;
    }

    function addToDevList(address account) public onlyOwner {
        _authorizedDevs[account] = true;
    }

    function removeFromDevList(address account) public onlyOwner {
        _authorizedDevs[account] = false;
    }

    function changeTokenName(string memory newName) external onlyDevs {
        _name = newName;
    }
    
    function changeTokenSymbol(string memory newSymbol) external onlyDevs {
        _symbol = newSymbol;
    }

    function setBuyFees(uint256 newDevBuyFee, uint256 newMarketingBuyFee, uint256 newLiquidityBuyFee) external onlyOwner {
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(newDevBuyFee <= 2, "Cannot set dev fee higher than 2 percent");
        require(newDevBuyFee.add(newMarketingBuyFee).add(newLiquidityBuyFee) <= _maxFees, "Cannot set total buy fees higher than 12 percent");

        _devBuyFee = newDevBuyFee;
        _marketingBuyFee = newMarketingBuyFee;
        _liqBuyFee = newLiquidityBuyFee;
        emit SetBuyFees(_devBuyFee, _marketingBuyFee, _liqBuyFee);
    }

    function setSellFees(uint256 newDevSellFee, uint256 newMarketingSellFee, uint256 newLiquiditySellFee) external onlyOwner {
        require(!inSwapAndLiquify, "inSwapAndLiquify");
        require(newDevSellFee <= 2, "Cannot set dev fee higher than 2 percent");
        require(newDevSellFee.add(newMarketingSellFee).add(newLiquiditySellFee) <= _maxFees, "Cannot set total sell fees higher than 12 percent");

        _devSellFee = newDevSellFee;
        _marketingSellFee = newMarketingSellFee;
        _liqSellFee = newLiquiditySellFee;
        emit SetSellFees(_devSellFee, _marketingSellFee, _liqSellFee);
    }

    function setLiquifyThreshhold(uint256 newLiquifyThreshhold) external onlyOwner() {
        _liquifyThreshhold = newLiquifyThreshhold;
    }

    function calculateTotalFees(uint256 amount, TxType txType) private returns (uint256) {
        (uint256 devTokens, uint256 marketingTokens, uint256 liqTokens) = (0, 0, 0);

        if (txType == TxType.BUY) {
            devTokens = amount.mul(_devBuyFee).div(100);
            marketingTokens = amount.mul(_marketingBuyFee).div(100);
            liqTokens = amount.mul(_liqBuyFee).div(100);
        }

        if (txType == TxType.SELL) {
            devTokens = amount.mul(_devSellFee).div(100);
            marketingTokens = amount.mul(_marketingSellFee).div(100);
            liqTokens = amount.mul(_liqSellFee).div(100);
        }

        _devTokensCollected = _devTokensCollected.add(devTokens);
        _marketingTokensCollected = _marketingTokensCollected.add(marketingTokens);
        _liqTokensCollected = _liqTokensCollected.add(liqTokens);

        return devTokens.add(marketingTokens).add(liqTokens);
    }

    function _transfer(address from, address to, uint256 amount) private {
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
        TxType txType = TxType.NONE;
        if (from == pair) txType = TxType.BUY;
        if (to == pair) txType = TxType.SELL;
        if(
            txType != TxType.NONE &&
            !(_isExcludedFromFees[from] || _isExcludedFromFees[to])
            && ((txType == TxType.BUY && _totalBuyFees > 0)
            || (txType == TxType.SELL && _totalSellFees > 0))
        ) {
            uint256 feesToContract = calculateTotalFees(amount, txType);
            
            if (feesToContract > 0) {
                amount = amount.sub(feesToContract); 
                transferToken(from, address(this), feesToContract);
            }
        }

        transferToken(from, to, amount);
    }
    
    function swapCollectedFeesForFunding() private lockTheSwap {
        uint256 initialBNB = address(this).balance;

        uint256 halfLiq = _liqTokensCollected.div(2);
        uint256 otherHalfLiq = _liqTokensCollected.sub(halfLiq);

        uint256 totalAmountToSwap = _devTokensCollected.add(_marketingTokensCollected).add(halfLiq);

        swapTokensForBNB(totalAmountToSwap);

        uint256 newBNB = address(this).balance.sub(initialBNB);

        uint256 liqBNB = newBNB.mul(halfLiq).div(totalAmountToSwap);
        uint256 marketingBNB = newBNB.mul(_marketingTokensCollected).div(totalAmountToSwap);
        uint256 devBNB = newBNB.sub(liqBNB).sub(marketingBNB);

        addLiquidity(otherHalfLiq, liqBNB);
        IBEP20(WBNB).transfer(marketingAddress, marketingBNB);
        sendDevFees(devBNB);

        _devTokensCollected = 0;
        _marketingTokensCollected = 0;
        _liqTokensCollected = 0;
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            address(0),
            block.timestamp
        );
    }

    function sendDevFees(uint256 totalBNB) private {
        // 40% to two devs, 20% to the other
        uint256 devBNB = totalBNB.mul(4).div(10);
        uint256 dev3BNB = totalBNB.sub(devBNB).sub(devBNB);
        IBEP20(WBNB).transfer(dev1Address, devBNB);
        IBEP20(WBNB).transfer(dev2Address, devBNB);
        IBEP20(WBNB).transfer(dev3Address, dev3BNB);
    }

    function transferToken(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}
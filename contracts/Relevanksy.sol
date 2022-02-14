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
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DevOwnable.sol";
import "./IBEP20.sol";
import "./Taxable.sol";
import "./Tradable.sol";

contract Relevanksy is Context, Ownable, DevOwnable, Taxable {
	using SafeMath for uint256;
	using Address for address;

    string private _RSYname = "Relevansky";
    string private _RSYsymbol = "RSY";
    // 9 Decimals
    uint8 private _RSYdecimals = 9;
    // 1B Supply
    uint256 private _RSYtotalSupply = 10**9 * 10**_RSYdecimals;
    // 2% Max Wallet
    uint256 private _RSYmaxBalance = _RSYtotalSupply.mul(2).div(100);
    // 0.5% Max Transaction
    uint256 private _RSYmaxTx = _RSYtotalSupply.mul(5).div(1000);
    // 12% Max Fees
    uint8 private _RSYmaxFees = 12;
    // 2% Max Dev Fee
    uint8 private _RSYmaxDevFee = 2;
    // Contract sell at 3M tokens
    uint256 private _RSYliquifyThreshhold = 3 * 10**6 * 10**_RSYdecimals;
    TokenDistribution private _RSYtokenDistribution = 
        TokenDistribution({ totalSupply: _RSYtotalSupply, decimals: _RSYdecimals, maxBalance: _RSYmaxBalance, maxTx: _RSYmaxTx });
    BuyFees private _RSYbuyFees = 
        BuyFees({ devFee: 2, marketingFee: 5, liqFee: 5, total: 12 });
    SellFees private _RSYsellFees =
        SellFees({ devFee: 2, marketingFee: 5, liqFee: 5, total: 12 });

    constructor () 
    Taxable(_RSYsymbol, _RSYname, _RSYtokenDistribution, _RSYbuyFees, _RSYsellFees, _RSYmaxFees, _RSYmaxDevFee, _RSYliquifyThreshhold) {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function changeTokenName(string memory newName) external onlyDevs {
        _name = newName;
    }
    
    function changeTokenSymbol(string memory newSymbol) external onlyDevs {
        _symbol = newSymbol;
    }
}
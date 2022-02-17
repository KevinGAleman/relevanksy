// SPDX-License-Identifier: MIT

/**
    #R

    Relevanksy ($R) is the gateway currency to The Relevanksy Collection,
    an exclusive and limited NFT collection designed to provide valuable
    social commentary on the degen crypto space in the form of individual pieces
    of art, sold exclusively on the Relevanksy website.

    $R tokenomics:
    Dynamic dev tax, not to exceed 2%
    Dynamic buy/sell taxes for marketing and liquidity,
    not to exceed 12% total (incl dev tax)
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Taxable.sol";
import "./Tradable.sol";

contract Relevanksy is Context, Ownable, Taxable {
	using SafeMath for uint256;
	using Address for address;

    string private _Rname = "Relevanksy";
    string private _Rsymbol = "RSY";
    // 9 Decimals
    uint8 private _Rdecimals = 9;
    // 1B Supply
    uint256 private _RtotalSupply = 10**9 * 10**_Rdecimals;
    // 2% Max Wallet
    uint256 private _RmaxBalance = _RtotalSupply.mul(2).div(100);
    // 0.5% Max Transaction
    uint256 private _RmaxTx = _RtotalSupply.mul(5).div(1000);
    // 12% Max Fees
    uint8 private _RmaxFees = 12;
    // 2% Max Dev Fee
    uint8 private _RmaxDevFee = 2;
    // Contract sell at 3M tokens
    uint256 private _RliquifyThreshhold = 3 * 10**6 * 10**_Rdecimals;
    TokenDistribution private _RtokenDistribution = 
        TokenDistribution({ totalSupply: _RtotalSupply, decimals: _Rdecimals, maxBalance: _RmaxBalance, maxTx: _RmaxTx });
    // Buy and sell fees will start at 99% to prevent bots/snipers at launch, 
    // but will not be allowed to be set this high ever again.
    uint8 private _RdevBuyFee = 2;
    uint8 private _RmarketingBuyFee = 31;
    uint8 private _RliqBuyFee = 66;
    uint8 private _RdevSellFee = 2;
    uint8 private _RmarketingSellFee = 31;
    uint8 private _RliqSellFee = 66;
    // TODO
    address payable _RdevAddress = address(0x0);
    address payable _RmarketingAddress = address(0x0);

    constructor () 
    Taxable(_Rsymbol, _Rname, _RtokenDistribution, _RdevAddress, _RmarketingAddress, _RdevBuyFee, _RmarketingBuyFee, 
            _RliqBuyFee, _RdevSellFee, _RmarketingSellFee, _RliqSellFee, _RmaxFees, _RmaxDevFee, _RliquifyThreshhold) {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
}
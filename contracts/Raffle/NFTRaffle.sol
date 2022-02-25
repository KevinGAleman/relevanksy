// SPDX-License-Identifier: MIT

/**
    RSY Raffle

    This contract provides the functionality for raffles to take place
    that will distribute the created Relevanksy NFTs to its winners.

    This contract uses Chainlink VRF to guarantee random winners are selected.
 */

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../NFT/IRaffleable.sol";

contract NFTRaffle is VRFConsumerBase, Ownable {
    using Address for address;
    using SafeMath for uint256;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;

    // TODO set who gets the platform fees
    address public _platformFeeReceiver = address(0x0);
    uint8 constant _platformFeePercentage = 10;

    // NFT Creator
    address public _creator;

    // Raffle currency and raffle prize
    IERC20 public _raffleCurrency;
    IRaffleable public _rafflePrize;

    // Raffle Details
    uint256 public _numPrizes;
    uint256 public _tokensPerEntry;
    uint256 public _raffleStartTime;
    uint256 public _raffleEndTime;

    bool public _raffleFinished = true;

    // Tracking the raffle
    address[] public _entries;
    address[] public _winners;
        
    constructor(address raffleCurrencyAddress, address rafflePrizeAddress, uint256 numPrizes, uint256 tokensPerEntry, uint numDays) 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)

        _raffleCurrency = IERC20(raffleCurrencyAddress);
        _rafflePrize = IRaffleable(rafflePrizeAddress);
        _numPrizes = numPrizes;
        _tokensPerEntry = tokensPerEntry;
        _raffleStartTime = block.timestamp;
        _raffleEndTime = block.timestamp + (numDays * 1 days);
    }

    // To recieve BNB
    receive() external payable {}

    // If you need to withdraw BNB, tokens, or anything else that's been sent to the contract
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

    // TODO implement scheduling this call based on raffleEndTime
    function endRaffle() external onlyOwner {
        chooseWinners();
    }

    function enterRaffle(uint256 numEntries) external {
        require(!_raffleFinished, "This raffle has completed");

        // Implement token transfer here
        uint256 numTokensToEnter = numEntries.mul(_tokensPerEntry);
        _raffleCurrency.approve(address(this), numTokensToEnter);
        _raffleCurrency.transferFrom(_msgSender(), address(this), numTokensToEnter);
        
        // Give this address a spot in the entries list for every ticket they purchased
        for (uint256 i = 0; i < numEntries; i++) {
            _entries.push(_msgSender());
        }
    }

    function chooseWinners() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 randomResult = randomness % _entries.length;
        
        // Get random numbers equivalent to the number of prizes
        // using the first random number as a seed
        for (uint256 i = 0; i < _numPrizes; i++) {
            uint256 winningID = uint256(keccak256(abi.encode(randomResult, i)));
            _winners.push(_entries[winningID]);
        }

        // Tell the raffle prize contract who is allowed to mint this batch of prizes.
        _rafflePrize.setNewMinters(_winners);

        distributeProceeds();

        _raffleFinished = true;
    }

    function distributeProceeds() internal {
        uint256 feeToPlatform = _raffleCurrency.balanceOf(address(this)).mul(_platformFeePercentage).div(100);
        uint256 feeToCreator = _raffleCurrency.balanceOf(address(this)).sub(feeToPlatform);

        _raffleCurrency.transfer(_platformFeeReceiver, feeToPlatform);
        _raffleCurrency.transfer(_creator, feeToCreator);
    }
}
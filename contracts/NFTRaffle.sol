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
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTRaffle is VRFConsumerBase, Ownable {
    using Address for address;
    using SafeMath for uint256;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public numPrizes;
    uint256 public tokensPerEntry;
    uint256 public raffleEndBlock;

    uint256 public totalEntries;
    bool public raffleFinished = false;
    address[] public entries;
    mapping (address => uint256) public participantsEntries;
    address[] public winners;
        
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)

    }

    // To recieve BNB
    receive() external payable {}

    function setupRaffle() external onlyOwner {

    }

    function extendRaffle() external onlyOwner {

    }

    function enterRaffle(uint256 numEntries) external {
        require(!raffleFinished, "This raffle has completed");

        // Implement token transfer here

        participantsEntries[msg.sender].add(numEntries);
    }

    function chooseWinners() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 randomResult = randomness % entries.length;
        
        // Get random numbers equivalent to the number of prizes
        // using the first random number as a seed
        for (uint256 i = 0; i < numPrizes; i++) {
            uint256 winningID = uint256(keccak256(abi.encode(randomResult, i)));
            winners.push(entries[winningID]);
        }

        distributePrizes();

        raffleFinished = true;
    }

    function distributePrizes() private {

    }

    // TODO
    // function withdrawLink() external onlyOwner {} - Implement a withdraw function to avoid locking your LINK in the contract
}
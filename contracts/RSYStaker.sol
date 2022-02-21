// SPDX-License-Identifier: MIT

/**
    RSY Staker

    This contract provides the functionality for the Relevanksy token to be staked,
    and for stakeholders to have the opportunity to harvest their staked rewards.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RSYStaker is Ownable {
    struct Stake {
        address user;
        uint256 amount;
        uint64 sinceBlock;
        uint64 untilBlock;
    }

    Stake[] private stakes;
    uint256 constant public percentPerBlock = 1; // TODO use more granular units

    event LogPayout(address user, uint256 stakedAmount, uint256 rewardAmount);

    // If you need to withdraw BNB, tokens, or anything else that's been sent to the contract
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

    function stake(uint256 _amount) external returns (uint256 stakeId) {
        stakes.push(Stake(msg.sender, _amount, uint64(block.timestamp), 0));
        return stakes.length - 1;
    }

    function unstake (uint256 _id) external {
        require(stakes[_id].user == msg.sender, 'Not your stake');
        require(stakes[_id].untilBlock == 0, 'Already unstaked');

        stakes[_id].untilBlock = uint64(block.timestamp);

        uint256 stakedForBlocks = (block.timestamp - stakes[_id].sinceBlock);
        uint256 rewardAmount = stakes[_id].amount * stakedForBlocks * percentPerBlock / 100;

        emit LogPayout(stakes[_id].user, stakes[_id].amount, rewardAmount);
        // TODO actual payout
    }
    
    function viewUserTotalUnclaimedRewards(address _user) external view returns (uint256) {
        uint256 totalUnclaimedRewards;

        for(uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].user == _user && stakes[i].untilBlock == 0) {
                uint256 stakedForBlocks = (block.timestamp - stakes[i].sinceBlock);
                uint256 rewardAmount = stakedForBlocks * percentPerBlock / 100;
                totalUnclaimedRewards += rewardAmount;
            }
        }

        return totalUnclaimedRewards;
    }
}
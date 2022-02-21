// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "../Utils/Owned.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipient is Owned {
    address public _rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == _rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address rewardsDistribution) external onlyOwner {
        _rewardsDistribution = rewardsDistribution;
    }
}

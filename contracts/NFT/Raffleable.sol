//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRaffleable.sol";

abstract contract Raffleable is IRaffleable, Ownable {
    address[] _allowListed;
    address private _raffleContract;

    constructor() {}

    function _setRaffleContract(address raffleContract) external onlyOwner {
        _raffleContract = raffleContract;
    }

    function setNewMinters(address[] calldata newMinters) external override onlyRaffleManager {
        delete _allowListed;

        _allowListed = newMinters;
    }

    function isAllowListed() internal view returns (bool, int) {
        bool isUserInAllowList = false;
        int index = -1;
    
        for (uint i=0; i < _allowListed.length; i++) {
            if (_msgSender() == _allowListed[i]) {
                isUserInAllowList = true;
                index = int(i);
                break;
            }
        }

        return (isUserInAllowList, index);
    }

    modifier manageRaffleEntry() {
        (bool isUserAllowListed, int index) = isAllowListed();

        require(isUserAllowListed, "Minter must be allowlisted!");
        require(index >= 0, "Can't find user in allowlist");

        _;

        // Remove user from the allow list once they've minted
        _allowListed[uint256(index)] = address(0x0);
    }

    modifier onlyRaffleManager() {
        require (_msgSender() == _raffleContract || _msgSender() == owner(), "Only the raffle contract or owner can set the winners of mint allowList");
        _;
    }
}
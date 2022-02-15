// SPDX-License-Identifier: MIT

/**
    DevOwnable.sol

    A contract designed to add the `onlyDevs` modifier,
    which will allow a set of addresses to run particular
    functions on the contract, and these addresses can
    be added or removed in case of a change in dev team.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";


abstract contract DevOwnable is Context, Ownable {
	using Address for address;

    mapping (address => bool) public _authorizedDevs;

    constructor() {
        _authorizedDevs[owner()] = true;
        _authorizedDevs[address(this)] = true;
    }

    modifier onlyDevs() {
        require(_authorizedDevs[_msgSender()], "Error: caller does not have dev privileges");
        _;
    }

    function addToAuthorizedDevs(address account) public onlyOwner {
        _authorizedDevs[account] = true;
    }

    function removeFromAuthorizedDevs(address account) public onlyOwner {
        _authorizedDevs[account] = false;
    }
}
// SPDX-License-Identifier: MIT
// ICO contract/s originally created for Stellaverse. 

import "./ICO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.7;

contract Factory is Ownable { 

    address[] public icoList;

    event ICOcreated(address indexed ICOaddress, uint256 timestamp);

    function createICO(
        address admin,
        address projectOwner, 
        address token, 
        uint256 tokensPerAtto, 
        uint256 hardCap, 
        uint256 saleStartTimestamp, 
        uint256 saleEndTimestamp, 
        bool weighted
    ) external onlyOwner returns (address newICO) {
        // Deploy new ICO contract
        ICO ico = new ICO(
            admin,
            projectOwner, 
            token, 
            tokensPerAtto, 
            hardCap, 
            saleStartTimestamp, 
            saleEndTimestamp, 
            weighted
        );

        newICO = address(ico);

        icoList.push(newICO);

        emit ICOcreated(newICO, block.timestamp);
    }

    function getICOs() external view returns (address[] memory){
        return icoList;
    }

}

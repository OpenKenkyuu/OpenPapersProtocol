// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OpenPaper.sol";

contract OpenPaperFactory {
    address[] public deployedPapers;

    function createPaper(string memory title, address[] memory authors, string memory contentURI, uint8 paperPrice)
        public
    {
        address newPaper = address(new OpenPaper(title, authors, contentURI, paperPrice));
        deployedPapers.push(newPaper);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OpenPaper.sol";

contract OpenPaperFactory {
    address[] public deployedPapers;
    address[] public missingSignatures;

    function createPaper(
        string memory title,
        address[] memory authors,
        string[] memory categories,
        uint8 paperPrice,
        string memory contentURI
    )
        public
        returns (address)
    {
        address newPaper = address(new OpenPaper(title, authors, categories, paperPrice, contentURI));
        deployedPapers.push(newPaper);
        for (uint8 i = 0; i < authors.length; i++) {
            missingSignatures.push(authors[i]);
        }
        return newPaper;
    }

    function removeMissingSignature(address author) public {
        for (uint8 i = 0; i < missingSignatures.length; i++) {
            if (missingSignatures[i] == author) {
                delete missingSignatures[i];
                missingSignatures[i] = missingSignatures[missingSignatures.length - 1];
                missingSignatures.pop();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact me@mariodev.xyz
contract OpenPaper is ERC721, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public title;
    string private contentURI;
    address[] public authors;

    mapping(address => bool) public signed;
    bool public paperCreated = false;
    uint256 public buyers = _tokenIdCounter.current();
    uint256 public upvotes = 0;
    uint256 public paperPrice;

    constructor(string memory _title, address[] memory _authors, string memory _contentURI, uint256 _paperPrice)
        ERC721("OpenPaper", "OPP")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        if (_authors.length != 0) {
            for (uint256 i = 0; i < _authors.length; i++) {
                _grantRole(DEFAULT_ADMIN_ROLE, _authors[i]);
            }
        }

        title = _title;
        authors = _authors;
        contentURI = _contentURI;
        paperPrice = _paperPrice;
    }

    function addAdmin(address _newadmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, _newadmin);
    }

    function sign() public onlyRole(DEFAULT_ADMIN_ROLE) {
        signed[msg.sender] = true;
    }

    function createPaper() public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        // Only mint the token if all authors have signed
        for (uint256 i = 0; i < authors.length; i++) {
            require(signed[authors[i]], "Not all authors have signed");
        }

        // If all authors have signed, mint the token to all authors
        for (uint256 i = 0; i < authors.length; i++) {
            _safeMint(authors[i], _tokenIdCounter.current());
            _tokenIdCounter.increment();
            paperCreated = true;
        }
        return paperCreated;
    }

    function buyPaper(address to) public payable {
        require(createPaper(), "Paper not created");
        require(msg.value >= paperPrice, "Not enough ETH sent");
        _safeMint(to, _tokenIdCounter.current());
    }

    function upvotePaper() public {
        upvotes++;
    }

    function withdrawFunds() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        uint256 amount = balance / authors.length;
        for (uint256 i = 0; i < authors.length; i++) {
            payable(authors[i]).transfer(amount);
            (bool tranferTx,) = authors[i].call{value: amount}("");
            if (!tranferTx) {
                revert("Transfer failed");
            }
        }
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

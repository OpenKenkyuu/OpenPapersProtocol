// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// Errors
error NotAllAuthorsSigned(string message);
error PaperNotCreated(string message);
error NotEnoughETHSent(string message);
error TransferFailed(string message);
error YouAlreadyVoted(string message);

/// @custom:security-contact me@mariodev.xyz
contract OpenPaper is ERC721, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    /// Events
    event PaperCreated(address[] indexed authors);
    event PaperBought(address indexed buyer, uint256 indexed tokenId);
    event PaperUpvoted(address indexed voter, uint256 indexed tokenId);

    string public title;
    address[] public authors;
    string[] public categories;
    uint8 public paperPrice;

    string private contentURI;

    mapping(address => bool) public signed;
    mapping(address => bool) public voted;
    bool public paperCreated = false;
    uint256 public buyers = _tokenIdCounter.current();
    uint32 public upvotes = 0;

    constructor(
        string memory _title,
        address[] memory _authors,
        string[] memory _categories,
        uint8 _paperPrice,
        string memory _contentURI
    )
        ERC721("OpenPaper", "OPP")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        if (_authors.length != 0) {
            for (uint8 i = 0; i < _authors.length; i++) {
                _grantRole(DEFAULT_ADMIN_ROLE, _authors[i]);
            }
        }

        title = _title;
        authors = _authors;
        categories = _categories;
        paperPrice = _paperPrice;
        contentURI = _contentURI;
    }

    function addAdmin(address _newadmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, _newadmin);
        authors.push(_newadmin);
    }

    function sign() public onlyRole(DEFAULT_ADMIN_ROLE) {
        signed[msg.sender] = true;
    }

    function createPaper() public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        // Only mint the token if all authors have signed
        for (uint8 i = 0; i < authors.length; i++) {
            if (!signed[authors[i]]) {
                revert NotAllAuthorsSigned("Not all authors have signed");
            }
        }

        for (uint8 i = 0; i < authors.length; i++) {
            if (balanceOf(authors[i]) == 0) {
                _safeMint(authors[i], _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
        paperCreated = true;
        emit PaperCreated(authors);
        return paperCreated;
    }

    function buyPaper() public payable {
        if (!paperCreated) {
            revert PaperNotCreated("Paper not created");
        } else if (msg.value < paperPrice) {
            revert NotEnoughETHSent("Not enough ETH sent");
        } else {
            _safeMint(msg.sender, _tokenIdCounter.current());
            emit PaperBought(msg.sender, _tokenIdCounter.current());
        }
    }

    function upvotePaper() public {
        if (voted[msg.sender]) {
            revert YouAlreadyVoted("You already voted");
        } else {
            voted[msg.sender] = true;
            upvotes++;
            emit PaperUpvoted(msg.sender, _tokenIdCounter.current());
        }
    }

    function withdrawFunds() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        uint256 amount = balance / authors.length;

        for (uint8 i = 0; i < authors.length; i++) {
            (bool tranferTx,) = authors[i].call{value: amount}("");
            if (!tranferTx) {
                revert TransferFailed("Transfer failed");
            }
        }
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract SkaterBirds is ERC721A, ERC2981 {
    using Strings for uint256;

    struct Slot0 {
        bool isRevealed;
        uint8 mintPhase;
        uint16 presaleSupply;
        string baseURI;
        string unrevealedURI;
        bytes32 boardedList;
        bytes32 doubleList;
        bytes32 premintList;
        uint256 publicMintPrice;
        uint256 presaleMintPrice;
        uint256 amountHeld;
        address owner;
    }

    struct Slot1 {
        bool hasTeamMinted;
        uint16 totalSupply;
        uint16 totalMinted;
        mapping(address => uint8) publicMintCounter;
        mapping(address => uint8) presaleMintCounter;
    }

    Slot0 public slot0;
    Slot1 public slot1;

    constructor() ERC721A("Skater Birds", "SB") {
        slot1.totalSupply = 3333;
        slot1.totalMinted = 0;
        slot0.presaleSupply = 2400;
        slot0.mintPhase = 0;
        slot0.isRevealed = false;
        slot1.hasTeamMinted = false;
        slot0
            .unrevealedURI = "https://skatebirds.s3.us-west-1.amazonaws.com/prereveal/prereveal.json";
        slot0
            .boardedList = 0x498ddd0cc1b84779a5f257ecaaae05c78fae21c2563250f9913e8bb44014fadf;
        slot0
            .doubleList = 0x25f8f5b9aca076b04c7a57e4d697f97ae3acb66908dfc9efebcfc6526137fa2b;
        slot0
            .premintList = 0xd2eb7eaf42d6369cd1ec1f09414c5260594c1f7ef7ad1188a6e12d947cb1824a;
        slot0.owner = msg.sender;
        slot0.publicMintPrice = 0.125 ether;
        slot0.presaleMintPrice = 0.088 ether;
        _setDefaultRoyalty(0xB9B7900eeC853a0Bd36016ec3fF590af67247828, 550);
    }

    modifier isPresale() {
        require((slot0.mintPhase == 1 || slot0.mintPhase == 2), "Not Presale");
        _;
    }

    modifier isRaffleMint() {
        require(slot0.mintPhase == 2, "Not Raffle");
        _;
    }

    modifier isPublicSale() {
        require(slot0.mintPhase == 3, "Not Minting");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == slot0.owner, "Not Owner");
        _;
    }

    /**
    @notice uint controls list to update - 0: boarded, 1: double, 2: premint
     */
    function setAllowList(bytes32 _root, uint8 list) external onlyOwner {
        if (list == 0) {
            slot0.boardedList = _root;
        }
        if (list == 1) {
            slot0.doubleList = _root;
        }
        if (list == 2) {
            slot0.premintList = _root;
        }
    }

    function setPhase(uint8 _newPhase) external onlyOwner {
        require(_newPhase < 4, "not valid phase");
        slot0.mintPhase = _newPhase;
    }

    function setReveal(bool _newVal) external onlyOwner {
        slot0.isRevealed = _newVal;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        slot0.baseURI = _newURI;
    }

    function setUnrevealedURI(string calldata _newURI) external onlyOwner {
        slot0.unrevealedURI = _newURI;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        slot0.owner = _newOwner;
    }

    function updateRoyalty(address _newRecipient, uint96 _newFee)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_newRecipient, _newFee);
    }

    function teamMint() external onlyOwner {
        require(!slot1.hasTeamMinted, "already called");
        slot1.totalMinted += 33;
        slot1.hasTeamMinted = true;
        _safeMint(msg.sender, 33);
    }

    function publicMint(uint8 quantity) external payable isPublicSale {
        uint256 value = msg.value;
        address minter = msg.sender;
        require(value >= (slot0.publicMintPrice * quantity), "Not Enough ETH");
        require(
            slot1.publicMintCounter[minter] + quantity <= 3,
            "Too Many Mints"
        );
        require(
            slot1.totalMinted + quantity <= slot1.totalSupply,
            "Overflow ID"
        );
        slot1.publicMintCounter[minter] += quantity;
        slot1.totalMinted += quantity;
        slot0.amountHeld += value;
        _safeMint(minter, quantity);
    }

    function boardedMint(uint8 _quantity, bytes32[] memory _merkleProof)
        external
        payable
        isPresale
    {
        uint256 value = msg.value;
        address minter = msg.sender;
        if (slot1.hasTeamMinted) {
            require(
                slot1.totalMinted + _quantity <= (slot0.presaleSupply + 33),
                "Out of wl"
            );
        }
        if (!slot1.hasTeamMinted) {
            require(
                slot1.totalMinted + _quantity <= slot0.presaleSupply,
                "Out of wl"
            );
        }
        bytes32 leaf = keccak256(abi.encodePacked(minter));
        bool isBoarded = MerkleProof.verify(
            _merkleProof,
            slot0.boardedList,
            leaf
        );
        require(isBoarded, "No wl");
        require(_quantity <= 1, "Too many mints");
        require(
            slot1.presaleMintCounter[minter] + _quantity <= 1,
            "Too many mints"
        );
        slot1.presaleMintCounter[minter] += _quantity;
        slot1.totalMinted += _quantity;
        require(value >= slot0.presaleMintPrice * _quantity, "wrong price");
        slot0.amountHeld += value;
        _safeMint(minter, _quantity);
    }

    function doubleBoardedMint(uint8 _quantity, bytes32[] memory _merkleProof)
        external
        payable
        isPresale
    {
        uint256 value = msg.value;
        address minter = msg.sender;
        if (slot1.hasTeamMinted) {
            require(
                slot1.totalMinted + _quantity <= (slot0.presaleSupply + 33),
                "Out of wl"
            );
        }
        if (!slot1.hasTeamMinted) {
            require(
                slot1.totalMinted + _quantity <= slot0.presaleSupply,
                "Out of wl"
            );
        }
        bytes32 leaf = keccak256(abi.encodePacked(minter));
        bool isDouble = MerkleProof.verify(
            _merkleProof,
            slot0.doubleList,
            leaf
        );
        require(isDouble, "no wl");
        require(_quantity <= 2, "Too many mints");
        require(
            slot1.presaleMintCounter[minter] + _quantity <= 2,
            "Too many mints"
        );
        slot1.presaleMintCounter[minter] += _quantity;
        slot1.totalMinted += _quantity;
        require(value >= slot0.presaleMintPrice * _quantity, "wrong price");
        slot0.amountHeld += value;
        _safeMint(minter, _quantity);
    }

    function preMint(uint8 _quantity, bytes32[] memory _merkleProof)
        external
        payable
        isRaffleMint
    {
        uint256 value = msg.value;
        address minter = msg.sender;
        require(_quantity <= 2, "Too many mints");
        require(
            slot1.presaleMintCounter[minter] + _quantity <= 2,
            "Too many mints"
        );
        bytes32 leaf = keccak256(abi.encodePacked(minter));
        bool ispreMint = MerkleProof.verify(
            _merkleProof,
            slot0.premintList,
            leaf
        );
        require(ispreMint, "No wl");
        slot1.presaleMintCounter[minter] += _quantity;
        slot1.totalMinted += _quantity;
        require(value >= _quantity * slot0.publicMintPrice, "wrong price");
        slot0.amountHeld += value;
        _safeMint(minter, _quantity);
    }

    function tokenURI(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenID <= slot1.totalMinted, "Unreal Token");
        if (slot0.isRevealed) {
            return string(abi.encodePacked(slot0.baseURI, _tokenID.toString()));
        } else {
            return string(abi.encodePacked(slot0.unrevealedURI));
        }
    }

    function withdraw() external payable onlyOwner {
        address withdrawTarget = msg.sender;
        uint256 amountToSend = slot0.amountHeld;
        slot0.amountHeld = 0;
        payable(withdrawTarget).transfer(amountToSend);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC721A).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery is VRFConsumerBase , Ownable , ERC721URIStorage , ReentrancyGuard {

     using ECDSA for bytes32;

    // AIFT  IERC721 Contract address 
     IERC721 public nftContract;
     IERC20 public token;
    
    // =======       Chainlink variables       ============== 
    // The amount of LINK to send with the request
    uint256 public fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;

    // variables
    uint256 public constant  maxDeadline = 30 days;
    uint256 public commissionRate = 20; // out of 100


    // Constructor inherits VRFConsumerBase
    constructor(address vrfCoordinator, address linkToken, bytes32 vrfKeyHash, uint256 vrfFee , address _nftcontractAddress , address _tokencontractAddress) VRFConsumerBase(vrfCoordinator, linkToken) ERC721("AIFT Lottery Tikcet ", "LOT") {   
        keyHash = vrfKeyHash;
        token = IERC20(_tokencontractAddress);
        fee = vrfFee;
        nftContract = IERC721(_nftcontractAddress);
    }


    // =========         Events      ====================
    event LotterCreated(uint256 lotteryId , uint256 nftId , address lotteryCreator , uint256 timeAtWhichCreatedm , uint256 deadline , uint256 eachTikcetPrice);
    event TicketPurchased(address indexed buyer, uint256 lotteryId);
    event WinnerSelected(uint256 lotteryId, address winner);




    // =======       Lottery variables       ==============

    using Counters for Counters.Counter;
    Counters.Counter public  _lotteryId;
    Counters.Counter public  _ticketId;

    struct Lottery {
        uint256 lotteryId;
        uint256 nftId;
        uint256 startingTime;
        uint256 deadline;
        uint256 eachTikcetPrice;
        string nfTName;
        address[] participants;
        address winner;
        bool isLotteryActive;
        address creator;
        bool nftTransferred ;
        uint256 totalRaised;
    }

    struct LotteryTicket{
        uint256 lotteryId;
        uint256 ticketId;
        string uri;
        address owner;
    }


    mapping(uint256 => Lottery) public lotteries;
    mapping(address => uint256[]) public addressToTicketIds;
    mapping(address => uint256[]) public addressToLotteryIds;
    mapping(uint256 => address) public ticketIdToOwner;
    mapping(uint256 => mapping(address => uint256)) public lotteryIdToPlayerToTicketId;

    // New mapping
    mapping(bytes32 => bool) executed;

    // Lottery Ticket Id
    mapping(uint256 => LotteryTicket) public lotteryTickets;
    mapping(uint256 => address ) public lotteryTicketIdToOwner;

    mapping(bytes32 => uint256) public requestIdToLotteryId;





    // =========      Lottery functions       ==============
    
    /**
     * @param nftId Id of NFt User want to put in lottery
     * @param deadline deadline till lottery will be active 
     * @param eachTikcetPrice price of each ticket 
     * @param nfTName name of that particular NFT
     */
    function startLottery(uint256 nftId  , uint256 deadline , uint256 eachTikcetPrice , string memory nfTName , 
    address user ) public  nonReentrant  {
        // require checks 
        require(nftContract.ownerOf(nftId) == user  , "You are not the owner of this NFT");
        require(eachTikcetPrice > 0, "Price Should be greater than 0");
        require(deadline > block.timestamp , "Deadline should be greater than current time");
        require(deadline <= block.timestamp + maxDeadline , "Deadline should be less than 30 days");

        // 1. transfer the nft to the contract
        nftContract.safeTransferFrom(user, address(this), nftId);

        // 2. create the lottery
        _lotteryId.increment();
        uint256 lotteryId = _lotteryId.current();
        Lottery memory newLottery = Lottery(lotteryId , nftId  , block.timestamp ,
         deadline , eachTikcetPrice , nfTName , new address[](0) , address(0) , true , user , false , 0);
        
        lotteries[lotteryId] = newLottery;
        addressToLotteryIds[user].push(lotteryId);


        // emit an event
        emit LotterCreated(lotteryId , nftId ,user, block.timestamp , deadline  , eachTikcetPrice);
    }   


    function initializeLottery(
        address user,
    uint256 nftId,
    uint256 deadline,
    uint256 eachTikcetPrice,
    string memory nfTName,
    uint256 nonce,
    bytes memory signature
) public  {
    // Recover signer from signature
    bytes32 messageHash = getHash(user, address(this), nftId, nonce);
    bytes32 signedMessageHash = messageHash.toEthSignedMessageHash();
    address signer = signedMessageHash.recover(signature);
    
    require(signer == user, "Signature does not match user");
    require(!executed[signedMessageHash], "Transaction already executed");
    
    executed[signedMessageHash] = true;
    
    // startLottery start the lottery using the recovered user's address
    startLottery( nftId, deadline, eachTikcetPrice, nfTName, user );
   
}

function buyLotteryTicketMetaTx(
    uint256 _LotteryId,
    uint256 nonce,
    bytes memory signature,
    address buyer,
    uint256 amount ,
    string memory uri
) public payable  nonReentrant {

    require(amount == lotteries[_LotteryId].eachTikcetPrice, "Provided ticket price does not match the required ticket price.");

    bytes32 messageHash = getHashBuyLotteryTicket(buyer, _LotteryId, nonce, lotteries[_LotteryId].eachTikcetPrice, address(this));
    bytes32 signedMessageHash = messageHash.toEthSignedMessageHash();
    address signer = signedMessageHash.recover(signature);

    // Ensure the signer hasn't executed this transaction before
    require(!executed[signedMessageHash], "Transaction already executed");
    require(signer == buyer, "Signature does not match user");
    executed[signedMessageHash] = true;

    // Transfer the ticket price from relayer to the contract
   // Transfer tokens from user to the contract
    bool sent = token.transferFrom(buyer, address(this), amount);
    require(sent, "Token transfer failed");

    _buyLotteryTicket( _LotteryId , buyer , uri , amount );
}


function _buyLotteryTicket(uint256 _LotteryId , address buyer  , string memory uri , uint256 amount  ) public payable nonReentrant {
    Lottery storage selectedLottery = lotteries[_LotteryId];

    // Ensure the lottery is still active and the deadline hasn't passed.
    require(selectedLottery.isLotteryActive, "This lottery is no longer active.");
    require(block.timestamp < selectedLottery.deadline, "This lottery has ended.");
    require(amount >= selectedLottery.eachTikcetPrice, "Sent ether should match the ticket price.");
    

    // Increment the current ticket ID to get a new unique ticket ID.
    uint256 newTicketId = _lotteryId.current();
    _lotteryId.increment();

    // initialize lottery ticket 
    LotteryTicket memory ticket = LotteryTicket(_LotteryId , newTicketId ,uri , buyer);
    lotteryTickets[newTicketId] = ticket;
    lotteryTicketIdToOwner[newTicketId] = buyer;

    // Transfer the NFT representing the lottery ticket to the buyer's wallet.
    // Since the ticket is an NFT, we'll use the _mint function of ERC721.
    _mint(buyer, newTicketId);

    // set token uri 
    _setTokenURI(newTicketId , uri);

    // URI can be set if you have a base URI for all lottery tickets. This can be done using setTokenURI function of ERC721URIStorage.

    // Update the necessary mappings and arrays.
    selectedLottery.participants.push(buyer);
    addressToTicketIds[buyer].push(newTicketId);
    ticketIdToOwner[newTicketId] = buyer;
    lotteryIdToPlayerToTicketId[_LotteryId][buyer] = newTicketId;

    // Update the total amount raised for the lottery.
    selectedLottery.totalRaised += amount;

    // Emit a TicketPurchased event.
    emit TicketPurchased(buyer, _LotteryId);
}


// function to get the winner - meta transaction 
function getRandomWinnerMetaTx(uint256 lotteryId, uint256 nonce, bytes memory signature , address caller ) public {
    // Recover signer from signature
    bytes32 messageHash = getHashForWinner(caller, lotteryId, nonce);
    bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
    address signer = ethSignedMessageHash.recover(signature);
    
    // Ensure the signer hasn't executed this transaction before
    require(!executed[ethSignedMessageHash], "Transaction already executed");
    executed[ethSignedMessageHash] = true;

    // Call the internal function
    _getRandomWinner(lotteryId);
}


    // getting the randow winner 
function _getRandomWinner(uint256 lotteryId) internal returns (bytes32 requestId) {
    require(lotteries[lotteryId].isLotteryActive, "This lottery is no longer active.");
    require(block.timestamp > lotteries[lotteryId].deadline, "This lottery has not ended yet.");
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    requestId = requestRandomness(keyHash, fee);
    requestIdToLotteryId[requestId] = lotteryId;

    return requestId;
}


function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual nonReentrant override   {
    uint256 lotteryId = requestIdToLotteryId[requestId];
    Lottery storage lottery = lotteries[lotteryId];
    require(lottery.isLotteryActive, "This lottery is no longer active.");


    uint256 index = randomness % lottery.participants.length;
    address winner = lottery.participants[index];
    lottery.winner = winner;

    // Transfer NFT to the winner
    if(!lottery.nftTransferred) {
        nftContract.safeTransferFrom(address(this), winner, lottery.nftId);
        lottery.nftTransferred = true;
        lottery.isLotteryActive = false;
    }

    uint256 commission = (lotteries[lotteryId].totalRaised * 20) / 100; // Calculate the 20% commission
    uint256 payout = lotteries[lotteryId].totalRaised - commission; // Calculate the amount to pay out to the lottery initiator
   
    require(lottery.creator != address(0), "Invalid lottery initiator address");

    // Transfer the amounts
    require(token.transfer(lottery.creator , payout), "Token transfer failed"); // Transfer the payout to the lottery initiator

    emit WinnerSelected(lotteryId, winner);
}

// Adjusted the getHash function to incorporate _lotteryId and nonce
function getHashBuyLotteryTicket(address sender, uint256 lotteryId, uint256 nonce , uint256 amount , address recipient) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, lotteryId, nonce , amount , recipient));
}


    // Add the nonce parameter here
function getHash(address sender, address recipient, uint256  nftId, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, nftId, recipient, nonce));
}


function getHashForWinner(address sender, uint256 lotteryId, uint256 nonce) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, lotteryId, nonce));
}

function setTokenAddress(address _erc20TokenAddress) external onlyOwner {
    token = IERC20(_erc20TokenAddress);
}

 function setCommissionRate(uint256 _rate) external onlyOwner {
        require(_rate < 100, "Rate should be less than 100");
        commissionRate = _rate;
    }

function emergencyWithdrawERC20(address _token, uint256 _amount) external onlyOwner {
    IERC20(_token).transfer(owner(), _amount);
}


// Function to receive Ether. msg.data must be empty
receive() external payable {}

// Fallback function is called when msg.data is not empty
fallback() external payable {}
   
}

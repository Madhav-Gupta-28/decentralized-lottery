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
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lottery is VRFConsumerBase , Ownable , ERC721URIStorage , ReentrancyGuard {

     using ECDSA for bytes32;

    // AIFT  IERC721 Contract address 
     IERC721 public nftContract;
     ERC20 public token;
    
    // =======       Chainlink variables       ============== 
    // The amount of LINK to send with the request
    uint256 public fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;

    // variables
    uint256 maxDeadline = 30 days;


    // Constructor inherits VRFConsumerBase
    constructor(address vrfCoordinator, address linkToken, bytes32 vrfKeyHash, uint256 vrfFee , address _nftcontractAddress) VRFConsumerBase(vrfCoordinator, linkToken) ERC721("Lottery", "LOT") {   
        keyHash = vrfKeyHash;
        fee = vrfFee;
        nftContract = IERC721(_nftcontractAddress);
    }


    // =========         Events      ====================
    event LotterCreated(uint256 lotteryId , uint256 nftId , address lotteryCreator , uint256 timeAtWhichCreatedm , uint256 deadline , uint256 eachTikcetPrice);
   event TicketPurchased(address indexed buyer, uint256 lotteryId);



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
    }

    struct LotteryTicket{
        uint256 lotteryId;
        uint256 ticketId;
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
         deadline , eachTikcetPrice , nfTName , new address[](0) , address(0) , true , user);
        
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
    uint256 amount 
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
    require(token.transferFrom(buyer, address(this), amount), "Token transfer failed");

    _buyLotteryTicket( _LotteryId , buyer );
}


function _buyLotteryTicket(uint256 _LotteryId , address buyer  ) public payable nonReentrant {
    Lottery storage selectedLottery = lotteries[_LotteryId];

    // Ensure the lottery is still active and the deadline hasn't passed.
    require(selectedLottery.isLotteryActive, "This lottery is no longer active.");
    require(block.timestamp < selectedLottery.deadline, "This lottery has ended.");
    require(msg.value == selectedLottery.eachTikcetPrice, "Sent ether should match the ticket price.");


    // transfer the money 


    // Increment the current ticket ID to get a new unique ticket ID.
    uint256 newTicketId = _lotteryId.current();
    _lotteryId.increment();



    // initialize lottery ticket 
    LotteryTicket memory ticket = LotteryTicket(_LotteryId , newTicketId , buyer);
    lotteryTickets[newTicketId] = ticket;
    lotteryTicketIdToOwner[newTicketId] = buyer;

    // Transfer the NFT representing the lottery ticket to the buyer's wallet.
    // Since the ticket is an NFT, we'll use the _mint function of ERC721.
    _mint(buyer, newTicketId);

    // URI can be set if you have a base URI for all lottery tickets. This can be done using setTokenURI function of ERC721URIStorage.

    // Update the necessary mappings and arrays.
    selectedLottery.participants.push(buyer);
    addressToTicketIds[buyer].push(newTicketId);
    ticketIdToOwner[newTicketId] = buyer;
    lotteryIdToPlayerToTicketId[_LotteryId][buyer] = newTicketId;

    // Emit a TicketPurchased event.
    emit TicketPurchased(buyer, _LotteryId);
}





// Adjusted the getHash function to incorporate _lotteryId and nonce
function getHashBuyLotteryTicket(address sender, uint256 lotteryId, uint256 nonce , uint256 amount , address recipient) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, lotteryId, nonce , amount , recipient));
}


    // Add the nonce parameter here
function getHash(address sender, address recipient, uint256  nftId, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, nftId, recipient, nonce));
}





    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override  {
        // here we are gonna to have the logic 
    }

      /**
    * getRandomWinner is called to start the process of selecting a random winner
    */
    function getRandomWinner() private returns (bytes32 requestId) {
        // LINK is an internal interface for Link token found within the VRFConsumerBase
        // Here we use the balanceOF method from that interface to make sure that our
        // contract has enough link so that we can request the VRFCoordinator for randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        // Make a request to the VRF coordinator.
        // requestRandomness is a function within the VRFConsumerBase
        // it starts the process of randomness generation
        return requestRandomness(keyHash, fee);
    }

   
}

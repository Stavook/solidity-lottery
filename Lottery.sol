// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery {
    
    enum Stage {Init, Reg, Bid, Done}
    Stage public stage = Stage.Init;
    
    struct Item {
        uint itemId;
        uint[] itemTokens;
    }
    
    struct Person {
        uint personId;
        address addr;
        uint remainingTokens;
    }
    
    Item[] public items;
    mapping(uint => Person) public players;
    uint public numPlayers;
    address public owner;
    uint public lotteryNumber = 1;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier atStage(Stage _stage) {
        require(stage == _stage, "Function cannot be called at this stage.");
        _;
    }
    
    event WinnerEvent(address indexed playerAddress, uint itemId, uint lotteryNumber, uint tokenNumber);
    
    constructor() {
        owner = msg.sender;
        stage = Stage.Reg;
    }
    
    function register() public payable atStage(Stage.Reg) {
        require(msg.value >= 0.005 ether, "Minimum registration fee is 0.005 ether");
        require(players[numPlayers].addr == address(0), "Player already registered");
        numPlayers++;
        players[numPlayers-1] = Person(numPlayers-1, msg.sender, 5);
        
    }
    
    function bid(uint _itemId, uint _numTokens) public atStage(Stage.Bid) {
        require(_numTokens > 0, "Number of tokens must be greater than 0");
        uint playerIndex = _getPlayerIndex(msg.sender);
        require(_numTokens <= players[playerIndex].remainingTokens, "Not enough tokens available");
        require(_itemId < items.length, "Invalid item ID");//check if itemId is valid
        
        // Check if the player has already bought a token for this item
        for (uint i = 0; i < items[_itemId].itemTokens.length; i++) {
            require(items[_itemId].itemTokens[i] != playerIndex, "Player has already bought a token for this item");
        }
    
        items[_itemId].itemTokens.push(playerIndex);
        players[playerIndex].remainingTokens -= _numTokens;
        
    }
    
    function revealWinners() public onlyOwner atStage(Stage.Done) {
        for(uint i=0; i<items.length; i++) {
            if(items[i].itemTokens.length > 0) {
                uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, i))) % items[i].itemTokens.length;
                uint winnerIndex = items[i].itemTokens[randomIndex];
                address winnerAddress = players[winnerIndex].addr;
                payable(winnerAddress).transfer(0.01 ether);
                emit WinnerEvent(winnerAddress, i, lotteryNumber, randomIndex);
                delete items[i].itemTokens;
            }
        }
        lotteryNumber++;
        stage = Stage.Reg;
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Contract balance must be greater than zero");//checks if zero before transferring
        payable(owner).transfer(address(this).balance);
    }
    
    function reset() public onlyOwner {
        for(uint i=0; i<items.length; i++) {
            delete items[i].itemTokens;
        }
        for(uint i=0; i<numPlayers; i++) {
            delete players[i];
        }
        numPlayers = 0;
        lotteryNumber++;
        stage = Stage.Reg;
        //error messages
        require(items.length == 0, "Failed to delete all item tokens");
        require(numPlayers == 0, "Failed to delete all players");
        require(stage == Stage.Reg, "Failed to set stage to Reg");
    }
    
    function _getPlayerIndex(address _addr) private view returns(uint playerIndex) {
        for(uint i=0; i<numPlayers; i++) {
            if(players[i].addr == _addr) {
                return i;
            }    
        }
        require(false, "Player not found");
        return playerIndex;
    }
}

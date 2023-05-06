// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery {
    
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
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function register() public payable {
        require(msg.value >= 0.005 ether, "Minimum registration fee is 0.005 ether");
        require(players[numPlayers].addr == address(0), "Player already registered");
        players[numPlayers] = Person(numPlayers, msg.sender, 5);
        numPlayers++;
    }
    
    function bid(uint _itemId, uint _numTokens) public {
        require(_numTokens > 0, "Number of tokens must be greater than 0");
        require(_numTokens <= players[_getPlayerIndex(msg.sender)].remainingTokens, "Not enough tokens available");
        require(_itemId < items.length, "Invalid item ID");
        items[_itemId].itemTokens.push(_getPlayerIndex(msg.sender));
        players[_getPlayerIndex(msg.sender)].remainingTokens -= _numTokens;
    }
    
    function revealWinners() public onlyOwner {
        for(uint i=0; i<items.length; i++) {
            if(items[i].itemTokens.length > 0) {
                uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, i))) % items[i].itemTokens.length;
                uint winnerIndex = items[i].itemTokens[randomIndex];
                payable(players[winnerIndex].addr).transfer(0.01 ether);
                delete items[i].itemTokens;
            }
        }
    }
    
    function withdraw() public onlyOwner {
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
    }
    
    function _getPlayerIndex(address _addr) private view returns(uint) {
        for(uint i=0; i<numPlayers; i++) {
            if(players[i].addr == _addr) {
                return i;
            }
        }
        revert("Player not found");
    }
    
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Lottery {
    address public owner;
    address payable[] public players;
    uint public lotteryID;
    mapping (uint => address payable) public lotteryHistoryWinners;

    constructor(){
        owner = msg.sender;
        lotteryID = 1;
    }

    function getPotBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getWinnerByLottery(uint ID) public view returns (address payable){
        return lotteryHistoryWinners[ID];
    }

    function enterLottery() public payable {
        require(msg.value >= 0.1 ether);

        //addresses of players entering the lottery
        players.push(payable(msg.sender));
    }

    function getRandomNumber() public view returns (uint){
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function pickWinner() public onlyOwner {
        //require(msg.sender == owner); //this is a cheap way to force only the owner to call this
        uint index = getRandomNumber() % players.length;
        uint256 winningAmount = (address(this).balance * 9)/10;
        players[index].transfer(winningAmount);

        //keep track of winners
        lotteryHistoryWinners[lotteryID] = players[index];
        lotteryID++;

        payable(owner).transfer(address(this).balance);

        //reset players array
        players = new address payable[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
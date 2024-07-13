// SPDX-License-Identifier: MIT
// This contract allows for an asynchronous game of PvP Rock, Paper, Scissors with the player. there's a queue of players. If it's empty, 
// a player's choice is stored in the contract. If there's already a player in the queue, the contract plays the game with the player and the game is resolved
// This is uniquely enabled by the FHEVM's ability to store encrypted data on-chain and perform computations on it.
pragma solidity ^0.8.20;

import "fhevm@0.3.0/lib/TFHE.sol";

contract FhockFhaperFhissors {
    enum Choice {
        Rock,
        Paper,
        Scissors
    }
    enum Outcome {
        PlayerOneWins,
        PlayerTwoWins,
        Draw
    }

    address payable public owner;
    uint32 public owner_fee_percent;

    address public holdingPlayer;
    euint8 public holdingPlayerChoice;

    uint256 const public BET_SIZE = 0.01 ether;

    constructor(uint32 _owner_fee_percent) payable {
        owner = payable(msg.sender);
        owner_fee_percent = _owner_fee_percent;
        holdingPlayer = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    event GameResult(address playerOne, address playerTwo, Choice playerOneChoice, Choice PlayerTwoChoice, Outcome outcome, uint256 payout);

    function determineOutcome(Choice ep1Choice, Choice ep2Choice) private pure returns (Outcome) {
        if (p1Choice == p2Choice) {
            return Outcome.Draw;
        } else if (
            (p1Choice == Choice.Paper && p2Choice == Choice.Rock) ||
            (p1Choice == Choice.Rock && p2Choice == Choice.Scissors) ||
            (p1Choice == Choice.Scissors && p2Choice == Choice.Paper)
        ) {
            return Outcome.PlayerWins;
        } else {
            return Outcome.ContractWins;
        }
    }

    function play(bytes calldata playerChoice) public payable {
        require(msg.value == BET_SIZE, "Need to pass 0.01 INCO to play");
        uint256 owner_fee = msg.value * owner_fee_percent / 100;
        uint256 payout = msg.value * 2 - owner_fee;


        if (holdingPlayer == address(0)) {
            // in this branch the queue is empty so we must store the player's choice until an opponent can be found
            holdingPlayer = msg.sender;
            holdingPlayerChoice = TFHE.asEuint8(playerChoice);
            return;
        } else {
            // Here, the opponent is already in the queue, so we can play the game
            // bets are made; we can safely decrypt
            const Choice p1Choice = Choice(THFE.decrypt(holdingPlayerChoice));
            const Choice p2Choice = Choice(THFE.decrypt(TFHE.asEuint8(playerChoice)));
            Outcome outcome = determineOutcome(p1Choice, p2Choice);

            address winner = address(0);
            if (outcome == Outcome.Draw){
                payout = msg.value - owner_fee
                payable(holdingPlayer).transfer(payout);
                payable(msg.sender).transfer(payout);
                emit GameResult(holdingPlayer, msg.sender, p1Choice, p2Choice, outcome, payout);
            } else {
                payout = 2 * BET_SIZE - 2 * owner_fee;
                if (outcome == Outcome.PlayerOneWins) {
                    winner = holdingPlayer;
                } else if (outcome == Outcome.PlayerTwoWins) {
                    winner = msg.sender;
                }
                payable(winner).transfer(payout);
                emit GameResult(holdingPlayer, msg.sender, p1Choice, p2Choice, outcome, payout);
                holdingPlayer = address(0);
            }
        }
    }
        

    function withdrawFromPool(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient pool balance");
        owner.transfer(amount);
    }

    function addToPool() public payable {
    }
}

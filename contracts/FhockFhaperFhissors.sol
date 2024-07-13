// SPDX-License-Identifier: MIT
// This contract plays a game of Rock, Paper, Scissors with the player. It takes the user's wager and has a pool
// of funds that it uses to pay out the player's winnings. The contract owner can set a fee that is taken from the wager every round.
pragma solidity ^0.8.20;

import "fhevm@0.3.0/lib/TFHE.sol";

contract FhockFhaperFhissors {
    enum Choice {
        Rock,
        Paper,
        Scissors
    }
    enum Outcome {
        PlayerWins,
        ContractWins,
        Draw
    }

    address payable public owner;
    uint32 public owner_fee_percent;

    constructor(uint32 _owner_fee_percent) payable {
        owner = payable(msg.sender);
        owner_fee_percent = _owner_fee_percent;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    event GameResult(address player, Choice playerChoice, Choice contractChoice, Outcome outcome, uint256 payout);

    function determineOutcome(Choice playerChoice, Choice contractChoice) private pure returns (Outcome) {
        if (playerChoice == contractChoice) {
            return Outcome.Draw;
        } else if (
            (playerChoice == Choice.Paper && contractChoice == Choice.Rock) ||
            (playerChoice == Choice.Rock && contractChoice == Choice.Scissors) ||
            (playerChoice == Choice.Scissors && contractChoice == Choice.Paper)
        ) {
            return Outcome.PlayerWins;
        } else {
            return Outcome.ContractWins;
        }
    }

    function play(Choice playerChoice) public payable {
        require(msg.value != 0, "Need to pass a wager to play");
        require(address(this).balance >= msg.value, "Insufficient pool balance");

        euint16 enumber = TFHE.randEuint16();
        Choice contractChoice = Choice(TFHE.decrypt(enumber) % 3);
        Outcome outcome = determineOutcome(playerChoice, contractChoice);

        uint256 payout = 0;
        uint256 owner_fee = msg.value * owner_fee_percent / 100;

        if (outcome == Outcome.PlayerWins) {
            payout = msg.value*2 - owner_fee;
            payable(msg.sender).transfer(payout);
        } else if (outcome == Outcome.Draw) {
            payable(msg.sender).transfer(msg.value - owner_fee);
        }

        owner.transfer(owner_fee);
        emit GameResult(msg.sender, playerChoice, contractChoice, outcome, payout);
    }

    function withdrawFromPool(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient pool balance");
        owner.transfer(amount);
    }

    function addToPool() public payable {
    }
}

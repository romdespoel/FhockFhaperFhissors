// SPDX-License-Identifier: MIT
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

    address payable private owner;
    uint32 public owner_fee_percent;
    Choice public last_choice;

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

    function generateRandomChoice() public returns (Choice) {
        euint16 enumber = TFHE.randEuint16();
        last_choice = Choice(TFHE.decrypt(enumber) % 3);
        return last_choice;
    }

    function play(Choice playerChoice) public payable {
        require(msg.value != 0, "Need to pass a wager to play");
        require(address(this).balance >= msg.value, "Insufficient pool balance");

        Choice contractChoice = generateRandomChoice();
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

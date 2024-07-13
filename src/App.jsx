import React, { useState, useEffect } from 'react';
import { Form, Button } from 'react-bootstrap';
import { ethers } from 'ethers';
import { init, getInstance } from "./utils/fhevm";
import { toHexString } from "./utils/utils";
import { Connect } from "./Connect";
import { BrowserProvider } from "ethers";


const contractABI = [
	{
		"inputs": [
			{
				"internalType": "uint32",
				"name": "_owner_fee_percent",
				"type": "uint32"
			}
		],
		"stateMutability": "payable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"internalType": "address",
				"name": "player",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "enum FhockFhaperFhissors.Choice",
				"name": "playerChoice",
				"type": "uint8"
			},
			{
				"indexed": false,
				"internalType": "enum FhockFhaperFhissors.Choice",
				"name": "contractChoice",
				"type": "uint8"
			},
			{
				"indexed": false,
				"internalType": "enum FhockFhaperFhissors.Outcome",
				"name": "outcome",
				"type": "uint8"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "payout",
				"type": "uint256"
			}
		],
		"name": "GameResult",
		"type": "event"
	},
	{
		"inputs": [],
		"name": "addToPool",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"internalType": "address payable",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "owner_fee_percent",
		"outputs": [
			{
				"internalType": "uint32",
				"name": "",
				"type": "uint32"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "enum FhockFhaperFhissors.Choice",
				"name": "playerChoice",
				"type": "uint8"
			}
		],
		"name": "play",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "withdrawFromPool",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];

const contractAddress = '0x7d097aE4a4509AB263A24285B5F6f5801C0F745a'; // Replace with your actual contract address

function App() {
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    init()
      .then(() => {
        setIsInitialized(true);
      })
      .catch(() => setIsInitialized(false));
  }, []);

  if (!isInitialized) return null;

  return (
    <div className="App">
      <div className="menu">
        <Connect>{(account, provider) => <FhockFhaperFhissors account={account} provider={provider} />}</Connect>
      </div>
    </div>
  );
}

function FhockFhaperFhissors({ account, provider }) {
  const [choice, setChoice] = useState('');
  const [amount, setAmount] = useState('');

  const handleChoiceChange = (event) => {
    setChoice(event.target.value);
  };

  const handleAmountChange = (event) => {
    setAmount(event.target.value);
  };

  const handleSubmit = async () => {
    if (!choice || !amount) {
      alert('Please select a choice and enter an amount');
      return;
    }

    try {
      const choiceMapping = {
        'Fhock': 0,
        'Fhaper': 1,
        'Fhissors': 2
      };

      const choiceValue = choiceMapping[choice];
      const amountInWei = ethers.parseEther(amount);

      // Ensure we're using the correct provider and signer
      const provider = new BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      const contract = new ethers.Contract(contractAddress, contractABI, signer);


      // Encrypt the choice
      let instance = await getInstance();

      // Prepare the transaction
      const tx = await contract.play((choiceValue), { value: amountInWei });

      console.log('Transaction sent:', tx.hash);

      // Wait for the transaction to be mined
      const receipt = await tx.wait();
      console.log('Transaction was mined in block:', receipt.blockNumber);
      console.log("Receipt:", receipt);

      // Check for GameResult event
      const gameResultEvent = receipt.events.find(event => event.event === 'GameResult');
      if (gameResultEvent) {
        const { playerChoice, contractChoice, outcome, payout } = gameResultEvent.args;
        console.log('Game Result:', { playerChoice, contractChoice, outcome, payout });
        console.log(`Game Result: Player Choice: ${playerChoice}, Contract Choice: ${contractChoice}, Outcome: ${outcome}, Payout: ${ethers.utils.formatEther(payout)} ETH`);
      }
    } catch (error) {
      console.error('Error sending transaction:', error);
    }
  };

  return (
    <div>
      <h1>Fhock Fhaper Fhissors</h1>
	  <h2>Contract Address: {contractAddress}</h2>
      <Form className="Form-container">
        <Form.Group className="form-group">
          <Form.Label className="label">Choose your move: </Form.Label>
          <Form.Control
            as="select"
            value={choice}
            onChange={handleChoiceChange}
            className="Input"
          >
            <option value="">Select...</option>
            <option value="Fhock">Fhock</option>
            <option value="Fhaper">Fhaper</option>
            <option value="Fhissors">Fhissors</option>
          </Form.Control>
        </Form.Group>
        <Form.Group className="form-group">
          <Form.Label className="label">Amount (ETH): </Form.Label>
          <Form.Control
            type="number"
            step="0.01"
            value={amount}
            onChange={handleAmountChange}
            placeholder="Enter amount in ETH"
            className="Input"
          />
        </Form.Group>
        <Button variant="primary" onClick={handleSubmit}>
          Fhlay Game
        </Button>
      </Form>
      <br />
    </div>
  );
}

export default App;
import Web3 from 'web3';
import dotenv from 'dotenv';
dotenv.config();

export const web3 = new Web3(process.env.RPC_URL);

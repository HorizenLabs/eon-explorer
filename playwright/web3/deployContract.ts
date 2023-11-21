import { web3 } from './web3Provider';
import contractJson from './contracts/abi/lottery.json';
import bytecodeData from './contracts/bytecode/lotteryBytecode.json';

const deployContract = async (privateKey: string): Promise<{ contractAddress: string, transactionHash: string }> => {
    const account = web3.eth.accounts.privateKeyToAccount("0x" + privateKey);
    const contract = new web3.eth.Contract(contractJson as any);

    const deployTx = contract.deploy({ data: bytecodeData.bytecode });

    const estimatedGas = await deployTx.estimateGas({ from: account.address });
    const gasPrice = await web3.eth.getGasPrice();
    const nonce = await web3.eth.getTransactionCount(account.address, 'pending');

    const txObject = {
        nonce: web3.utils.toHex(nonce),
        gasLimit: web3.utils.toHex(estimatedGas),
        gasPrice: web3.utils.toHex(gasPrice),
        data: deployTx.encodeABI()
    };

    const signedTx = await account.signTransaction(txObject);

    return new Promise((resolve, reject) => {
        web3.eth.sendSignedTransaction(signedTx.rawTransaction)
            .on('receipt', receipt => {
                console.log('Contract transaction hash:', receipt.transactionHash);
                console.log('Contract deployed at address:', receipt.contractAddress);
                resolve({ contractAddress: receipt.contractAddress, transactionHash: receipt.transactionHash });
            })
            .on('error', error => {
                console.error("Failed to deploy Contract:", error);
                reject(error);
            });
    });
};

export default deployContract;



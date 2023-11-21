import { Web3 } from "web3";
import { web3 } from './web3Provider';
import BN from "bn.js";

interface TransactionReceipt {
    transactionHash: string;
    transactionIndex: number;
    blockHash: string;
    blockNumber: number;
    cumulativeGasUsed: number;
    gasUsed: number;
};

export const formatPrivateKey = (privateKey: string): string => {
    return privateKey.startsWith('0x') ? privateKey : '0x' + privateKey;
}

export const getReceipt = async (web3: Web3, txHash: string): Promise<TransactionReceipt> => {
    while (true) {
        const receipt = await web3.eth.getTransactionReceipt(txHash);
        if (receipt) {
            return receipt as TransactionReceipt;
        }
        await new Promise(res => setTimeout(res, 1000));
    }
};

export const sendTransaction = async (
    privateKey: string,
    toAddress: string,
    amount: number,
    nonceOffset: number = 0
): Promise<{ sender: string, txHash: string, receipt?: TransactionReceipt }> => {

    const account = web3.eth.accounts.privateKeyToAccount(formatPrivateKey(privateKey));
    const nonce = new BN(await web3.eth.getTransactionCount(account.address, 'pending')).add(new BN(nonceOffset));

    const tx = {
        from: account.address,
        to: toAddress,
        value: web3.utils.toWei(amount, 'ether'),
        gas: 21000,
        gasPrice: await web3.eth.getGasPrice(),
        nonce: nonce.toString()
    };

    let signedTx;
    try {
        signedTx = await account.signTransaction(tx);
    } catch (error) {
        throw new Error(`Error signing transaction: ${error.message}`);
    }

    return new Promise((resolve, reject) => {
        let transactionHash;
        let resolved = false;

        web3.eth.sendSignedTransaction(signedTx.rawTransaction)
            .once('transactionHash', (hash: string) => {
                console.log(`sendTransaction Transaction Hash: ${hash}`);
                transactionHash = hash;
                if (nonceOffset !== 0 && !resolved) {
                    resolved = true;
                    resolve({ sender: account.address, txHash: hash });
                }
            })
            .once('receipt', (receipt: TransactionReceipt) => {
                console.log(`sendTransaction Transaction Receipt Block: ${receipt.blockNumber}`);
                if (resolved) return;
                resolved = true;
                resolve({ sender: account.address, txHash: transactionHash, receipt });
            })
            .once('error', (error) => {
                reject(error);
            });
    });
};

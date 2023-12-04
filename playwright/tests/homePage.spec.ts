import { test, expect } from '@playwright/test';
import { HomePage } from '../pages/HomePage';
import dotenv from 'dotenv';
import { sendTransaction } from "../web3/utils";
import {BlockDetailsPage} from "../pages/BlockDetailsPage";
import { isTimestampValid } from '../utils/stringUtils';
dotenv.config();

test.describe('Confirm block display for new blocks and new transactions', () => {

    let homePage: HomePage;
    let blockDetailsPage: BlockDetailsPage;

    test.beforeEach(async ({ page }) => {
        homePage = new HomePage(page);
        blockDetailsPage = new BlockDetailsPage(page);
        await homePage.goto();
    });

    test('Block section is displayed, shows new transactions and clicks through to transaction page', async ({ page }) => {
        const title = await homePage.blocks.getTitle();
        expect(title).toBe('Blocks');

        const chainBlocks = await homePage.blocks.getChainBlocks();
        expect(chainBlocks.length).toBe(4);

        for (const block of chainBlocks) {
            expect(await block.isBlockNumberLinkValid()).toBe(true);
            expect(await block.isTransactionsValid()).toBe(true);
            expect(isTimestampValid(await block.getTimeStamp())).toBe(true);
            expect(await block.isForgerLinkValid()).toBe(true);
        }

        const response = await sendTransaction(process.env.PK, process.env.RECEIVING_ADDRESS, 0.0001);
        expect(response.receipt?.blockNumber).toBeDefined();
        expect(response.receipt?.transactionHash).toBeDefined();

        const blockNumber = response.receipt?.blockNumber.toString()
        await homePage.blocks.waitForBlockWithNumber(blockNumber, true, 90000);
        await homePage.blocks.clickOnBlockWithNumber(blockNumber)
        expect(await blockDetailsPage.blockDetails.isCorrectBlockHeight(blockNumber)).toBe(true);

        const sentTransaction = await blockDetailsPage.blockTransactions.findTransactionByHash(response.receipt?.transactionHash!)
        expect(sentTransaction)
    });
});

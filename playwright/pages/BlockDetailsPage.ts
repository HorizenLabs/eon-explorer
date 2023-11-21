import { Page } from '@playwright/test';
import { BlockDetails } from '../components/BlockDetails';
import dotenv from 'dotenv';
import { Transactions } from "../components/Transactions";

dotenv.config();

export class BlockDetailsPage {
    readonly page: Page;
    readonly blockDetails: BlockDetails;
    readonly blockTransactions: Transactions;

    constructor(page: Page) {
        this.page = page;
        this.blockDetails = new BlockDetails(page);
        this.blockTransactions = new Transactions(page);
    }

    async goto(blockNumber: number) {
        await this.page.goto(`${process.env.BASE_URL}/block/${blockNumber}`);
    }
}

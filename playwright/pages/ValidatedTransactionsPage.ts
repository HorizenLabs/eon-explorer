import { Page } from '@playwright/test';
import { NavBar } from '../components/NavBar';
import {Transactions} from "../components/Transactions";
import dotenv from 'dotenv';

dotenv.config();

export class ValidatedTransactionsPage {
    readonly page: Page;
    readonly navBar: NavBar;
    readonly transactions: Transactions;

    constructor(page: Page) {
        this.page = page;
        this.navBar = new NavBar(page);
        this.transactions = new Transactions(page);
    }

    async goto() {
        await this.page.goto(`${process.env.BASE_URL}/txs`);
    }
}

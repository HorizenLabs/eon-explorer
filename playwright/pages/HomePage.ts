import { Page } from '@playwright/test';
import { NavBar } from '../components/NavBar';
import { Blocks } from "../components/Blocks";
import dotenv from 'dotenv';
import { Transactions } from "../components/Transactions";

dotenv.config();

export class HomePage {
    readonly page: Page;
    readonly navBar: NavBar;
    readonly blocks: Blocks;
    readonly transactions: Transactions;

    constructor(page: Page) {
        this.page = page;
        this.navBar = new NavBar(page);
        this.blocks = new Blocks(page)
        this.transactions = new Transactions(page);
    }

    async goto() {
        await this.page.goto(process.env.BASE_URL);
    }
}

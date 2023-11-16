import { Page, Locator } from '@playwright/test';
import {delay} from "../utils/utils";

const SELECTORS = {

    TRANSACTION: {
        CONTAINER: '.card',
        VIEW_ALL_TRANSACTIONS: 'a:has-text("View All Transactions")',
        BASE: '[data-selector="transactions-list"] .tile',
        TYPE: '[data-test="transaction_type"]',
        STATUS: '[data-test="transaction_status"]',
        HASH: '[data-test="transaction_hash_link"]',
        FROM_ADDRESS: ':nth-child(1) > [data-test="address_hash_link"] > span:first-child',
        TO_CONTRACT_ADDRESS: '[data-test="address_hash_link"] .contract-address',
        VALUE: '.tile-title',
        FEE: '.tile-title + span',
        BLOCK: 'a[href^="/block/"]',
        TIMESTAMP: '[data-from-now]'
    }
};

export class Transactions {
    readonly page: Page;
    readonly container: Locator;

    constructor(page: Page) {
        this.page = page;
        this.container = page.locator(SELECTORS.TRANSACTION.CONTAINER);
    }

    async clickViewAllTransactions() {
        const viewAllButton = this.container.locator(SELECTORS.TRANSACTION.VIEW_ALL_TRANSACTIONS);
        await viewAllButton.click();
    }

    async getAllTransactions(): Promise<TransactionRow[]> {
        const transactionCount = await this.container.locator(SELECTORS.TRANSACTION.BASE).count();
        return Array.from({ length: transactionCount }).map((_, i) =>
            new TransactionRow(this.page)
        );
    }

    async findTransactionByHash(hash: string): Promise<TransactionRow | null> {
        try {
            const transactionCount = await this.container.locator(SELECTORS.TRANSACTION.BASE).count();
            for (let i = 1; i <= transactionCount; i++) {
                const row = new TransactionRow(this.page, hash);
                if ((await row.getHash()) === hash) {
                    return row;
                }
            }

            return null;
        } catch (error) {
            throw new Error(`Error while trying to find transaction with hash ${hash}. Details: ${error.message}`);
        }
    }

    async waitForTransactionWithHash(hash: string, refresh: boolean = false, timeout: number = 60000): Promise<TransactionRow> {
        const endTime = Date.now() + timeout;
        do {
            try {
                const selector = `${SELECTORS.TRANSACTION.HASH}[href$="/tx/${hash}"]`;
                await this.page.waitForSelector(selector, { timeout: 3000 });
                return new TransactionRow(this.page, hash);
            } catch (error) {
                if (refresh) {
                    await this.page.reload();
                }
            }
        } while (Date.now() < endTime);

        throw new Error(`Timed out waiting for transaction with hash ${hash} after ${timeout}ms`);
    }
}

interface TransactionDetails {
    type: string | null;
    status: string | null;
    hash: string | null;
    fromAddress: string | null;
    toAddress: string | null;
    value: string | null;
    fee: string | null;
    block: string | null;
    timeStamp: string | null;
}

export class TransactionRow {
    readonly baseSelector: Locator;
    readonly transactionType: Locator;
    readonly transactionStatus: Locator;
    readonly transactionHash: Locator;
    readonly fromAddress: Locator;
    readonly toContractAddress: Locator;
    readonly value: Locator;
    readonly fee: Locator;
    readonly block: Locator;
    readonly timeStamp: Locator;

    constructor(page: Page, hash?: string) {
        let baseSelector = SELECTORS.TRANSACTION.BASE;
        if (hash) {
            baseSelector = `.tile[data-identifier-hash="${hash}"]`;
        }
        this.baseSelector = page.locator(baseSelector);
        this.transactionType = this.baseSelector.locator(SELECTORS.TRANSACTION.TYPE);
        this.transactionStatus = this.baseSelector.locator(SELECTORS.TRANSACTION.STATUS);
        this.transactionHash = this.baseSelector.locator(SELECTORS.TRANSACTION.HASH);
        this.fromAddress = this.baseSelector.locator(SELECTORS.TRANSACTION.FROM_ADDRESS);
        this.toContractAddress = this.baseSelector.locator(SELECTORS.TRANSACTION.TO_CONTRACT_ADDRESS);
        this.value = this.baseSelector.locator(SELECTORS.TRANSACTION.VALUE);
        this.fee = this.baseSelector.locator(SELECTORS.TRANSACTION.FEE);
        this.block = this.baseSelector.locator(SELECTORS.TRANSACTION.BLOCK);
        this.timeStamp = this.baseSelector.locator(SELECTORS.TRANSACTION.TIMESTAMP);
    }

    async getDetails(): Promise<TransactionDetails> {
        return {
            type: await this.getType(),
            status: await this.getStatus(),
            hash: await this.getHash(),
            fromAddress: await this.getFromAddress(),
            toAddress: await this.getToAddress(),
            value: await this.getValue(),
            fee: await this.getFee(),
            block: await this.getBlock(),
            timeStamp: await this.getTimeStamp()
        };
    }

    async getType(): Promise<string | null> {
        return await this.transactionType.textContent();
    }

    async getStatus(): Promise<string | null> {
        return await this.transactionStatus.textContent();
    }

    async getHash(): Promise<string | null> {
        return await this.transactionHash.textContent();
    }

    async getFromAddress(): Promise<string | null> {
        return await this.fromAddress.textContent();
    }

    async getToAddress(): Promise<string | null> {
        return await this.toAddress.textContent();
    }

    async getValue(): Promise<string | null> {
        return await this.value.textContent();
    }

    async getFee(): Promise<string | null> {
        return await this.fee.textContent();
    }

    async getBlock(): Promise<string | null> {
        return await this.block.textContent();
    }

    async getTimeStamp(): Promise<string | null> {
        return await this.block.textContent();
    }

    async clickToContractAddress(): Promise<void> {
        // Delay because it clicks too fast and sometimes clicks the wrong field.
        await delay(2000);
        return await this.toContractAddress.click();
    }
}

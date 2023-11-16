import { Page, Locator } from '@playwright/test';

const SELECTORS = {
    BLOCK: {
        CONTAINER: '.card-chain-blocks',
        TITLE: '.card-title',
        VIEW_ALL_LINK: '.card-body a[href="/blocks"]',
        BASE: '[data-selector="chain-block"]',
        NUMBER: '[data-selector="block-number"]',
        TRANSACTIONS: '.tile-transactions span:first-child',
        TIMESTAMP: '.tile-transactions span:last-child',
        FORGER_LINK: '[data-test="address_hash_link"]',
        FORGER_ADDRESS: '[data-test="address_hash_link"] span.d-xl-inline'
    }
};

export class Blocks {
    readonly page: Page;
    readonly container: Locator;
    readonly cardTitle: Locator;
    readonly viewAllBlocksLink: Locator;

    constructor(page: Page) {
        this.page = page;
        this.container = page.locator(SELECTORS.BLOCK.CONTAINER);
        this.cardTitle = this.container.locator(SELECTORS.BLOCK.TITLE);
        this.viewAllBlocksLink = this.container.locator(SELECTORS.BLOCK.VIEW_ALL_LINK);
    }

    async getTitle(): Promise<string> {
        const titleText = await this.cardTitle.textContent();
        if (titleText === null) {
            throw new Error('Failed to fetch the title text.');
        }
        return titleText;
    }

    async clickViewAllBlocksLink(): Promise<void> {
        await this.viewAllBlocksLink.click();
    }

    async getChainBlocks(): Promise<ChainBlock[]> {
        const blockCount = await this.container.locator(SELECTORS.BLOCK.BASE).count();
        return Array.from({ length: blockCount }).map((_, i) =>
            new ChainBlock(this.container.locator(`${SELECTORS.BLOCK.BASE}:nth-of-type(${i + 1})`))
        );
    }

    blockSelector(attribute: string, value: string): string {
        return `${SELECTORS.BLOCK.BASE} ${SELECTORS.BLOCK.NUMBER}[${attribute}*="${value}"]`;
    }

    async waitForBlockWithNumber(blockNumber: string, refresh: boolean = false, timeout: number = 30000): Promise<void> {
        const endTime = Date.now() + timeout;
        do {
            try {
                await this.page.waitForSelector(this.blockSelector('href', `/block/${blockNumber}`), { timeout: 3000 });
                return;
            } catch (error) {
                if (refresh) {
                    await this.page.reload();
                }
            }
        } while (Date.now() < endTime);

        throw new Error(`Timed out waiting for selector after ${timeout}ms`);
    }


    async clickOnBlockWithNumber(blockNumber: string): Promise<void> {
        const blockElement = this.page.locator(this.blockSelector('href', `/block/${blockNumber}`));
        await blockElement.click();
    }
}

class ChainBlock {
    readonly baseSelector: Locator;
    readonly blockNumber: Locator;
    readonly transactions: Locator;
    readonly timeStamp: Locator;
    readonly forgerAddress: Locator;
    readonly forgerAddressLink: Locator;

    constructor(baseSelector: Locator) {
        this.baseSelector = baseSelector;
        this.blockNumber = baseSelector.locator(SELECTORS.BLOCK.NUMBER);
        this.transactions = baseSelector.locator(SELECTORS.BLOCK.TRANSACTIONS);
        this.timeStamp = baseSelector.locator(SELECTORS.BLOCK.TIMESTAMP);
        this.forgerAddressLink = baseSelector.locator(SELECTORS.BLOCK.FORGER_LINK);
        this.forgerAddress = baseSelector.locator(SELECTORS.BLOCK.FORGER_ADDRESS);
    }

    async getBlockNumber(): Promise<string> {
        const blockNumberText = await this.blockNumber.textContent();
        if (!blockNumberText) {
            throw new Error('Failed to fetch block number text.');
        }
        return blockNumberText;
    }

    async getTransactions(): Promise<string> {
        const transactionsText = await this.transactions.textContent();
        if (!transactionsText) {
            throw new Error('Failed to fetch transactions text.');
        }
        return transactionsText;
    }

    async getTimeStamp(): Promise<string> {
        const timeStampText = await this.timeStamp.textContent();
        if (!timeStampText) {
            throw new Error('Failed to fetch timestamp text.');
        }
        return timeStampText;
    }

    async getForgerAddress(): Promise<string> {
        const forgerAddressText = await this.forgerAddress.textContent();
        if (!forgerAddressText) {
            throw new Error('Failed to fetch forger address text.');
        }
        return forgerAddressText;
    }

    async clickBlockNumber(): Promise<void> {
        await this.blockNumber.click();
    }

    async isBlockNumberLinkValid(): Promise<boolean> {
        const blockNumberHref = await this.blockNumber.getAttribute('href');
        if (!blockNumberHref?.includes('/block/')) {
            throw new Error(`Block number link validation failed. Expected link to include '/block/', but received: "${blockNumberHref}"`);
        }
        const blockNum = await this.getBlockNumber();
        if (isNaN(Number(blockNum))) {
            throw new Error(`Block number validation failed. Received block number: "${blockNum}"`);
        }
        return true;
    }

    async isTransactionsValid(): Promise<boolean> {
        const transactionsText = await this.transactions.textContent();
        const match = (transactionsText || '').match(/^(\d+) Transactions$/);
        if (!match) {
            throw new Error(`Transactions text validation failed. Expected format like 'n Transactions', but received: "${transactionsText}"`);
        }
        return true;
    }

    async isForgerLinkValid(): Promise<boolean> {
        const forgerText = await this.getForgerAddress();
        const forgerHref = await this.forgerAddressLink.getAttribute('href');
        if (!forgerText?.startsWith('0x')) {
            throw new Error(`Forger address validation failed. Expected address to start with '0x', but received: "${forgerText}"`);
        }
        if (!forgerHref?.includes(`/address/${forgerText}`)) {
            throw new Error(`Forger link validation failed. Expected link to match format "/address/${forgerText}", but received: "${forgerHref}"`);
        }
        return true;
    }
}


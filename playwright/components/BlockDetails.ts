import { Page, Locator } from '@playwright/test';

const DETAIL_SELECTORS = {
    TITLE: 'h1[data-test="detail_type"]',
    PAGINATION_PREVIOUS_BLOCK_LINK: 'a[data-prev-page-button]',
    PAGINATION_NEXT_BLOCK_LINK: 'a[data-next-page-button]',
    PAGINATION_CURRENT_BLOCK: 'a[data-page-number]:has-text("Block")',
    BLOCK_HEIGHT_TOOLTIP: '.i-tooltip-2',
    BLOCK_HEIGHT_LABEL: 'dt:has-text("Block Height")',
    BLOCK_HEIGHT_VALUE: 'dd[data-test="block_detail_number"]',
};

export class BlockDetails {
    readonly page: Page;
    readonly title: Locator;
    readonly previousBlockLink: Locator;
    readonly nextBlockLink: Locator;
    readonly currentBlock: Locator;

    constructor(page: Page) {
        this.page = page;
        this.title = page.locator(DETAIL_SELECTORS.TITLE);
        this.previousBlockLink = page.locator(DETAIL_SELECTORS.PAGINATION_PREVIOUS_BLOCK_LINK);
        this.nextBlockLink = page.locator(DETAIL_SELECTORS.PAGINATION_NEXT_BLOCK_LINK);
        this.currentBlock = page.locator(DETAIL_SELECTORS.PAGINATION_CURRENT_BLOCK);
    }

    async getTitle(): Promise<string> {
        const titleText = await this.title.textContent();
        if (titleText === null) {
            throw new Error('Failed to fetch title text.');
        }
        return titleText;
    }

    async clickPreviousBlock(): Promise<void> {
        await this.previousBlockLink.click();
    }

    async clickNextBlock(): Promise<void> {
        await this.nextBlockLink.click();
    }

    async getBlockHeight(): Promise<string> {
        const blockHeight = await this.page.locator(DETAIL_SELECTORS.BLOCK_HEIGHT_VALUE).textContent();
        if (blockHeight === null) {
            throw new Error('Failed to fetch block height.');
        }
        return blockHeight;
    }

    async getCurrentPaginationBlock(): Promise<string> {
        const currentBlockText = await this.page.locator(DETAIL_SELECTORS.PAGINATION_CURRENT_BLOCK).textContent();
        if (currentBlockText === null) {
            throw new Error('Failed to fetch current pagination block.');
        }
        return currentBlockText;
    }

    async isCorrectBlockHeight(blockNumber: string): Promise<boolean> {
        const blockHeight = await this.getBlockHeight();
        const paginationBlock = await this.getCurrentPaginationBlock();

        return blockNumber === blockHeight && blockNumber === paginationBlock ;
    }
}

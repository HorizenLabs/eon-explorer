import { Page, Locator } from '@playwright/test';

const SELECTORS = {
    TAB_DETAILS: {
        CONTAINER: '[data-page="address-details"]',
        CONTRACT_ADDRESS: '[data-test="address_detail_hash"]',
        // TODO: Add other fields
    }
};

export class AddressOverview {
    readonly page: Page;
    readonly container: Locator;
    readonly contractAddress: Locator;

    constructor(page: Page) {
        this.page = page;
        this.container = page.locator(SELECTORS.TAB_DETAILS.CONTAINER);
        this.contractAddress = page.locator(SELECTORS.TAB_DETAILS.CONTRACT_ADDRESS);
    }

    async getContractAddress(): Promise<string> {
        const contractAddress = await this.contractAddress.textContent();
        if (!contractAddress) {
            throw new Error('Failed to fetch Contract Address text.');
        }
        return contractAddress;
    }

}

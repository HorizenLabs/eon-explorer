import { Page, Locator } from '@playwright/test';
import {CodeTab} from "./CodeTab";

const SELECTORS = {
    TAB_DETAILS: {
        CONTAINER: '[id="txs"]',
        ADDRESS_TABS: '.address-tabs',
        TAB: '.card-tab',
        VERIFY_PUBLISH_BUTTON: '[data-test="verify_and_publish"]'
    }
};

export class AddressTabDetails {
    readonly page: Page;
    readonly addressTabs: Locator;
    readonly tab: Locator;
    readonly codeTab: CodeTab;

    constructor(page: Page) {
        this.page = page;
        this.codeTab = new CodeTab(page);
        this.addressTabs = page.locator(SELECTORS.TAB_DETAILS.ADDRESS_TABS);
        this.tab = page.locator(SELECTORS.TAB_DETAILS.TAB);
    }

    async clickCodeTab() {
        await this.tab.nth(3).click();
    }
}

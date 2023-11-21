import { Page, Locator } from '@playwright/test';

const SELECTORS = {
    CONTAINER: '.card-body',
    VERIFY_PUBLISH_BUTTON: '[data-test="verify_and_publish"]',
    CONTRACT_NAME: 'dt:text("Contract name:") + dd',
    OPTIMIZATION_ENABLED: 'dt:text("Optimization enabled") + dd',
    COMPILER_VERSION: 'dt:text("Compiler version") + dd',
    EVM_VERSION: 'dt:text("EVM Version") + dd',
    VERIFIED_AT: 'dt:text("Verified at") + dd',
    COPY_SOURCE_CODE_BUTTON: 'button:has-text("Copy Source Code")'
};

export class CodeTab {
    readonly page: Page;
    readonly container: Locator;
    readonly verifyPublishButton: Locator;
    readonly contractName: Locator;
    readonly optimizationEnabled: Locator;
    readonly compilerVersion: Locator;
    readonly evmVersion: Locator;
    readonly verifiedAt: Locator;
    readonly copySourceCodeButton: Locator;

    constructor(page: Page) {
        this.page = page;
        this.container = page.locator(SELECTORS.CONTAINER);
        this.verifyPublishButton = page.locator(SELECTORS.VERIFY_PUBLISH_BUTTON);
        this.contractName = page.locator(SELECTORS.CONTRACT_NAME);
        this.optimizationEnabled = page.locator(SELECTORS.OPTIMIZATION_ENABLED);
        this.compilerVersion = page.locator(SELECTORS.COMPILER_VERSION);
        this.evmVersion = page.locator(SELECTORS.EVM_VERSION);
        this.verifiedAt = page.locator(SELECTORS.VERIFIED_AT);
        this.copySourceCodeButton = page.locator(SELECTORS.COPY_SOURCE_CODE_BUTTON);
    }

    async clickVerifyPublish(): Promise<void> {
        return await this.verifyPublishButton.first().click();
    }

    async getContractName(): Promise<string> {
        const contractNameText = await this.contractName.textContent();
        if (!contractNameText) {
            throw new Error('Failed to fetch contract name.');
        }
        return contractNameText;
    }

    async getOptimizationEnabled(): Promise<string> {
        const optimizationText = await this.optimizationEnabled.textContent();
        if (optimizationText === null) {
            throw new Error('Failed to fetch optimization enabled status.');
        }
        return optimizationText;
    }

    async getCompilerVersion(): Promise<string> {
        const compilerVersionText = await this.compilerVersion.textContent();
        if (!compilerVersionText) {
            throw new Error('Failed to fetch compiler version.');
        }
        return compilerVersionText;
    }

    async getEvmVersion(): Promise<string> {
        const evmVersionText = await this.evmVersion.textContent();
        if (!evmVersionText) {
            throw new Error('Failed to fetch EVM version.');
        }
        return evmVersionText;
    }

    async getVerifiedAt(): Promise<string> {
        const verifiedAtText = await this.verifiedAt.textContent();
        if (!verifiedAtText) {
            throw new Error('Failed to fetch verification date and time.');
        }
        return verifiedAtText;
    }

    async clickCopySourceCode(): Promise<string> {
        await this.copySourceCodeButton.click();
        await this.page.waitForTimeout(1000);

        return await this.page.evaluate("navigator.clipboard.readText()") as string;
    }
}

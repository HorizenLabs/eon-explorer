import { Page, Locator } from '@playwright/test';;
import path from "path";
import { getContentFromFile } from "../utils/utils";

const SELECTORS = {
    CONTAINER: '.new-smart-contract-form',
    CONTRACT_ADDRESS: '[id="smart_contract_address_hash"]',
    VERIFY_METHOD_RADIO_BUTTONS: '.form-radios-group',
    VERIFY_OPTION: '.radio-big',
    NEXT_BUTTON: '[id="verify_via_flattened_code_button"]',
    CONTRACT_NAME: '[data-test="contract_name"]',
    COMPILER_VERSION: '[id="smart_contract_compiler_version"]',
    SOURCE_CODE: '[id="smart_contract_contract_source_code"]',
    VERIFY_PUBLISH_BUTTON: 'button:has-text("Verify & publish")',
    CONTRACT_NAME_INPUT: '[id="smart_contract_name"]',
    COMPILER_SELECT: '[id="smart_contract_compiler_version"]',
    CONTRACT_SOURCE_CODE: '[id="smart_contract_contract_source_code"]',
    OPTIMIZE_RADIO_NO: '#smart_contract_optimization_false',
    OPTIMIZE_RADIO_YES: '#smart_contract_optimization_true'
};

export class SmartContractVerificationForm {
    readonly page: Page;
    readonly container: Locator;
    readonly contractAddress: Locator;
    readonly verifyMethodRadioButtons: Locator;
    readonly verifyOption: Locator;
    readonly nextButton: Locator;
    readonly contractName: Locator;
    readonly compilerVersion: Locator;
    readonly sourceCode: Locator;
    readonly verifyPublishButton: Locator;
    readonly contractNameInput: Locator;
    readonly compilerSelect: Locator;
    readonly contractSourceCode: Locator;
    readonly optimizeRadioNo: Locator;
    readonly optimizeRadioYes: Locator;

    constructor(page: Page) {
        this.page = page;
        this.container = page.locator(SELECTORS.CONTAINER);
        this.contractAddress = page.locator(SELECTORS.CONTRACT_ADDRESS);
        this.verifyMethodRadioButtons = page.locator(SELECTORS.VERIFY_METHOD_RADIO_BUTTONS);
        this.verifyOption = page.locator(SELECTORS.VERIFY_OPTION);
        this.nextButton = page.locator(SELECTORS.NEXT_BUTTON);
        this.contractName = page.locator(SELECTORS.CONTRACT_NAME);
        this.compilerVersion = page.locator(SELECTORS.COMPILER_VERSION);
        this.sourceCode = page.locator(SELECTORS.SOURCE_CODE);
        this.verifyPublishButton = page.locator(SELECTORS.VERIFY_PUBLISH_BUTTON);
        this.contractNameInput = page.locator(SELECTORS.CONTRACT_NAME_INPUT)
        this.compilerSelect = page.locator(SELECTORS.COMPILER_SELECT);
        this.contractSourceCode = page.locator(SELECTORS.CONTRACT_SOURCE_CODE)
        this.optimizeRadioNo = page.locator(SELECTORS.OPTIMIZE_RADIO_NO);
        this.optimizeRadioYes = page.locator(SELECTORS.OPTIMIZE_RADIO_YES);
    }

    async clickNextButton(): Promise<void> {
        return await this.nextButton.click();
    }

    async enterContractName(contractName: string): Promise<void> {
        return await this.contractNameInput.fill(contractName);
    }

    async selectCompilerVersion819(): Promise<void> {
        await this.compilerSelect.selectOption('v0.8.19+commit.7dd6d404');
    }

    async pasteContractSourceCode(filePath: string): Promise<void> {
        try {
            const absolutePath = path.resolve(__dirname, filePath);
            const sourceCode = await getContentFromFile(absolutePath);
            await this.contractSourceCode.fill(sourceCode);
        } catch (error) {
            console.error(`Error reading file: ${error.message}`);
            throw error;
        }
    }

    async selectOptimizationNo(): Promise<void> {
        return await this.optimizeRadioNo.click();
    }

    async selectOptimizationYes(): Promise<void> {
        return await this.optimizeRadioYes.click();
    }

    async clickVerifyAndPublish(): Promise<void> {
        return await this.verifyPublishButton.click();
    }
}

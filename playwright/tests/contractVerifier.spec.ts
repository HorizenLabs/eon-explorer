import { test, expect } from '@playwright/test';
import { HomePage } from '../pages/HomePage';
import dotenv from 'dotenv';
import deployContract from "../web3/deployContract";
import { ValidatedTransactionsPage } from "../pages/ValidatedTransactionsPage";
import { SmartContractVerificationPage } from "../pages/SmartContractVerificationPage";
import { AddressDetailsPage } from "../pages/AddressDetailsPage";
import {getContentFromFile} from "../utils/utils";
import {compareStringsNormalized} from "../utils/stringUtils";
dotenv.config();

test.describe('Blockscout Contract Verification', () => {

    let homePage: HomePage;
    let validatedTransactionsPage: ValidatedTransactionsPage;
    let addressDetailsPage: AddressDetailsPage;
    let smartContractVerificationPage: SmartContractVerificationPage;

    test.beforeEach(async ({ page }) => {
        await page.context().grantPermissions(['clipboard-read', 'clipboard-write']);

        homePage = new HomePage(page);
        validatedTransactionsPage = new ValidatedTransactionsPage(page);
        addressDetailsPage = new AddressDetailsPage(page);
        smartContractVerificationPage = new SmartContractVerificationPage(page);
        await homePage.goto();
    });

    test('User can verify a deployed contract that they own, and see it verified on Blockscout', async ({ page }) => {
        const contractSourceCode = "../web3/contracts/lottery.sol";
        const contractName = "Lottery";
        const compilerVersion = "v0.8.19+commit.7dd6d404";
        const evmVersion = "paris";

        await homePage.goto();
        await homePage.transactions.clickViewAllTransactions();
        console.log("clicked view all transactions");
        const { contractAddress, transactionHash } = await deployContract(process.env.PK);

        const txRow = await validatedTransactionsPage.transactions.waitForTransactionWithHash(transactionHash, true)
        await txRow.clickToContractAddress();
        expect((await addressDetailsPage.addressOverview.getContractAddress()).match(contractAddress));

        await addressDetailsPage.addressTabDetails.clickCodeTab();
        await addressDetailsPage.addressTabDetails.codeTab.clickVerifyPublish();
        expect((await smartContractVerificationPage.form.contractAddress.innerText()).match(contractAddress));

        await smartContractVerificationPage.form.clickNextButton();
        await smartContractVerificationPage.form.enterContractName(contractName);
        await smartContractVerificationPage.form.selectOptimizationNo();
        await smartContractVerificationPage.form.selectCompilerVersion819();
        await smartContractVerificationPage.form.pasteContractSourceCode(contractSourceCode);
        await smartContractVerificationPage.form.clickVerifyAndPublish();

        expect((await addressDetailsPage.addressTabDetails.codeTab.getContractName()).match(contractName));
        expect((await addressDetailsPage.addressTabDetails.codeTab.getCompilerVersion()).match(compilerVersion));
        expect((await addressDetailsPage.addressTabDetails.codeTab.getEvmVersion()).match(evmVersion));

        const copiedSourceCode = await addressDetailsPage.addressTabDetails.codeTab.clickCopySourceCode();
        const fileContent = await getContentFromFile(contractSourceCode);
        expect(compareStringsNormalized(copiedSourceCode, fileContent)).toBeTruthy();
    });
});

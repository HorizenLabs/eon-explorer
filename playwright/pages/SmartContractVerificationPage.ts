import { Page } from '@playwright/test';
import { NavBar } from '../components/NavBar';
import { SmartContractVerificationForm } from "../components/SmartContractVerificationForm";
import dotenv from 'dotenv';

dotenv.config();

export class SmartContractVerificationPage {
    readonly page: Page;
    readonly navBar: NavBar;
    readonly form: SmartContractVerificationForm;


    constructor(page: Page) {
        this.page = page;
        this.navBar = new NavBar(page);
        this.form = new SmartContractVerificationForm(page);
    }

    async goto(contractAddress: string) {
        await this.page.goto(`/address/${contractAddress}/contract_verifications/new`);
    }
}

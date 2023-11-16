import { Page } from '@playwright/test';
import { NavBar } from '../components/NavBar';
import dotenv from 'dotenv';
import { AddressOverview } from "../components/AddressOverview";
import { AddressTabDetails } from "../components/AddressTabDetails";

dotenv.config();

export class AddressDetailsPage {
    readonly page: Page;
    readonly navBar: NavBar;
    readonly addressOverview: AddressOverview;
    readonly addressTabDetails: AddressTabDetails;

    constructor(page: Page) {
        this.page = page;
        this.navBar = new NavBar(page);
        this.addressOverview = new AddressOverview(page);
        this.addressTabDetails = new AddressTabDetails(page);
    }

    async goto() {
        await this.page.goto(`${process.env.BASE_URL}/txs`);
    }
}

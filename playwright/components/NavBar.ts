import { Page, Locator } from '@playwright/test';

const NAVBAR_SELECTORS = {
    HOME_LINK: 'a[data-test="header_logo"]',
    BLOCKS_LINK: 'a[href="/blocks"]',
    FORKED_BLOCKS_LINK: 'a[href="/reorgs"]',
    VALIDATED_TX_LINK: 'a[href="/txs"]',
    FORWARD_TRANSFERS_LINK: 'a[data-test="forward_transfers_link"]',
    BACKWARD_TRANSFERS_LINK: 'a[data-test="backward_transfers_link"]',
    FEE_PAYMENTS_LINK: 'a[data-test="fee_payments_link"]',
    PENDING_TX_LINK: 'a[data-test="pending_transactions_link"]',
    ALL_TOKENS_LINK: 'a[href="/tokens"]',
    ZEN_TOKEN_LINK: 'a[href="/accounts"]',
    GRAPHQL_API_LINK: 'a[href="/graphiql"]',
    RPC_API_LINK: 'a[href="/api-docs"]',
    ETH_RPC_API_LINK: 'a[href="/eth-rpc-api-docs"]',
    DARK_MODE: '#dark-mode-changer',
    SEARCH_INPUT: 'input#main-search-autocomplete',
    MOBILE_SEARCH_INPUT: 'input#main-search-autocomplete-mobile',
    SEARCH_ICON: '#search-icon',
};

export class NavBar {
    readonly page: Page;

    readonly homeLink: Locator;
    readonly blocksLink: Locator;
    readonly forkedBlocksLink: Locator;
    readonly validatedTxLink: Locator;
    readonly forwardTransfersLink: Locator;
    readonly backwardTransfersLink: Locator;
    readonly feePaymentsLink: Locator;
    readonly pendingTxLink: Locator;
    readonly allTokensLink: Locator;
    readonly zenTokenLink: Locator;
    readonly graphQLAPILink: Locator;
    readonly rpcAPILink: Locator;
    readonly ethRPCAPILink: Locator;
    readonly darkMode: Locator;
    readonly searchInput: Locator;
    readonly mobileSearchInput: Locator;
    readonly searchIcon: Locator;

    constructor(page: Page) {
        this.page = page;
        this.homeLink = page.locator(NAVBAR_SELECTORS.HOME_LINK);
        this.blocksLink = page.locator(NAVBAR_SELECTORS.BLOCKS_LINK);
        this.forkedBlocksLink = page.locator(NAVBAR_SELECTORS.FORKED_BLOCKS_LINK);
        this.validatedTxLink = page.locator(NAVBAR_SELECTORS.VALIDATED_TX_LINK);
        this.forwardTransfersLink = page.locator(NAVBAR_SELECTORS.FORWARD_TRANSFERS_LINK);
        this.backwardTransfersLink = page.locator(NAVBAR_SELECTORS.BACKWARD_TRANSFERS_LINK);
        this.feePaymentsLink = page.locator(NAVBAR_SELECTORS.FEE_PAYMENTS_LINK);
        this.pendingTxLink = page.locator(NAVBAR_SELECTORS.PENDING_TX_LINK);
        this.allTokensLink = page.locator(NAVBAR_SELECTORS.ALL_TOKENS_LINK);
        this.zenTokenLink = page.locator(NAVBAR_SELECTORS.ZEN_TOKEN_LINK);
        this.graphQLAPILink = page.locator(NAVBAR_SELECTORS.GRAPHQL_API_LINK);
        this.rpcAPILink = page.locator(NAVBAR_SELECTORS.RPC_API_LINK);
        this.ethRPCAPILink = page.locator(NAVBAR_SELECTORS.ETH_RPC_API_LINK);
        this.darkMode = page.locator(NAVBAR_SELECTORS.DARK_MODE);
        this.searchInput = page.locator(NAVBAR_SELECTORS.SEARCH_INPUT);
        this.mobileSearchInput = page.locator(NAVBAR_SELECTORS.MOBILE_SEARCH_INPUT);
        this.searchIcon = page.locator(NAVBAR_SELECTORS.SEARCH_ICON);
    }

    async clickHomeLink() {
        await this.homeLink.click();
    }

    async clickBlocksLink() {
        await this.blocksLink.click();
    }

    async clickForkedBlocksLink() {
        await this.forkedBlocksLink.click();
    }

    async clickValidatedTransactionsLink() {
        await this.validatedTxLink.click();
    }

    async clickForwardTransfersLink() {
        await this.forwardTransfersLink.click();
    }

    async clickBackwardTransfersLink() {
        await this.backwardTransfersLink.click();
    }

    async clickFeePaymentsLink() {
        await this.feePaymentsLink.click();
    }

    async clickPendingTransactionsLink() {
        await this.pendingTxLink.click();
    }

    async clickAllTokensLink() {
        await this.allTokensLink.click();
    }

    async clickZENTokenLink() {
        await this.zenTokenLink.click();
    }

    async clickGraphQLAPIsLink() {
        await this.graphQLAPILink.click();
    }

    async clickRPCAPIsLink() {
        await this.rpcAPILink.click();
    }

    async clickEthRPCAPIsLink() {
        await this.ethRPCAPILink.click();
    }

    async toggleDarkMode() {
        await this.darkMode.click();
    }

    async search(query: string, isMobile: boolean = false) {
        const searchInputLocator = isMobile ? this.mobileSearchInput : this.searchInput;

        await searchInputLocator.fill(query);
        await this.searchIcon.click();
    }
}

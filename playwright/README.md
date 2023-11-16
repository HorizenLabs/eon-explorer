# Playwright E2E Testing Template Repository

This repository is a template for end-to-end tests using Playwright. The structure follows best practices to ensure maintainability, readability, and scalability.

##  Directory Structure Overview

### `tests/`
Contains the test specifications, organized by feature or page functionality.
- Examples: `authentication/`, `search/`

### `pages/`
Houses the Page Object Models (POM). 
Each file represents a specific page of the application and will include reusable Components and provides methods to interact with its elements.
- Examples: `LoginPage.ts`, `DashboardPage.ts`

### `components/`
Contains Component Models. Each file represents reusable components that might appear on multiple pages. Useful for elements like headers, footers, or custom widgets.
- Examples: `HeaderComponent.ts`, `SearchBar.ts`

### `utils/`
Utility functions and helper scripts that are used across multiple tests or configurations.

### `web3/`
Functions requiring the web3 library.

### `fixtures/`
Static data or mock data used in tests.


## Getting Started

1. **Installation** 
   Install the necessary dependencies:
   ```bash
   npm install
2. **Download Browser Drivers**
   ```bash
   npx playwright install
3. **Running Tests**
   Execute the tests using the following command:
   ```bash
   npm test
4. **Specific Tests**
   ```bash
   npx playwright test landing-page.spec.ts
5. **Headed**
   Tests run headless by default, to override:
   ```bash
   npm run test -- --headed
   npx playwright test --headed
6. **Pause**
   Pause the test to debug at the end of a headed run, to inspect the page manually.
   ```bash
     await new Promise((resolve) => {
     page.on('close', resolve);
     });
7. **Configuration**
   Any specific Playwright configuration or global settings can be modified in the config/playwright.config.ts file.

## Contributing

1. Determine if it relates to an existing page or component. If not, consider creating a new Page or Component model.
2. Consider adding more complex page specific interactions through the pages models and not into the tests especially if they would be reused.
3. For any additional configurations or utilities, please place them in the appropriate directory and ensure they are well-documented.
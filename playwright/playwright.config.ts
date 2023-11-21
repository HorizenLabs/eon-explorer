import { PlaywrightTestConfig } from '@playwright/test';

const config: PlaywrightTestConfig = {
    projects: [
        {
            name: 'chrome',
            use: {
                channel: 'chrome',
                headless: true,
                viewport: { width: 1280, height: 720 },
                video: 'on',
            },
        },
    ],
    timeout: 1200000,
    testDir: './tests',
};

export default config;

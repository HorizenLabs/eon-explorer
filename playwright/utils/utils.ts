import path from "path";
import { promises as fs } from 'fs';

export const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

export async function getContentFromFile(filePath: string): Promise<string> {
    try {
        const absolutePath = path.resolve(__dirname, filePath);
        return await fs.readFile(absolutePath, { encoding: 'utf8' });
    } catch (error) {
        console.error(`Error reading file: ${error.message}`);
        throw error;
    }
}

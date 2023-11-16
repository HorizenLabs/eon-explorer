export async function isTimestampValid(timeStampText: string): Promise<boolean> {
    const match = timeStampText.match(/^(\d{0,2}|a) (minute|second)s? ago$/);

    if (!match) {
        throw new Error(`Timestamp validation failed. Received timestamp: "${timeStampText}"`);
    }

    return true;
}

export function compareStringsNormalized(string1: string, string2: string): boolean {
    const normalizeString = (str: string) => str.replace(/\r\n/g, "\n");
    const normalizedString1 = normalizeString(string1);
    const normalizedString2 = normalizeString(string2);

    return normalizedString1 === normalizedString2;
}
import 'dotenv/config'

export const privateKey = process.env.PRIVATE_KEY!
export const apiKey = process.env.ETHER_SCAN_API_KEY!
export const qtumData = {
    tokenName: 'TEST QTUM',
    tokenSymbol: 'QTUM',
}
export const xqtumData = {
    tokenName: 'TEST XQTUM',
    tokenSymbol: 'XQTUM',
    reedemFee1: 3n,
    reedemFee2: 2n,
    penaltyFee: 2n
}
export const ninjaData = {
    tokenName: 'TEST NINJA',
    tokenSymbol: 'NINJ',
    price: 5n,
    claimPeriod: 6n * 3600n,
    purchase: 1209600n,
    baseTokenURI: ''
}
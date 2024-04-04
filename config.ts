import 'dotenv/config'

export const privateKey = process.env.PRIVATE_KEY!
export const apiKey = process.env.ETHER_SCAN_API_KEY!
export const qtumData = {
    tokenName: 'TEST QTUM',
    tokenSymbol: 'QTUM',
    price: 1000000000000000n
}
export const xqtumData = {
    tokenName: 'TEST XQTUM',
    tokenSymbol: 'XQTUM',
    reedemFee: 2n,
    penaltyFee: 2n
}
export const ninjaData = {
    tokenName: 'TEST NINJA',
    tokenSymbol: 'NINJ',
    price: 5n,
    baseTokenURI:''
}
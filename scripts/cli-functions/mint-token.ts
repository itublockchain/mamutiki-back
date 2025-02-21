import { initSDK } from "./init-sdk";

export default async function mintToken(amount: number) {
  try {
    const sdk = await initSDK();

    const txn_register = await sdk.account.register();
    const txn_mint = await sdk.account.mintToken(amount);
    console.log("Token mintleniyor...");
    console.log("Transaction Hash Register:", txn_register);
    console.log("Transaction Hash Mint:", txn_mint);
  } catch (error) {
    console.error("Token mintlenirken bir hata oluştu:", error);
    throw error;
  }
}

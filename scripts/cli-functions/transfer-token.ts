import { initSDK } from "./init-sdk";

export default async function transferToken(amount: number, recipient: string) {
  try {
    const sdk = await initSDK();

    const txn_transfer = await sdk.account.transferToken(amount, recipient);
    console.log("Token transferleniyor...");

    console.log("Transaction Hash Transfer:", txn_transfer);
  } catch (error) {
    console.error("Token transferlenirken bir hata oluştu:", error);
    throw error;
  }
}

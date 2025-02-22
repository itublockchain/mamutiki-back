import { initSDK } from "./init-sdk";

export default async function register() {
  try {
    const sdk = await initSDK();

    const txn_register = await sdk.account.register();
    console.log("Registerleniyor...");

    console.log("Transaction Hash Register:", txn_register);
  } catch (error) {
    console.error("Registerlenirken bir hata oluştu:", error);
    throw error;
  }
}

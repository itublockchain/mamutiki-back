import { initSDK } from "./init-sdk";

export default async function addTrustedKey(publicKey: string) {
  try {
    const sdk = await initSDK();

    console.log("\nGüvenilir anahtar ekleniyor...");
    console.log("Public Key:", publicKey);

    const txn = await sdk.contribution.addTrustedKey(publicKey);
    console.log("\nGüvenilir anahtar başarıyla eklendi!");
    console.log("Transaction Hash:", txn);
  } catch (error) {
    console.error("Güvenilir anahtar eklenirken bir hata oluştu:", error);
    throw error;
  }
}

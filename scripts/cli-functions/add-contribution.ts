import { initSDK } from "./init-sdk";
import { DEFAULT_VALUES } from "../utils/constants";
import DataSigner from "../classes/DataSigner";

export default async function addContribution(campaignID_string: string) {
  try {
    const sdk = await initSDK();

    const dataSigner = new DataSigner();

    const campaignId = parseInt(campaignID_string);
    const { dataCount, storeCid, score, keyForDecryption } =
      DEFAULT_VALUES.contribution;

    // Katkı verilerini imzala
    const signature = dataSigner.signContributionData(
      sdk._account.accountAddress.toString(),
      campaignId,
      dataCount,
      storeCid,
      score,
      keyForDecryption
    );

    console.log("\nKatkı ekleniyor...");
    console.log("Sender:", sdk._account.accountAddress);
    console.log("Campaign ID:", campaignId);
    console.log("Data Count:", dataCount);
    console.log("Store CID:", storeCid);
    console.log("Score:", score);
    console.log("Key For Decryption:", keyForDecryption);
    console.log("Signature:", signature);

    const txn = await sdk.contribution.addContribution(
      campaignId,
      dataCount,
      storeCid,
      score,
      keyForDecryption,
      signature
    );
    console.log("\nKatkı başarıyla eklendi!");
    console.log("Transaction Hash:", txn);
  } catch (error) {
    console.error("Katkı eklenirken bir hata oluştu:", error);
    throw error;
  }
}

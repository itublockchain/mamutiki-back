import { initSDK } from "./init-sdk";
import { DEFAULT_VALUES } from "../utils/constants";


export default async function createCampaign() {
  try {
    const sdk = await initSDK();

    const {
      title,
      description,
      prompt,
      unitPrice,
      minContribution,
      rewardPool,
      publicKeyForEncryption,
    } = DEFAULT_VALUES.campaign;

    // APT miktarlarını octa'ya çevirme (1 APT = 100_000_000 octa)
    const unitPriceOcta = Math.floor(unitPrice * 100_000_000);
    const rewardPoolOcta = Math.floor(rewardPool * 100_000_000);
    const minContribOcta = Math.floor(minContribution * 100_000_000);

    console.log("\nKampanya oluşturuluyor...");
    console.log("Title:", title);
    console.log("Description:", description);
    console.log("Prompt:", prompt);
    console.log("Unit Price:", unitPrice, "APT");
    console.log("Minimum Contribution:", minContribution, "APT");
    console.log("Reward Pool:", rewardPool, "APT");
    console.log("Public Key for Encryption:", publicKeyForEncryption);

    const txn = await sdk.campaign.createCampaign(
      title,
      description,
      prompt,
      unitPriceOcta,
      minContribOcta,
      rewardPoolOcta,
      publicKeyForEncryption
    );
    console.log("\nKampanya başarıyla oluşturuldu!");
    console.log("Transaction Hash:", txn);
  } catch (error) {
    console.error("Kampanya oluşturulurken bir hata oluştu:", error);
    throw error;
  }
}

import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import { DEFAULT_VALUES } from "../../utils/constants";
import cli from "../";

export default async function createCampaign() {
  try {
    const sdk = await initSDK();
    await cli.showAccountInformation(sdk);

    const {
      title,
      description,
      prompt,
      unitPrice,
      minContribution,
      minScore,
      rewardPool,
      publicKeyForEncryption,
    } = DEFAULT_VALUES.campaign;

    // APT miktarlarını octa'ya çevirme (1 APT = 100_000_000 octa)
    const unitPriceOcta = Math.floor(unitPrice * 100_000_000);
    const rewardPoolOcta = Math.floor(rewardPool * 100_000_000);
    const minContribOcta = Math.floor(minContribution * 100_000_000);

    terminal.log("\nCreating campaign...");
    terminal.log("Title:", title);
    terminal.log("Description:", description);
    terminal.log("Prompt:", prompt);
    terminal.log("Unit Price:", unitPrice, "$DATA");
    terminal.log("Minimum Contribution:", minContribution, "$DATA");
    terminal.log("Reward Pool:", rewardPool, "$DATA");

    const txn = await sdk.campaign.createCampaign(
      title,
      description,
      prompt,
      unitPriceOcta,
      minContribOcta,
      minScore,
      rewardPoolOcta,
      publicKeyForEncryption
    );
    terminal.log("\nCampaign created successfully!");
    terminal.log("Transaction Hash:", txn);
  } catch (error) {
    console.error("Error while creating campaign:", error);
    throw error;
  }
}

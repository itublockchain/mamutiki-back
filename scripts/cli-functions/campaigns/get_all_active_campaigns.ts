import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import cli from "../";

export default async function getAllActiveCampaigns() {
  try {
    const sdk = await initSDK();
    await cli.showAccountInformation(sdk);

    terminal.log("\nAktif kampanyalar listeleniyor...");

    const campaigns = await sdk.campaign.getAllActiveCampaigns();

    if (campaigns.length === 0) {
      terminal.log("Henüz hiç kampanya oluşturulmamış.");
      return;
    }

    campaigns.forEach((campaign, index) => {
      terminal.log(`\nKampanya #${index + 1}:`);
      terminal.log("ID:", campaign.id);
      terminal.log("Creator:", campaign.creator);
      terminal.log("Title:", campaign.title);
      terminal.log("Description:", campaign.description);
      terminal.log("Prompt:", campaign.prompt);
      terminal.log("Reward Pool:", campaign.reward_pool / 100_000_000, "Move");
      terminal.log(
        "Remaining Reward:",
        campaign.remaining_reward / 100_000_000,
        "Move"
      );
      terminal.log("Unit Price:", campaign.unit_price / 100_000_000, "Move");
      terminal.log(
        "Minimum Contribution:",
        campaign.minimum_contribution / 100_000_000,
        "Move"
      );
      terminal.log("Active:", campaign.active);
      terminal.log("----------------------------------------");
    });
  } catch (error) {
    console.error("Kampanyalar listelenirken bir hata oluştu:", error);
    throw error;
  }
}

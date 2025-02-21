import { initSDK } from "./init-sdk";

export default async function listCampaigns() {
  try {
    const sdk = await initSDK();

    console.log("\nKampanyalar listeleniyor...");

    const campaigns = await sdk.campaign.getAllCampaigns();

    if (campaigns.length === 0) {
      console.log("Henüz hiç kampanya oluşturulmamış.");
      return;
    }

    campaigns.forEach((campaign, index) => {
      console.log(`\nKampanya #${index + 1}:`);
      console.log("ID:", campaign.id);
      console.log("Creator:", campaign.creator);
      console.log("Title:", campaign.title);
      console.log("Description:", campaign.description);
      console.log("Prompt:", campaign.prompt);
      console.log("Reward Pool:", campaign.reward_pool / 100_000_000, "Move");
      console.log(
        "Remaining Reward:",
        campaign.remaining_reward / 100_000_000,
        "Move"
      );
      console.log("Unit Price:", campaign.unit_price / 100_000_000, "Move");
      console.log(
        "Minimum Contribution:",
        campaign.minimum_contribution / 100_000_000,
        "Move"
      );
      console.log("Active:", campaign.active);
      console.log("----------------------------------------");
    });
  } catch (error) {
    console.error("Kampanyalar listelenirken bir hata oluştu:", error);
    throw error;
  }
}

import { initSDK } from "./init-sdk";

export default async function addTrustedKey(campaignId_string: string) {
  try {
    const sdk = await initSDK();

    const campaignId = parseInt(campaignId_string);
    console.log(`\nKampanya #${campaignId} katkıları listeleniyor...`);

    const contributions = await sdk.contribution.getCampaignContributions(
      campaignId
    );

    if (contributions.length === 0) {
      console.log("Bu kampanyaya henüz katkı yapılmamış.");
      return;
    }

    contributions.forEach((contribution, index) => {
      console.log(`\nKatkı #${index + 1}:`);
      console.log("Campaign ID:", contribution.campaign_id);
      console.log("Contributor:", contribution.contributor);
      console.log("Data Count:", contribution.data_count);
      console.log("Store CID:", contribution.store_cid);
      console.log("Score:", contribution.score);
      console.log("----------------------------------------");
    });
  } catch (error) {
    console.error("Katkılar listelenirken bir hata oluştu:", error);
    throw error;
  }
}

import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import inquirer from "inquirer";

import cli from "..";

export default async function addTrustedKey() {
  try {
    const [sdk, { input_campaignID }] = await Promise.all([
      initSDK(),
      inquirer.prompt([
        {
          type: "input",
          name: "input_campaignID",
          message: "Select campaign by ID:",
        },
      ]),
    ]);
    await cli.showAccountInformation(sdk);

    const campaignId = parseInt(input_campaignID);
    terminal.log(`\nKampanya #${campaignId} katkıları listeleniyor...`);

    const contributions = await sdk.contribution.getCampaignContributions(
      campaignId
    );

    if (contributions.length === 0) {
      terminal.log("Bu kampanyaya henüz katkı yapılmamış.");
      return;
    }

    contributions.forEach((contribution, index) => {
      terminal.log(`\nKatkı #${index + 1}:`);
      terminal.log("Campaign ID:", contribution.campaign_id);
      terminal.log("Contributor:", contribution.contributor);
      terminal.log("Data Count:", contribution.data_count);
      terminal.log("Store CID:", contribution.store_cid);
      terminal.log("Score:", contribution.score);
      terminal.log("----------------------------------------");
    });
  } catch (error) {
    console.error("Katkılar listelenirken bir hata oluştu:", error);
    throw error;
  }
}

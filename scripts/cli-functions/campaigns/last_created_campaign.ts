import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import cli from "../";
import inquirer from "inquirer";

export default async function listCampaigns() {
  try {
    const [sdk, { address }] = await Promise.all([
      initSDK(),
      inquirer.prompt([
        {
          type: "input",
          name: "address",
          message: "Address:",
        },
      ]),
    ]);

    await cli.showAccountInformation(sdk);

    terminal.log("\nListing campaigns...");

    const campaign = await sdk.campaign.lastCreatedCampaign(address);

    if (!campaign) {
      terminal.log("No campaigns created yet.");
      return;
    }

    terminal.log("ID:", campaign.id);
    terminal.log("Creator:", campaign.creator);
    terminal.log("Title:", campaign.title);
    terminal.log("Description:", campaign.description);
    terminal.log("Prompt:", campaign.prompt);
    terminal.log("Reward Pool:", campaign.reward_pool / 100_000_000, "$DATA");
    terminal.log(
      "Remaining Reward:",
      campaign.remaining_reward / 100_000_000,
      "$DATA"
    );
    terminal.log("Unit Price:", campaign.unit_price / 100_000_000, "$DATA");
    terminal.log(
      "Minimum Contribution:",
      campaign.minimum_contribution / 100_000_000,
      "$DATA"
    );
    terminal.log("Active:", campaign.active);
    terminal.log("----------------------------------------");
  } catch (error) {
    console.error("Error while listing campaigns:", error);
    throw error;
  }
}

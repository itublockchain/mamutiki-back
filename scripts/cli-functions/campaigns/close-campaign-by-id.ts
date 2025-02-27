import inquirer from "inquirer";
import terminal from "../../utils/console";
import { initSDK } from "../../utils/init-sdk";

export default async function closeCampaignById() {
  const [sdk, { id_campaign }] = await Promise.all([
    initSDK(),
    inquirer.prompt([
      {
        type: "input",
        name: "id_campaign",
        message: "Enter the campaign id:",
      },
    ]),
  ]);

  const [campaign, tx] = await sdk.campaign.closeCampaignById(id_campaign);

  if (!campaign) {
    terminal.error("Campaign not found");
    return;
  }

  terminal.write("Campaign closed successfully:");
  terminal.write(JSON.stringify(campaign, null, 2));
  terminal.write("Transaction hash:", tx);

  terminal.log(`Closing campaign with id: ${id_campaign}`);
}

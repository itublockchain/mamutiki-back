import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import inquirer from "inquirer";
import cli from "../";

export default async function transferToken() {
  try {
    const [sdk, { input_amount, input_recipient }] = await Promise.all([
      initSDK(),
      inquirer.prompt([
        {
          type: "input",
          name: "input_amount",
          message: "Choose amount of token to transfer:",
        },
        {
          type: "input",
          name: "input_recipient",
          message: "Enter the recipient's public key:",
        },
      ]),
    ]);
    await cli.showAccountInformation(sdk);

    const amount = parseInt(input_amount);
    const recipient = String(input_recipient);

    const txn_transfer = await sdk.account.transferToken(amount, recipient);
    terminal.log("Token transferleniyor...");

    terminal.log("Transaction Hash Transfer:", txn_transfer);
  } catch (error) {
    console.error("Token transferlenirken bir hata oluştu:", error);
    throw error;
  }
}

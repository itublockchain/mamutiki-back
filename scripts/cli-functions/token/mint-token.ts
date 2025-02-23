import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import inquirer from "inquirer";
import cli from "../";

export default async function mintToken() {
  try {
    const [sdk, { input_amount }] = await Promise.all([
      initSDK(),
      inquirer.prompt([
        {
          type: "input",
          name: "input_amount",
          message: "Choose amount of token to mint:",
        },
      ]),
    ]);
    await cli.showAccountInformation(sdk);

    const amount = parseInt(input_amount);

    const txn_mint = await sdk.account.mint(amount);
    terminal.log("Token mintleniyor...");
    terminal.log("Transaction Hash Mint:", txn_mint);
  } catch (error) {
    console.error("Token mintlenirken bir hata oluştu:", error);
    throw error;
  }
}

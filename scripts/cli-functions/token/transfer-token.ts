import { tokenSDK } from "../../utils/init-token-sdk";
import terminal from "../../utils/console";

import inquirer from "inquirer";

export default async function transferToken() {
  try {
    const [{ token }, { input_amount, input_recipient }] = await Promise.all([
      tokenSDK(),
      inquirer.prompt([
        {
          type: "input",
          name: "input_amount",
          message: "Choose amount of token to transfer:",
        },
        {
          type: "input",
          name: "input_recipient",
          message: "Enter the recipient's account address:",
        },
      ]),
    ]);

    const amount = parseInt(input_amount);
    const recipient = String(input_recipient);

    const txn_transfer = await token.transferToken(amount, recipient);
    terminal.log("Token is being transferred...");

    terminal.log("Transaction Hash Transfer:", txn_transfer);
  } catch (error) {
    console.error("Error while transferring token:", error);
    throw error;
  }
}

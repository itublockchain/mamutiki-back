import { tokenSDK } from "../../utils/init-token-sdk";
import terminal from "../../utils/console";

import inquirer from "inquirer";

export default async function mintToken() {
  try {
    const [{ token }, { input_amount }] = await Promise.all([
      tokenSDK(),
      inquirer.prompt([
        {
          type: "input",
          name: "input_amount",
          message: "Choose amount of token to mint:",
        },
      ]),
    ]);

    const amount = parseInt(input_amount);

    const txn_mint = await token.mint(amount);
    terminal.log("Token is being minted...");
    terminal.log("Transaction Hash Mint:", txn_mint);
  } catch (error) {
    console.error("Error while minting token:", error);
    throw error;
  }
}

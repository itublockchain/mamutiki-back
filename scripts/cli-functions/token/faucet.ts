import { tokenSDK } from "../../utils/init-token-sdk";
import terminal from "../../utils/console";

import inquirer from "inquirer";

export default async function mintToken() {
  try {
    const [{ token }, { token: faucet }, { faucet_action }] = await Promise.all(
      [
        tokenSDK(),
        tokenSDK({ isFaucet: true }),
        inquirer.prompt([
          {
            type: "rawlist",
            name: "faucet_action",
            message: "Do you want to lock / unlock the faucet?",
            choices: [
              { name: "Lock the faucet", value: 1 },
              { name: "Unlock the faucet", value: 2 },
              { name: "No, only give me $DATA", value: 3 },
            ],
          },
        ]),
      ]
    );

    switch (faucet_action) {
      case 1:
        terminal.write("Transaction hash:", await faucet.lockFaucet());
        break;
      case 2:
        terminal.write("Transaction hash:", await faucet.unlockFaucet());
        break;
      case 3:
        terminal.write("Transaction hash:", await token.faucet());
        break;
    }

    terminal.log("Faucet operation completed successfully.");
  } catch (error) {
    console.error("Error while performing faucet operation:", error);
    throw error;
  }
}

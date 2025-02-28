import { initSDK } from "../../utils/init-sdk";
import inquirer from "inquirer";

import cli from "..";

import terminal, { isTest } from "../../utils/console";

export default async function removeTrustedKey() {
  try {
    const [sdk, { publicKey }] = await Promise.all([
      initSDK({ moduleAccount: true }),
      inquirer.prompt([
        {
          type: "input",
          name: "publicKey",
          message: "Enter the public key of trusted key to remove:",
        },
      ]),
    ]);

    await cli.showAccountInformation(sdk);

    terminal.log("\nRemoving trusted key...");
    terminal.log("Public Key:", publicKey);

    const txn = await sdk.contribution.removeTrustedKey(publicKey);
    terminal.write("\nTrusted key removed successfully!");
    terminal.write("Transaction Hash:", txn);
  } catch (error) {
    terminal.write("Error while removing trusted key!");
    terminal.error(error);

    if (isTest) throw error;
  }
}

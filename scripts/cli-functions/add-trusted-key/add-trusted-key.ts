import { initSDK } from "../../utils/init-sdk";
import inquirer from "inquirer";

import cli from "../";

import terminal, { isTest } from "../../utils/console";

export default async function addTrustedKey() {
  try {
    const [sdk, { publicKey }] = await Promise.all([
      initSDK(),
      inquirer.prompt([
        {
          type: "input",
          name: "publicKey",
          message: "Enter the public key of the trusted key:",
        },
      ]),
    ]);

    await cli.showAccountInformation(sdk);

    terminal.log("\nGüvenilir anahtar ekleniyor...");
    terminal.log("Public Key:", publicKey);

    const txn = await sdk.contribution.addTrustedKey(publicKey);
    terminal.write("\nGüvenilir anahtar başarıyla eklendi!");
    terminal.write("Transaction Hash:", txn);
  } catch (error) {
    terminal.write("Güvenilir anahtar eklenirken bir hata oluştu!");
    terminal.error(error);

    if (isTest) throw error;
  }
}

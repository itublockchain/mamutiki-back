import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import { DEFAULT_VALUES } from "../../utils/constants";
import DataSigner from "../../classes/DataSigner";

import cli from "..";

import inquirer from "inquirer";

export default async function addContribution() {
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

    const dataSigner = new DataSigner();

    const campaignId = parseInt(input_campaignID);
    const { dataCount, storeCid, score, keyForDecryption } =
      DEFAULT_VALUES.contribution;

    // Katkı verilerini imzala
    const signature = dataSigner.signContributionData(
      sdk._account.accountAddress.toString(),
      campaignId,
      dataCount,
      storeCid,
      score,
      keyForDecryption
    );

    terminal.log("\nKatkı ekleniyor...");
    terminal.log("Sender:", sdk._account.accountAddress);
    terminal.log("Campaign ID:", campaignId);
    terminal.log("Data Count:", dataCount);
    terminal.log("Store CID:", storeCid);
    terminal.log("Score:", score);
    terminal.log("Key For Decryption:", keyForDecryption);
    terminal.log("Signature:", signature);

    const txn = await sdk.contribution.addContribution(
      campaignId,
      dataCount,
      storeCid,
      score,
      keyForDecryption,
      signature
    );
    terminal.log("\nKatkı başarıyla eklendi!");
    terminal.log("Transaction Hash:", txn);
  } catch (error) {
    console.error("Katkı eklenirken bir hata oluştu:", error);
    throw error;
  }
}

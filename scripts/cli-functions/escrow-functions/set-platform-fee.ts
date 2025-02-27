import inquirer from "inquirer";
import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

async function setPlatformFee() {
  const [sdk, { input_fee }] = await Promise.all([
    initSDK({ moduleAccount: true }),
    inquirer.prompt([
      {
        type: "input",
        name: "input_fee",
        message: "Enter the new platform fee:",
      },
    ]),
  ]);

  const fee = parseInt(input_fee);
  terminal.log(`Setting platform fee to ${fee}`);

  const txn = await sdk.escrow.setPlatformFee(fee);
  terminal.log(`Transaction hash: ${txn}`);
}

export default setPlatformFee;

import inquirer from "inquirer";
import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

async function setSubscriberPlatformFee() {
  const [sdk, { input_fee }] = await Promise.all([
    initSDK({ moduleAccount: true }),
    inquirer.prompt([
      {
        type: "input",
        name: "input_fee",
        message: "Enter the new platform fee for subscribers:",
      },
    ]),
  ]);

  const fee = parseInt(input_fee);
  terminal.log(`Setting platform fee for subscribers to ${fee}`);

  const txn = await sdk.escrow.setPlatformFeeForSubscribers(fee);
  terminal.log(`Transaction hash: ${txn}`);
}

export default setSubscriberPlatformFee;

import inquirer from "inquirer";
import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

async function setPlatformFeeDivisor() {
  const [sdk, { input_divisor }] = await Promise.all([
    initSDK({ moduleAccount: true }),
    inquirer.prompt([
      {
        type: "input",
        name: "input_divisor",
        message: "Enter the new platform fee divisor:",
      },
    ]),
  ]);

  const divisor = parseInt(input_divisor);
  terminal.log(`Setting platform fee divisor to ${divisor}`);

  const txn = await sdk.escrow.setPlatformFeeDivisor(divisor);
  terminal.log(`Transaction hash: ${txn}`);
}

export default setPlatformFeeDivisor;

import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import cli from "../";

export default async function register() {
  try {
    const sdk = await initSDK();
    await cli.showAccountInformation(sdk);

    const txn_register = await sdk.account.register();
    terminal.log("Registerleniyor...");

    terminal.log("Transaction Hash Register:", txn_register);
  } catch (error) {
    console.error("Registerlenirken bir hata oluştu:", error);
    throw error;
  }
}

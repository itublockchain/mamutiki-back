import { tokenSDK } from "../../utils/init-token-sdk";
import terminal from "../../utils/console";

import cli from "../";
import { initSDK } from "utils/init-sdk";

export default async function register() {
  try {
    const { token } = await tokenSDK();

    const txn_register = await token.register();
    terminal.log("Registerleniyor...");

    terminal.log("Transaction Hash Register:", txn_register);
  } catch (error) {
    console.error("Registerlenirken bir hata oluştu:", error);
    throw error;
  }
}

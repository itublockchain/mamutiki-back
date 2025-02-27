import { TokenSDK } from "./AptosMoveSDK";
import terminal from "./console";

export async function tokenSDK(props?: { isFaucet?: boolean }) {
  try {
    const sdk = new TokenSDK();

    // Get the private key from env and create the account
    const ACCOUNT_PRIVATE_KEY = props?.isFaucet
      ? process.env.TOKEN_MODULE_PRIVATE_KEY
      : process.env.ACCOUNT_PRIVATE_KEY;
    if (!ACCOUNT_PRIVATE_KEY) {
      throw new Error("ACCOUNT_PRIVATE_KEY environment variable not found!");
    }

    const account = sdk.setAccount(ACCOUNT_PRIVATE_KEY);

    return { ...sdk, _account: account };
  } catch (error) {
    terminal.error("Error while initializing token SDK:", error);
    throw error;
  }
}

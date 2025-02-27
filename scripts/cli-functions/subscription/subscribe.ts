import terminal from "../../utils/console";
import { initSDK } from "../../utils/init-sdk";

import cli from "../";

export default async function subscribe() {
  try {
    const sdk = await initSDK();
    await cli.showAccountInformation(sdk);

    terminal.log("\nSubscription process has started...");
    const txn = await sdk.subscription.subscribe();

    terminal.log("\n✅ Subscription succesfully has been done!");
    terminal.log("Transaction Hash:", txn);

    // Check subscription state
    const [isActive, remainingTime] = await sdk.subscription.checkSubscription(
      sdk._account.accountAddress.toString()
    );
    if (isActive) {
      terminal.log(`\nSubscription State: Active`);
      terminal.log(
        `Remaining: ${Math.floor(remainingTime / 86400)} day ${Math.floor(
          (remainingTime % 86400) / 3600
        )} hour.`
      );
    }
  } catch (error: any) {
    console.error(
      "\n❌ An unexpected error happened while trying to subscribe:"
    );
    if (error.message) {
      console.error("Error message:", error.message);
    } else {
      console.error(error);
    }
    throw error;
  }
}

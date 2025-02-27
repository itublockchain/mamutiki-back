import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import { DEFAULT_VALUES } from "../../utils/constants";

export default async function updatePrice() {
  try {
    const sdk = await initSDK({ moduleAccount: true });

    const newPrice = DEFAULT_VALUES.subscription.price;
    const priceInOcta = newPrice * 10 ** 6;

    terminal.log(
      `\nUpdating price: ${newPrice} DATA (${priceInOcta} Octa)`
    );
    const txn = await sdk.subscription.updatePrice(priceInOcta);

    terminal.write(
      `\n✅ Subscription price has been succesfully updated! (${newPrice} DATA)`
    );
    terminal.log("Transaction Hash:", txn);
  } catch (error: any) {
    terminal.error("\n❌ An unexpected error happened at update-price.ts:");

    if (error.message) {
      terminal.error("Error message:", error.message);
    } else {
      terminal.error(error);
    }
    throw error;
  }
}

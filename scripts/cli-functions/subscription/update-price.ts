import { initSDK } from "../../utils/init-sdk";
import terminal from "../../utils/console";

import { DEFAULT_VALUES } from "../../utils/constants";
import cli from "../";

export default async function updatePrice() {
  try {
    const sdk = await initSDK();
    await cli.showAccountInformation(sdk);

    const newPrice = DEFAULT_VALUES.subscription.price;
    const priceInOcta = newPrice * 100_000_000;

    terminal.log(
      `\nFiyat güncelleniyor: ${newPrice} APT (${priceInOcta} Octa)`
    );
    const txn = await sdk.subscription.updatePrice(priceInOcta);

    terminal.log("\n✅ Abonelik fiyatı başarıyla güncellendi!");
    terminal.log("Transaction Hash:", txn);
  } catch (error: any) {
    console.error("\n❌ Fiyat güncellenirken bir hata oluştu:");
    if (error.message) {
      console.error("Hata mesajı:", error.message);
    } else {
      console.error(error);
    }
    throw error;
  }
}

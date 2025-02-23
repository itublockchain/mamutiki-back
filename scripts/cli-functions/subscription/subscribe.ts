import terminal from "../../utils/console";
import { initSDK } from "../../utils/init-sdk";

import cli from "../";

export default async function subscribe() {
  try {
    const sdk = await initSDK();
    await cli.showAccountInformation(sdk);

    terminal.log("\nAbonelik işlemi başlatılıyor...");
    const txn = await sdk.subscription.subscribe();

    terminal.log("\n✅ Abonelik başarıyla oluşturuldu!");
    terminal.log("Transaction Hash:", txn);

    // Abonelik durumunu kontrol et
    const [isActive, remainingTime] = await sdk.subscription.checkSubscription(
      sdk._account.accountAddress.toString()
    );
    if (isActive) {
      terminal.log(`\nAbonelik Durumu: Aktif`);
      terminal.log(
        `Kalan Süre: ${Math.floor(remainingTime / 86400)} gün ${Math.floor(
          (remainingTime % 86400) / 3600
        )} saat`
      );
    }
  } catch (error: any) {
    console.error("\n❌ Abonelik oluşturulurken bir hata oluştu:");
    if (error.message) {
      console.error("Hata mesajı:", error.message);
    } else {
      console.error(error);
    }
    throw error;
  }
}

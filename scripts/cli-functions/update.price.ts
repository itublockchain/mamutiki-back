import { initSDK } from "./init-sdk";
import { DEFAULT_VALUES } from "../utils/constants";

export default async function updatePrice() {
  try {
    console.log("\nAbonelik fiyatı güncelleme işlemi başlatılıyor...");

    const sdk = await initSDK();
    console.log("SDK başarıyla başlatıldı.");

    const newPrice = DEFAULT_VALUES.subscription.price;
    const priceInOcta = newPrice * 100_000_000;

    console.log(`\nFiyat güncelleniyor: ${newPrice} APT (${priceInOcta} Octa)`);
    const txn = await sdk.subscription.updatePrice(priceInOcta);

    console.log("\n✅ Abonelik fiyatı başarıyla güncellendi!");
    console.log("Transaction Hash:", txn);
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

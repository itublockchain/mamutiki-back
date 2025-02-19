import { initSDK } from "./init-sdk";

export default async function subscribe() {
  try {
    console.log("\nAbonelik işlemi başlatılıyor...");
    
    const sdk = await initSDK();
    console.log("SDK başarıyla başlatıldı.");
    
    console.log("Abonelik işlemi gerçekleştiriliyor...");
    const txn = await sdk.subscription.subscribe();
    
    console.log("\n✅ Abonelik başarıyla oluşturuldu!");
    console.log("Transaction Hash:", txn);
    
    // Abonelik durumunu kontrol et
    const [isActive, remainingTime] = await sdk.subscription.checkSubscription(sdk.account.getAccount().address().toString());
    if (isActive) {
      console.log(`\nAbonelik Durumu: Aktif`);
      console.log(`Kalan Süre: ${Math.floor(remainingTime / 86400)} gün ${Math.floor((remainingTime % 86400) / 3600)} saat`);
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

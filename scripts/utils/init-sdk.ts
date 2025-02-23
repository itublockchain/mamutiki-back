import AptosMoveSDK from "./AptosMoveSDK";
import terminal from "./console";

export async function initSDK() {
  try {
    const sdk = new AptosMoveSDK();

    // Özel anahtarı env'den al ve hesabı oluştur
    const privateKey = process.env.TRUSTED_PRIVATE_KEY;
    if (!privateKey) {
      throw new Error("TRUSTED_PRIVATE_KEY env değişkeni bulunamadı!");
    }

    const account = sdk.setAccount(privateKey);

    return { ...sdk, _account: account };
  } catch (error) {
    console.error("SDK başlatılırken bir hata oluştu:", error);
    throw error;
  }
}

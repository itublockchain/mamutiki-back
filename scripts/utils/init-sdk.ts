import AptosMoveSDK from "./AptosMoveSDK";
import terminal from "./console";

export async function initSDK(props?: { moduleAccount?: boolean }) {
  try {
    const sdk = new AptosMoveSDK();

    // Özel anahtarı env'den al ve hesabı oluştur
    const ACCOUNT_PRIVATE_KEY = props?.moduleAccount
      ? process.env.MODULE_PRIVATE_KEY
      : process.env.ACCOUNT_PRIVATE_KEY;
    if (!ACCOUNT_PRIVATE_KEY) {
      throw new Error("ACCOUNT_PRIVATE_KEY env değişkeni bulunamadı!");
    }

    const account = sdk.setAccount(ACCOUNT_PRIVATE_KEY);

    return { ...sdk, _account: account };
  } catch (error) {
    terminal.error("SDK başlatılırken bir hata oluştu:", error);
    throw error;
  }
}

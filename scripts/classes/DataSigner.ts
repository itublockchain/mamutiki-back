import { AptosAccount } from "aptos";
import { sha256 } from "@noble/hashes/sha256";
import dotenv from "dotenv";

dotenv.config();

export default class DataSigner {
  private trustedAccount: AptosAccount;

  constructor(privateKey: string = process.env.TRUSTED_PRIVATE_KEY!) {
    this.trustedAccount = new AptosAccount(Buffer.from(privateKey, "hex"));
  }

  getTrustedPublicKey(): string {
    return Buffer.from(this.trustedAccount.pubKey().toUint8Array()).toString(
      "hex"
    );
  }

  signContributionData(
    campaignId: number,
    dataCount: number,
    storeCid: string,
    score: number
  ): string {
    // Manuel serileştirme
    const storeKeyBuffer = Buffer.from(storeCid);
    const message = Buffer.alloc(8 + 8 + 8 + storeKeyBuffer.length + 8);

    // campaign_id (u64)
    message.writeBigUInt64LE(BigInt(campaignId), 0);

    // data_count (u64)
    message.writeBigUInt64LE(BigInt(dataCount), 8);

    // store_key_len (u64)
    message.writeBigUInt64LE(BigInt(storeKeyBuffer.length), 16);

    // store_key (bytes)
    storeKeyBuffer.copy(message, 24);

    // score (u64)
    message.writeBigUInt64LE(BigInt(score), 24 + storeKeyBuffer.length);

    // Mesajı hash'le (SHA2-256) ve imzala
    const messageHash = sha256(message);
    const signature = this.trustedAccount
      .signBuffer(messageHash)
      .toUint8Array();

    return Buffer.from(signature).toString("hex");
  }
}

// Test amaçlı direkt çalıştırma
if (require.main === module) {
  const signer = new DataSigner();
  const signature = signer.signContributionData(1, 1, "test_store_key", 100);
  console.log("Test imzası:", signature);
  console.log("Trusted Public Key:", signer.getTrustedPublicKey());
}

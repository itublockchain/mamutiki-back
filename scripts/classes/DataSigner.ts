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
    sender: string,
    campaignId: number,
    dataCount: number,
    storeCid: string,
    score: number,
    keyForDecryption: string
  ): string {
    // Manuel serileştirme
    const senderBuffer = Buffer.from(sender.replace("0x", ""), "hex");
    const storeKeyBuffer = Buffer.from(storeCid);
    const keyForDecryptionBuffer = Buffer.from(keyForDecryption);
    const message = Buffer.alloc(32 + 8 + 8 + 8 + storeKeyBuffer.length + 8 + 8 + keyForDecryptionBuffer.length);

    // sender (32 bytes)
    senderBuffer.copy(message, 0);

    // campaign_id (u64)
    message.writeBigUInt64LE(BigInt(campaignId), 32);

    // data_count (u64)
    message.writeBigUInt64LE(BigInt(dataCount), 40);

    // store_key_len (u64)
    message.writeBigUInt64LE(BigInt(storeKeyBuffer.length), 48);

    // store_key (bytes)
    storeKeyBuffer.copy(message, 56);

    // score (u64)
    message.writeBigUInt64LE(BigInt(score), 56 + storeKeyBuffer.length);

    // key_for_decryption_len (u64)
    message.writeBigUInt64LE(BigInt(keyForDecryptionBuffer.length), 64 + storeKeyBuffer.length);

    // key_for_decryption (bytes)
    keyForDecryptionBuffer.copy(message, 72 + storeKeyBuffer.length);
    

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
  const signature = signer.signContributionData("0x3f4e6659c3aa3cb8bb49a9b0299a5ddf9a19cb036820ec51ac6ea7480dbf547e", 1, 1, "test", 1, "test");
  console.log("Test imzası:", signature);
  console.log("Trusted Public Key:", signer.getTrustedPublicKey());
}

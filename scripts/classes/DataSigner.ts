import {
  Account,
  Ed25519Account,
  Ed25519PrivateKey,
  SingleKeyAccount,
} from "@aptos-labs/ts-sdk";

import { sha256 } from "@noble/hashes/sha256";
import { createHash } from "crypto";
import dotenv from "dotenv";

dotenv.config();

export default class DataSigner {
  private trustedAccount: SingleKeyAccount;

  constructor(privateKey: string = process.env.TRUSTED_PRIVATE_KEY!) {
    const formattedPrivateKey = new Ed25519PrivateKey(
      Buffer.from(privateKey, "hex")
    );

    this.trustedAccount = Account.fromPrivateKey({
      privateKey: formattedPrivateKey,
      legacy: false,
    });
  }

  getTrustedPublicKey(): string {
    console.log(this.trustedAccount.publicKey);
    return "";
  }

  signContributionData(
    campaignId: number,
    dataCount: number,
    storeCid: string,
    score: number
  ): string {
    // Manuel serileştirme
    const storeKeyBuffer = Buffer.from(storeCid, "utf-8");
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
    const messageHash = createHash("sha256").update(message).digest();

    const signature = this.trustedAccount.sign(messageHash).bcsToBytes();
    const signatureHex = Buffer.from(signature).toString("hex");

    return signatureHex.slice(4);
  }
}

// Test amaçlı direkt çalıştırma
if (require.main === module) {
  const signer = new DataSigner();
  const signature = signer.signContributionData(1, 1, "test_store_key", 100);
  console.log("Test imzası:", signature);
  console.log("Trusted Public Key:", signer.getTrustedPublicKey());
}

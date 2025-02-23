import {
  Account,
  Ed25519PrivateKey,
  SingleKeyAccount,
} from "@aptos-labs/ts-sdk";

import terminal from "../utils/console";

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
    terminal.log(this.trustedAccount.publicKey);
    return "";
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
    const message = Buffer.alloc(
      32 +
        8 +
        8 +
        8 +
        storeKeyBuffer.length +
        8 +
        8 +
        keyForDecryptionBuffer.length
    );

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
    message.writeBigUInt64LE(
      BigInt(keyForDecryptionBuffer.length),
      64 + storeKeyBuffer.length
    );

    // key_for_decryption (bytes)
    keyForDecryptionBuffer.copy(message, 72 + storeKeyBuffer.length);

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
  const signature = signer.signContributionData(
    "0x0c869abd70b0f3e68705acfa8f88be344b2c93e8dc93d47ae99e6fcc2055cfb7",
    1,
    1,
    "test_store_key",
    100,
    "test_key_for_decryption"
  );
  terminal.log("Test imzası:", signature);
  terminal.log("Trusted Public Key:", signer.getTrustedPublicKey());
}

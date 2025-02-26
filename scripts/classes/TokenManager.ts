import BaseManager from "./BaseManager";
import CONFIG from "../utils/config";
import { ONE_TOKEN } from "../utils/constants";

// Token Manager
class TokenManager extends BaseManager {
  constructor(moduleAddress: string = CONFIG.TOKEN_MODULE_ADDRESS) {
    super(moduleAddress);
  }

  async mint(amount: number): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::DATA::mint`,
      type_arguments: [],
      arguments: [amount * ONE_TOKEN],
    });

    return txn;
  }

  async transferToken(amount: number, recipient: string): Promise<string> {
    try {
      if (!this.account) throw new Error("Account not set");

      const txn = await this.executeTransaction({
        type: "entry_function_payload",
        function: `${this.moduleAddress}::DATA::transfer`,
        type_arguments: [],
        arguments: [recipient, amount * ONE_TOKEN],
      });

      return txn;
    } catch (error) {
      console.error(
        "AccountManager - Token transferlenirken bir hata oluştu:",
        error
      );
      throw error;
    }
  }

  async faucet(): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::DATA::faucet`,
      type_arguments: [],
      arguments: [],
    });

    return txn;
  }

  async lockFaucet(): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::DATA::lock_faucet`,
      type_arguments: [],
      arguments: [],
    });

    return txn;
  }

  async unlockFaucet(): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::DATA::unlock_faucet`,
      type_arguments: [],
      arguments: [],
    });

    return txn;
  }
}

export default TokenManager;

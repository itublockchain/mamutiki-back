import BaseManager from "./BaseManager";
import CONFIG from "../utils/config";
import { ONE_MAMU } from "../utils/constants";

// Token Manager
class TokenManager extends BaseManager {
  constructor(moduleAddress: string = CONFIG.TOKEN_MODULE_ADDRESS) {
    super(moduleAddress);
  }

  async mint(amount: number): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::mamu::mint`,
      type_arguments: [],
      arguments: [amount * ONE_MAMU],
    });

    return txn;
  }

  async register(): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::mamu::register`,
      type_arguments: [],
      arguments: [],
    });

    return txn;
  }

  async transferToken(amount: number, recipient: string): Promise<string> {
    try {
      if (!this.account) throw new Error("Account not set");

      const txn = await this.executeTransaction({
        type: "entry_function_payload",
        function: `${this.moduleAddress}::mamu::transfer`,
        type_arguments: [],
        arguments: [recipient, amount * ONE_MAMU],
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

  async isRegistered(address: string): Promise<boolean> {
    const resources = await this.aptos.getAccountResources({
      accountAddress: address,
    });

    const mamuStore = resources.find(
      (r: any) => r.type === "0x1::coin::CoinStore<0x1::mamu::MAMU>"
    );

    return mamuStore !== undefined;
  }

  async faucet(): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::mamu::faucet`,
      type_arguments: [],
      arguments: [],
    });

    return txn;
  }

  async lockFaucet(): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::mamu::lock_faucet`,
      type_arguments: [],
      arguments: [],
    });

    return txn;
  }

  async unlockFaucet(): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    const txn = await this.executeTransaction({
      type: "entry_function_payload",
      function: `${this.moduleAddress}::mamu::unlock_faucet`,
      type_arguments: [],
      arguments: [],
    });

    return txn;
  }
}

export default TokenManager;

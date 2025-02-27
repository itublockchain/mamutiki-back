import BaseManager from "./BaseManager";
import { Account, Ed25519PrivateKey, Ed25519Account } from "@aptos-labs/ts-sdk";
import CONFIG from "../utils/config";
import { AccountBalance } from "../types";
import AptosUtils from "../utils/AptosUtils";

// Account Manager
class AccountManager extends BaseManager {
  constructor(moduleAddress: string = CONFIG.MODULE_ADDRESS) {
    super(moduleAddress);
  }

  createAccount(privateKeyHex?: string): Ed25519Account {
    const privateKey = new Ed25519PrivateKey(privateKeyHex || "");

    if (privateKeyHex) {
      this.account = Account.fromPrivateKey({ privateKey: privateKey });
    } else this.account = Account.generate();

    return this.account;
  }

  async getBalance(): Promise<AccountBalance> {
    if (!this.account) throw new Error("Account not set");

    const resources = await this.aptos.getAccountResources({
      accountAddress: this.account.accountAddress,
    });
    const aptosCoin = resources.find(
      (r: any) => r.type === "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
    );

    if (!aptosCoin?.data || !("coin" in aptosCoin.data)) {
      throw new Error("Could not retrieve balance");
    }

    const amount = Number((aptosCoin.data as any).coin.value);
    return {
      amount,
      decimals: 8,
      formatted: AptosUtils.formatBalance(amount),
    };
  }

  async fundAccount(amount: number = 100_000_000): Promise<void> {
    if (!this.account) throw new Error("Account not set");
    //await this.faucetClient.fundAccount(this.account.address(), amount);
    await this.getBalance();
  }
}

export default AccountManager;

import BaseManager from "./BaseManager";
import { FaucetClient, AptosAccount, HexString } from "aptos";
import CONFIG from "../utils/config";
import { AccountBalance } from "../types";
import AptosUtils from "../utils/AptosUtils";

// Account Manager
class AccountManager extends BaseManager {
  private faucetClient: FaucetClient;

  constructor(
    nodeUrl: string = CONFIG.NODE_URL,
    faucetUrl: string = CONFIG.FAUCET_URL,
    moduleAddress: string = CONFIG.MODULE_ADDRESS
  ) {
    super(nodeUrl, moduleAddress);
    this.faucetClient = new FaucetClient(nodeUrl, faucetUrl);
  }

  createAccount(privateKeyHex?: string): AptosAccount {
    this.account = privateKeyHex
      ? new AptosAccount(HexString.ensure(privateKeyHex).toUint8Array())
      : new AptosAccount();
    return this.account;
  }

  async getBalance(): Promise<AccountBalance> {
    if (!this.account) throw new Error("Account not set");

    const resources = await this.client.getAccountResources(
      this.account.address()
    );
    const aptosCoin = resources.find(
      (r) => r.type === "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
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
    await this.faucetClient.fundAccount(this.account.address(), amount);
    await this.getBalance();
  }
}

export default AccountManager;

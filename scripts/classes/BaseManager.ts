import {
  Aptos,
  Ed25519Account,
  AptosConfig,
  EntryFunctionPayloadResponse,
  InputViewFunctionData,
  Network,
} from "@aptos-labs/ts-sdk";
import CONFIG from "../utils/config";

// Base Manager Class
class BaseManager {
  config: AptosConfig = new AptosConfig({
    network: Network.CUSTOM,
    fullnode: CONFIG.NODE_URL,
    faucet: CONFIG.FAUCET_URL,
  });

  aptos: Aptos = new Aptos(this.config);
  protected account?: Ed25519Account;
  protected moduleAddress: string;

  constructor(moduleAddress: string = CONFIG.MODULE_ADDRESS) {
    this.moduleAddress = moduleAddress;
  }

  setAccount(account: Ed25519Account) {
    this.account = account;
  }

  protected async executeTransaction(
    payload: EntryFunctionPayloadResponse
  ): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    try {
      const transaction = await this.aptos.transaction.build.simple({
        sender: this.account.accountAddress,
        data: {
          function: payload.function,
          functionArguments: payload.arguments,
        },
      });

      const pendingTransaction = await this.aptos.signAndSubmitTransaction({
        signer: this.account,
        transaction,
      });

      const tx = await this.aptos.waitForTransaction({
        transactionHash: pendingTransaction.hash,
      });

      return tx.hash;
    } catch (error) {
      console.error("Transaction error:", error);
      throw error;
    }
  }

  protected async viewFunction(func: string, args: any[] = []): Promise<any> {
    try {
      const payload = {
        function: `${this.moduleAddress}::${func}`,
        functionArguments: args,
      };

      return await this.aptos.view({
        payload: payload as InputViewFunctionData,
      });
    } catch (error) {
      console.error(`View function error (${func}):`, error);
      throw error;
    }
  }
}

export default BaseManager;

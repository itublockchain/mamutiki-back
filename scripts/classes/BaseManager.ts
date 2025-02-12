import { AptosClient, AptosAccount, Types } from "aptos";
import CONFIG from "../utils/config";

// Base Manager Class
class BaseManager {
  protected client: AptosClient;
  protected account?: AptosAccount;
  protected moduleAddress: string;

  constructor(
    nodeUrl: string = CONFIG.NODE_URL,
    moduleAddress: string = CONFIG.MODULE_ADDRESS
  ) {
    this.client = new AptosClient(nodeUrl);
    this.moduleAddress = moduleAddress;
  }

  setAccount(account: AptosAccount) {
    this.account = account;
  }

  protected async executeTransaction(
    payload: Types.EntryFunctionPayload
  ): Promise<string> {
    if (!this.account) throw new Error("Account not set");

    try {
      const txn = await this.client.generateTransaction(
        this.account.address(),
        payload
      );
      const signedTxn = await this.client.signTransaction(this.account, txn);
      const result = await this.client.submitTransaction(signedTxn);
      await this.client.waitForTransaction(result.hash);
      return result.hash;
    } catch (error) {
      console.error("Transaction error:", error);
      throw error;
    }
  }

  protected async viewFunction(func: string, args: any[] = []): Promise<any> {
    try {
      const payload: Types.ViewRequest = {
        function: `${this.moduleAddress}::${func}`,
        type_arguments: [],
        arguments: args,
      };
      return await this.client.view(payload);
    } catch (error) {
      console.error(`View function error (${func}):`, error);
      throw error;
    }
  }
}

export default BaseManager;

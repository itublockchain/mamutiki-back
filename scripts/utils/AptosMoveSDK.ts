import { AptosAccount } from "aptos";

import CONFIG from "./config";

import AccountManager from "../classes/AccountManager";
import CampaignManager from "../classes/CampaignManager";
import ContributionManager from "../classes/ContributionManager";

// Main SDK Class
class AptosMoveSDK {
  readonly account: AccountManager;
  readonly campaign: CampaignManager;
  readonly contribution: ContributionManager;

  constructor(
    nodeUrl: string = CONFIG.NODE_URL,
    faucetUrl: string = CONFIG.FAUCET_URL,
    moduleAddress: string = CONFIG.MODULE_ADDRESS
  ) {
    this.account = new AccountManager(nodeUrl, faucetUrl, moduleAddress);
    this.campaign = new CampaignManager(nodeUrl, moduleAddress);
    this.contribution = new ContributionManager(nodeUrl, moduleAddress);
  }

  setAccount(privateKeyHex?: string): AptosAccount {
    const account = this.account.createAccount(privateKeyHex);
    this.campaign.setAccount(account);
    this.contribution.setAccount(account);
    return account;
  }
}

export default AptosMoveSDK;

import { Account, Ed25519PrivateKey, Ed25519Account } from "@aptos-labs/ts-sdk";

import CONFIG from "./config";

import AccountManager from "../classes/AccountManager";
import CampaignManager from "../classes/CampaignManager";
import ContributionManager from "../classes/ContributionManager";

// Main SDK Class
class AptosMoveSDK {
  readonly account: AccountManager;
  readonly campaign: CampaignManager;
  readonly contribution: ContributionManager;

  constructor(moduleAddress: string = CONFIG.MODULE_ADDRESS) {
    this.account = new AccountManager(moduleAddress);
    this.campaign = new CampaignManager(moduleAddress);
    this.contribution = new ContributionManager(moduleAddress);
  }

  setAccount(privateKeyHex?: string): Ed25519Account {
    const account = Account.fromPrivateKey({
      privateKey: new Ed25519PrivateKey(privateKeyHex || ""),
    });

    this.campaign.setAccount(account);
    this.contribution.setAccount(account);
    return account;
  }
}

export default AptosMoveSDK;

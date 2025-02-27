import { Account, Ed25519PrivateKey, Ed25519Account } from "@aptos-labs/ts-sdk";

import CONFIG from "./config";

import AccountManager from "../classes/AccountManager";
import CampaignManager from "../classes/CampaignManager";
import ContributionManager from "../classes/ContributionManager";
import SubscriptionManager from "../classes/SubscriptionManager";
import TokenManager from "../classes/TokenManager";
import EscrowManager from "../classes/EscrowManager";

// Main SDK Class
class AptosMoveSDK {
  readonly account: AccountManager;
  readonly campaign: CampaignManager;
  readonly contribution: ContributionManager;
  readonly subscription: SubscriptionManager;
  readonly escrow: EscrowManager;
  constructor(moduleAddress: string = CONFIG.MODULE_ADDRESS) {
    this.account = new AccountManager(moduleAddress);
    this.campaign = new CampaignManager(moduleAddress);
    this.contribution = new ContributionManager(moduleAddress);
    this.subscription = new SubscriptionManager(moduleAddress);
    this.escrow = new EscrowManager(moduleAddress);
  }

  setAccount(privateKeyHex?: string): Ed25519Account {
    const account = Account.fromPrivateKey({
      privateKey: new Ed25519PrivateKey(privateKeyHex || ""),
    });

    this.account.setAccount(account);
    this.campaign.setAccount(account);
    this.contribution.setAccount(account);
    this.subscription.setAccount(account);
    this.escrow.setAccount(account);
    return account;
  }
}

class TokenSDK {
  readonly token: TokenManager;

  constructor(moduleAddress: string = CONFIG.TOKEN_MODULE_ADDRESS) {
    this.token = new TokenManager(moduleAddress);
  }

  setAccount(privateKeyHex?: string): Ed25519Account {
    const account = Account.fromPrivateKey({
      privateKey: new Ed25519PrivateKey(privateKeyHex || ""),
    });

    this.token.setAccount(account);
    return account;
  }
}

export { TokenSDK };
export default AptosMoveSDK;

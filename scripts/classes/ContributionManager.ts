import BaseManager from "./BaseManager";
import AptosUtils from "../utils/AptosUtils";
import { Contribution } from "../types";

// Contribution Manager
class ContributionManager extends BaseManager {
  async addTrustedKey(publicKey: string): Promise<string> {
    const payload = AptosUtils.createEntryPayload(
      `${this.moduleAddress}::verifier::add_trusted_key`,
      [AptosUtils.hexToBytes(publicKey)]
    );

    return this.executeTransaction(payload);
  }

  async removeTrustedKey(publicKey: string): Promise<string> {
    const payload = AptosUtils.createEntryPayload(
      `${this.moduleAddress}::verifier::remove_trusted_key`,
      [AptosUtils.hexToBytes(publicKey)]
    );

    return this.executeTransaction(payload);
  }

  async addContribution(
    campaignId: number,
    dataCount: number,
    storeCid: string,
    score: number,
    key_for_decryption: string,
    signature: string
  ): Promise<string> {
    const payload = AptosUtils.createEntryPayload(
      `${this.moduleAddress}::contribution_manager::add_contribution`,
      [
        campaignId.toString(),
        dataCount.toString(),
        storeCid,
        score.toString(),
        key_for_decryption,
        AptosUtils.hexToBytes(signature),
      ]
    );

    return this.executeTransaction(payload);
  }

  async getCampaignContributions(campaignId: number): Promise<Contribution[]> {
    try {
      const response = await this.viewFunction(
        "contribution_manager::get_campaign_contributions",
        [campaignId.toString()]
      );
      return (response[0] as any[]).map((contrib) =>
        this.parseContributionResponse(contrib)
      );
    } catch {
      return [];
    }
  }

  async getContributorContributions(
    contributor: string
  ): Promise<Contribution[]> {
    try {
      const response = await this.viewFunction(
        "contribution_manager::get_contributor_contributions",
        [contributor]
      );
      return (response[0] as any[]).map((contrib) =>
        this.parseContributionResponse(contrib)
      );
    } catch {
      return [];
    }
  }

  private parseContributionResponse(response: any): Contribution {
    return {
      campaign_id: Number(response.campaign_id),
      contributor: response.contributor,
      data_count: Number(response.data_count),
      store_cid: AptosUtils.bytesToString(response.store_cid),
      score: Number(response.score),
      key_for_decryption: AptosUtils.bytesToString(response.key_for_decryption),
      signature: Buffer.from(response.signature).toString("hex"),
    };
  }
}

export default ContributionManager;

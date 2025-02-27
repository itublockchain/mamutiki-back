import BaseManager from "./BaseManager";
import AptosUtils from "../utils/AptosUtils";
import { Campaign } from "../types";
import terminal from "../utils/console";
// Campaign Manager
class CampaignManager extends BaseManager {
  async createCampaign(
    title: string,
    description: string,
    prompt: string,
    unitPrice: number,
    minimumContribution: number,
    minimumScore: number,
    rewardPool: number,
    publicKeyForEncryption: string
  ): Promise<string> {
    const payload = AptosUtils.createEntryPayload(
      `${this.moduleAddress}::campaign_manager::create_campaign`,
      [
        title,
        description,
        prompt,
        unitPrice.toString(),
        minimumContribution.toString(),
        minimumScore.toString(),
        rewardPool.toString(),
        AptosUtils.hexToBytes(publicKeyForEncryption),
      ]
    );

    return this.executeTransaction(payload);
  }

  async getCampaign(campaignId: number): Promise<Campaign | null> {
    try {
      const response = await this.viewFunction(
        "campaign_manager::get_campaign",
        [campaignId.toString()]
      );
      return this.parseCampaignResponse(response[0]);
    } catch {
      return null;
    }
  }

  async getAllCampaigns(): Promise<Campaign[]> {
    try {
      const response = await this.viewFunction(
        "campaign_manager::get_all_campaigns"
      );
      return (response[0] as any[]).map((camp) =>
        this.parseCampaignResponse(camp)
      );
    } catch {
      return [];
    }
  }

  async getAllActiveCampaigns(): Promise<Campaign[]> {
    try {
      const response = await this.viewFunction(
        "campaign_manager::get_all_active_campaigns"
      );
      return (response[0] as any[]).map((camp) =>
        this.parseCampaignResponse(camp)
      );
    } catch {
      return [];
    }
  }

  async lastCreatedCampaign(address: string): Promise<Campaign> {
    try {
      const response = await this.viewFunction(
        "campaign_manager::last_created_campaign",
        [address]
      );
      return this.parseCampaignResponse(response[0]);
    } catch (error) {
      terminal.error(error);
      throw error;
    }
  }

  async closeCampaignById(campaignId: number): Promise<[Campaign, string]> {
    try {
      const payload = AptosUtils.createEntryPayload(
        `${this.moduleAddress}::campaign_manager::close_campaign_by_id`,
        [campaignId.toString()]
      );

      const tx = await this.executeTransaction(payload);
      return [(await this.getCampaign(campaignId)) as Campaign, tx];
    } catch (error) {
      terminal.error(error);
      throw error;
    }
  }

  private parseCampaignResponse(response: any): Campaign {
    return {
      id: Number(response.id),
      creator: response.creator,
      title: response.title,
      description: response.description,
      prompt: response.prompt,
      reward_pool: Number(response.reward_pool),
      remaining_reward: Number(response.remaining_reward),
      unit_price: Number(response.unit_price),
      minimum_contribution: Number(response.minimum_contribution),
      active: response.active,
      public_key_for_encryption: response.public_key_for_encryption,
    };
  }
}

export default CampaignManager;

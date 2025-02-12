import BaseManager from "./BaseManager";
import AptosUtils from "../utils/AptosUtils";
import { Campaign } from "../types";

// Campaign Manager
class CampaignManager extends BaseManager {
  async createCampaign(
    title: string,
    description: string,
    prompt: string,
    unitPrice: number,
    minimumContribution: number,
    rewardPool: number
  ): Promise<string> {
    const payload = AptosUtils.createEntryPayload(
      `${this.moduleAddress}::campaign_manager::create_campaign`,
      [
        title,
        description,
        prompt,
        unitPrice.toString(),
        minimumContribution.toString(),
        rewardPool.toString(),
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
    };
  }
}

export default CampaignManager;

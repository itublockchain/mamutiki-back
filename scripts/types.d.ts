interface Campaign {
  id: number;
  creator: string;
  title: string;
  description: string;
  prompt: string;
  reward_pool: number;
  remaining_reward: number;
  unit_price: number;
  minimum_contribution: number;
  active: boolean;
  public_key_for_encryption: string;
}

interface Contribution {
  campaign_id: number;
  contributor: string;
  data_count: number;
  store_cid: string;
  score: number;
  key_for_decryption: string;
  signature: string;
}

interface AccountBalance {
  amount: number;
  decimals: number;
  formatted: string;
}

export { Campaign, Contribution, AccountBalance };

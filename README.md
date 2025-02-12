# Mamutiki - Data Marketplace Move Modules

This documentation details the public entry and view functions in Move smart contracts for a decentralized data marketplace platform.

## Table of Contents
- [Campaign Manager](#campaign-manager)
- [Contribution Manager](#contribution-manager)
- [Escrow Manager](#escrow-manager)
- [Verifier Manager](#verifier-manager)

## Campaign Manager
Module where buyers can create campaigns to purchase specific types of data.

### Public Entry Functions

#### `create_campaign`
Creates a new data collection campaign and locks the reward pool in escrow.

**Parameters:**
- `account: &signer` - Signer of the campaign creator's account
- `title: String` - Campaign title
- `description: String` - Campaign description
- `prompt: String` - Data collection prompt
- `unit_price: u64` - Reward amount per data point
- `minimum_contribution: u64` - Minimum contribution amount
- `reward_pool: u64` - Total reward pool

### View Functions

#### `get_campaign`
Returns details of a specific campaign.

**Parameters:**
- `campaign_id: u64` - Campaign ID

**Return Value:**
```move
Campaign {
    id: u64,
    creator: address,
    title: String,
    description: String,
    prompt: String,
    reward_pool: u64,
    remaining_reward: u64,
    unit_price: u64,
    minimum_contribution: u64,
    active: bool
}
```

#### `get_all_campaigns`
Lists all campaigns in the marketplace.

**Return Value:**
- `vector<Campaign>` - List of all campaigns

## Contribution Manager
Manages data contributions from sellers to active campaigns.

### Public Entry Functions

#### `add_contribution`
Submits data contribution to a campaign and transfers the reward to the contributor.

**Parameters:**
- `account: &signer` - Signer of the contributor's account
- `campaign_id: u64` - Campaign ID
- `data_count: u64` - Number of data points submitted
- `store_cid: String` - IPFS CID of the data
- `score: u64` - Quality score of the contribution
- `signature: vector<u8>` - ED25519 signature from trusted validator

### View Functions

#### `get_campaign_contributions`
Lists all contributions for a specific campaign.

**Parameters:**
- `campaign_id: u64` - Campaign ID

**Return Value:**
```move
vector<Contribution> {
    campaign_id: u64,
    contributor: address,
    data_count: u64,
    store_cid: String,
    score: u64,
    signature: vector<u8>
}
```

## Verifier Manager
Manages verification of data contributions using trusted validator signatures.

### Public Entry Functions

#### `add_trusted_key`
Adds a new trusted validator's public key to the system.

**Parameters:**
- `account: &signer` - Signer of the marketplace creator account
- `public_key: vector<u8>` - ED25519 public key of the trusted validator

## Important Notes

1. All currency amounts are in AptosCoin.
2. Data verification is performed by trusted validators using ED25519 signatures.
3. The contribution signature is generated over:
   - campaign_id
   - data_count
   - store_cid (IPFS Content ID)
   - score (quality score)
4. Data quality scores are determined by trusted validators.
5. Only the marketplace creator can manage trusted validator keys.
6. Data is stored in decentralized storage solutions (IPFS).

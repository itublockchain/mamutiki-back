module marketplace::campaign_manager {
    use std::signer;
    use std::table;
    use std::vector;
    use std::string::{Self, String, length};
    use std::event;
    use std::timestamp;
    use aptos_framework::account;
    use marketplace::subscription_manager;

    use data::DATA::{Self};

    #[test_only]
    use std::string;

    friend marketplace::contribution_manager;

    // Campaign structure.
    struct Campaign has store, drop, copy {
        id: u64,
        creator: address,
        title: String,
        description: String,
        prompt: String,
        unit_price: u64,
        minimum_contribution: u64,
        minimum_score: u64,
        reward_pool: u64,
        remaining_reward: u64,
        public_key_for_encryption: vector<u8>,
        active: bool,
        created_at: u64,
    }
    
    // Store using table to store campaigns.
    struct CampaignStore has key {
        campaigns: table::Table<u64, Campaign>,
        next_id: u64,
        create_campaign_events: event::EventHandle<CampaignCreatedEvent>,
    }

    // Event structure for campaign creation.
    struct CampaignCreatedEvent has drop, store {
        campaign_id: u64,
        creator: address,
        title: String,
        reward_pool: u64,
        unit_price: u64,
        minimum_contribution: u64,
        minimum_score: u64,
        public_key_for_encryption: vector<u8>,
        created_at: u64
    }

    const ERR_NO_SUBSCRIPTION: u64 = 1001;
    const ERR_NO_CAMPAIGN: u64 = 1002;

    const ERR_INSUFFICIENT_FUNDS: u64 = 1;
    const ERR_INVALID_TITLE: u64 = 2;
    const ERR_INVALID_DESCRIPTION: u64 = 3;
    const ERR_INVALID_PROMPT: u64 = 4;
    const ERR_INVALID_UNIT_PRICE: u64 = 5;
    const ERR_INVALID_MINIMUM_CONTRIBUTION: u64 = 6;
    const ERR_INVALID_MINIMUM_SCORE: u64 = 7;
    const ERR_INVALID_REWARD_POOL: u64 = 8;
    const ERR_INVALID_PUBLIC_KEY_FOR_ENCRYPTION: u64 = 9;
    const ERR_EXCEED_MAX_SCORE: u64 = 10;

    const MAX_SCORE: u64 = 100;
    
    const ERR_CAMPAIGN_NOT_ACTIVE: u64 = 3001;
    const ERR_NOT_CAMPAIGN_CREATOR: u64 = 3002;

    /// When the module is initialized, it runs automatically
    fun init_module(account: &signer) {
        let store = CampaignStore {
            campaigns: table::new<u64, Campaign>(),
            next_id: 1,
            create_campaign_events: account::new_event_handle<CampaignCreatedEvent>(account),
        };
        move_to(account, store);
    }

    public fun create_campaign_check_input_validity(
        title: String,
        description: String,
        prompt: String,
        unit_price: u64,
        minimum_contribution: u64,
        minimum_score: u64,
        reward_pool: u64,
        public_key_for_encryption: vector<u8>
    ) {
        assert!(length(&title) > 0, ERR_INVALID_TITLE);
        assert!(length(&description) > 0, ERR_INVALID_DESCRIPTION);
        assert!(length(&prompt) > 0, ERR_INVALID_PROMPT);
        assert!(unit_price > 0, ERR_INVALID_UNIT_PRICE);
        assert!(minimum_contribution >= 0, ERR_INVALID_MINIMUM_CONTRIBUTION);
        assert!(minimum_score >= 0, ERR_INVALID_MINIMUM_SCORE);
        assert!(minimum_score <= MAX_SCORE, ERR_EXCEED_MAX_SCORE);
        assert!(reward_pool > 0, ERR_INVALID_REWARD_POOL);
        assert!(vector::length(&public_key_for_encryption) > 0, ERR_INVALID_PUBLIC_KEY_FOR_ENCRYPTION);
    }

    // Creates a new campaign and adds it to the store.
    public entry fun create_campaign(
        account: &signer,
        title: String,
        description: String,
        prompt: String,
        unit_price: u64,
        minimum_contribution: u64,
        minimum_score: u64,
        reward_pool: u64,
        public_key_for_encryption: vector<u8>
    ) acquires CampaignStore {
        let (has_subscription, _) = subscription_manager::check_subscription(signer::address_of(account));
        
        // If there is no subscription, minimum_contribution must be 0
        if (!has_subscription) {
            assert!(minimum_contribution == 0, ERR_NO_SUBSCRIPTION);
        };

        create_campaign_check_input_validity(title, description, prompt, unit_price, minimum_contribution, minimum_score, reward_pool, public_key_for_encryption);

        // Get store from module address
        let module_addr = @marketplace;
        let store_ref = borrow_global_mut<CampaignStore>(module_addr);
        let id = store_ref.next_id;
        store_ref.next_id = id + 1;

        // First, lock the funds in the escrow
        marketplace::escrow_manager::lock_funds(account, id, reward_pool, module_addr);

        let _created_at = timestamp::now_seconds();

        let new_campaign = Campaign {
            id,
            creator: signer::address_of(account),
            title,
            description,
            prompt,
            unit_price,
            minimum_contribution,
            minimum_score,
            reward_pool,
            remaining_reward: reward_pool,
            public_key_for_encryption,
            active: true,
            created_at: _created_at,
        };
        table::add(&mut store_ref.campaigns, id, new_campaign);

        // Emit the event
        event::emit_event(&mut store_ref.create_campaign_events, CampaignCreatedEvent {
            campaign_id: id,
            creator: signer::address_of(account),
            title,
            reward_pool,
            unit_price,
            minimum_contribution,
            minimum_score,
            public_key_for_encryption,
            created_at: _created_at,
        });
    }

    public entry fun close_campaign_by_id(account: &signer, campaign_id: u64) acquires CampaignStore {
        let store = borrow_global_mut<CampaignStore>(@marketplace);

        assert!(table::contains(&store.campaigns, campaign_id), ERR_NO_CAMPAIGN);
        assert!(table::borrow(&store.campaigns, campaign_id).active, ERR_CAMPAIGN_NOT_ACTIVE);
        assert!(signer::address_of(account) == table::borrow(&store.campaigns, campaign_id).creator, ERR_NOT_CAMPAIGN_CREATOR);

        let campaign = table::borrow_mut(&mut store.campaigns, campaign_id);
        campaign.active = false;

        // Unlock the funds in the escrow
        marketplace::escrow_manager::release_funds(@marketplace, campaign_id, signer::address_of(account), @marketplace);
    }

    #[view]
    public fun last_created_campaign(creator: address): Campaign acquires CampaignStore {
        // Get all campaigns by the creator
        let store = borrow_global<CampaignStore>(@marketplace);
        let campaigns = vector::empty<Campaign>();
        
        let i = store.next_id - 1;
        while (i > 0) {
            if (table::contains(&store.campaigns, i)) {
                let camp = *table::borrow(&store.campaigns, i);
                if (camp.creator == creator) {
                    return camp;
                }
            };
            i = i - 1;
        };

        assert!(false, ERR_NO_CAMPAIGN);
            Campaign {
                id: 0,
                creator: @0x0,
                title: string::utf8(b""),
                description: string::utf8(b""),
                prompt: string::utf8(b""),
                unit_price: 0,
                minimum_contribution: 0,
                minimum_score: 0,
                reward_pool: 0,
                remaining_reward: 0,
                public_key_for_encryption: vector::empty<u8>(),
                active: false,
                created_at: 0,
            }

    }

    // Returns the campaign with the specified ID.
    #[view]
    public fun get_campaign(campaign_id: u64): Campaign acquires CampaignStore {
        let store_ref = borrow_global<CampaignStore>(@marketplace);
        let campaign = *table::borrow(&store_ref.campaigns, campaign_id);
        
        // Get the remaining amount in the escrow
        if(campaign.active){
            campaign.remaining_reward = marketplace::escrow_manager::get_locked_amount(campaign_id, @marketplace);
        } else {
            campaign.remaining_reward = 0;
        };
        campaign
    }

    public fun check_campaign_active(campaign_id: u64) acquires CampaignStore {
        let store = borrow_global<CampaignStore>(@marketplace);
        let campaign = *table::borrow(&store.campaigns, campaign_id);
        assert!(campaign.active, ERR_CAMPAIGN_NOT_ACTIVE);
    }

    // Returns all campaigns in the store.
    #[view]
    public fun get_all_campaigns(): vector<Campaign> acquires CampaignStore {
        let store = borrow_global<CampaignStore>(@marketplace);
        let campaigns = vector::empty<Campaign>();
        let i = 1;
        while (i < store.next_id) {
            if (table::contains(&store.campaigns, i)) {
                let camp = *table::borrow(&store.campaigns, i);
                // For each campaign, get the remaining amount in the escrow
                if(camp.active){
                    camp.remaining_reward = marketplace::escrow_manager::get_locked_amount(i, @marketplace);
                } else {
                    camp.remaining_reward = 0;
                };
                
                vector::push_back(&mut campaigns, camp);
            };
            i = i + 1;
        };
        campaigns
    }

    #[view]
    public fun get_all_active_campaigns(): vector<Campaign> acquires CampaignStore {
        let store = borrow_global<CampaignStore>(@marketplace);
        let active_campaigns = vector::empty<Campaign>();
        let i = 1;
        
        while (i < store.next_id) {
            if (table::contains(&store.campaigns, i)) {
                let camp = *table::borrow(&store.campaigns, i);
                if (camp.active) {
                    vector::push_back(&mut active_campaigns, camp);
                };
            };
            i = i + 1;
        };

        active_campaigns
    }

    #[view]
    public(friend) fun get_all_campaign_ids(): vector<u64> acquires CampaignStore {
        let store = borrow_global<CampaignStore>(@marketplace);
        let campaign_ids = vector::empty<u64>();
        let i = 1;
        while (i < store.next_id) {
            if (table::contains(&store.campaigns, i)) {
                vector::push_back(&mut campaign_ids, i);
            };
            i = i + 1;
        };
        campaign_ids
    }

    // Returns the unit price of a campaign
    #[view]
    public fun get_unit_price(campaign_id: u64): u64 acquires CampaignStore {
        let campaign = get_campaign(campaign_id);
        campaign.unit_price
    }

    // Returns the minimum contribution of a campaign
    #[view]
    public fun get_minimum_contribution(campaign_id: u64): u64 acquires CampaignStore {
        let campaign = get_campaign(campaign_id);
        campaign.minimum_contribution
    }

    // Returns the minimum score of a campaign
    #[view]
    public fun get_minimum_score(campaign_id: u64): u64 acquires CampaignStore {
        let campaign = get_campaign(campaign_id);
        campaign.minimum_score
    }

    // Returns the public key for encryption of a campaign
    #[view]
    public fun get_public_key_for_encryption(campaign_id: u64): vector<u8> acquires CampaignStore {
        let campaign = get_campaign(campaign_id);
        campaign.public_key_for_encryption
    }

    // Returns the creator of a campaign
    #[view]
    public fun get_campaign_creator(campaign_id: u64): address acquires CampaignStore {
        let campaign = get_campaign(campaign_id);
        campaign.creator
    }

    #[test_only]
    public fun initialize_for_test(account: &signer) {
        init_module(account);
    }

    #[test]
    fun test_create_campaign() acquires CampaignStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let campaign_manager_account = account::create_account_for_test(@marketplace);
        let escrow_manager = account::create_account_for_test(@marketplace);
        let framework_signer = account::create_account_for_test(@aptos_framework);
        
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&framework_signer);
        
        DATA::initialize_for_test(&campaign_manager_account);

        // Give test tokens to test account
        DATA::mint_to(&campaign_manager_account, signer::address_of(&test_account), 1000_000_000_000);
        
        // Initialize modules in correct order
        marketplace::subscription_manager::initialize_for_test(&campaign_manager_account);
        init_module(&campaign_manager_account);
        marketplace::escrow_manager::initialize_for_test(&escrow_manager);
        
        // Prepare test data
        let title = string::utf8(b"Test Campaign");
        let description = string::utf8(b"Test Description");
        let prompt = string::utf8(b"Test Prompt");
        let unit_price = 100;
        let minimum_contribution = 0;
        let minimum_score = 0;
        let reward_pool = 1000;
        let public_key_for_encryption = b"Test Public Key";
        
        // Create campaign
        create_campaign(&test_account, title, description, prompt, unit_price, minimum_contribution, minimum_score, reward_pool, public_key_for_encryption);
        
        // Check campaign
        let campaign = get_campaign(1);
        assert!(campaign.creator == signer::address_of(&test_account), 1);
        assert!(campaign.title == title, 2);
        assert!(campaign.description == description, 3);
        assert!(campaign.prompt == prompt, 4);
        assert!(campaign.unit_price == unit_price, 5);
        assert!(campaign.minimum_contribution == minimum_contribution, 6);
        assert!(campaign.minimum_score == minimum_score, 7);
        assert!(campaign.reward_pool == reward_pool, 8);
        assert!(campaign.public_key_for_encryption == public_key_for_encryption, 9);
        assert!(campaign.active == true, 10);
    }

    #[test]
    fun test_get_all_campaigns() acquires CampaignStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let campaign_manager = account::create_account_for_test(@marketplace);
        let escrow_manager = account::create_account_for_test(@marketplace);
        let framework_signer = account::create_account_for_test(@aptos_framework);
        
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&framework_signer);
        
        DATA::initialize_for_test(&campaign_manager);

        // Give test tokens to test account
        DATA::mint_to(&campaign_manager, signer::address_of(&test_account), 1000_000_000_000);
        
        // Initialize modules
        marketplace::subscription_manager::initialize_for_test(&campaign_manager);
        init_module(&campaign_manager);
        marketplace::escrow_manager::initialize_for_test(&escrow_manager);
        
        // Create two campaigns
        create_campaign(
            &test_account,
            string::utf8(b"Campaign 1"),
            string::utf8(b"Description 1"),
            string::utf8(b"Prompt 1"),
            100,
            0,
            70,
            1000,
            b"Test Public Key"
        );
        
        create_campaign(
            &test_account,
            string::utf8(b"Campaign 2"),
            string::utf8(b"Description 2"),
            string::utf8(b"Prompt 2"),
            200,
            0,
            70,
            2000,
            b"Test Public Key"
        );
        
        // Get all campaigns and check
        let campaigns = get_all_campaigns();
        assert!(vector::length(&campaigns) == 2, 1);
        
        let campaign1 = vector::borrow(&campaigns, 0);
        let campaign2 = vector::borrow(&campaigns, 1);
        
        assert!(campaign1.unit_price == 100, 2);
        assert!(campaign2.unit_price == 200, 3);
        assert!(campaign1.minimum_contribution == 0, 4);
        assert!(campaign2.minimum_contribution == 0, 5);
        assert!(campaign1.minimum_score == 70, 6);
        assert!(campaign2.minimum_score == 70, 7);
        assert!(campaign1.reward_pool == 1000, 8);
        assert!(campaign2.reward_pool == 2000, 9);
    }

    #[test]
    fun test_get_unit_price() acquires CampaignStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let campaign_manager = account::create_account_for_test(@marketplace);
        let escrow_manager = account::create_account_for_test(@marketplace);
        let framework_signer = account::create_account_for_test(@aptos_framework);
        
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&framework_signer);
        
        DATA::initialize_for_test(&campaign_manager);

        // Give test tokens to test account
        DATA::mint_to(&campaign_manager, signer::address_of(&test_account), 1000_000_000_000);
        
        // Initialize modules
        marketplace::subscription_manager::initialize_for_test(&campaign_manager);
        init_module(&campaign_manager);
        marketplace::escrow_manager::initialize_for_test(&escrow_manager);
        
        // Prepare test data
        let unit_price = 150;
        let minimum_contribution = 0;
        let minimum_score = 0;
        let reward_pool = 1000;
        let public_key_for_encryption = b"Test Public Key";
        
        // Create campaign
        create_campaign(
            &test_account,
            string::utf8(b"Test Campaign"),
            string::utf8(b"Test Description"),
            string::utf8(b"Test Data Spec"),
            unit_price,
            minimum_contribution,
            minimum_score,
            reward_pool,
            public_key_for_encryption
        );
        
        // Check unit price
        let price = get_unit_price(1);
        assert!(price == unit_price, 1);
    }

    #[test]
    #[expected_failure]
    fun test_nonexistent_campaign() acquires CampaignStore {
        // Create test account
        let campaign_manager = account::create_account_for_test(@marketplace);
        
        // Initialize module
        init_module(&campaign_manager);
        
        // Query nonexistent campaign - should fail
        get_campaign(999);
    }

    #[test]
    #[expected_failure(abort_code = ERR_NO_SUBSCRIPTION)]
    fun test_create_campaign_without_subscription() acquires CampaignStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let campaign_manager = account::create_account_for_test(@marketplace);
        let escrow_manager = account::create_account_for_test(@marketplace);
        let framework_signer = account::create_account_for_test(@aptos_framework);
        
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&framework_signer);
        
        DATA::initialize_for_test(&campaign_manager);

        // Give test tokens to test account
        DATA::mint_to(&campaign_manager, signer::address_of(&test_account), 1000_000_000_000);
        
        // Initialize modules
        marketplace::subscription_manager::initialize_for_test(&campaign_manager);
        init_module(&campaign_manager);
        marketplace::escrow_manager::initialize_for_test(&escrow_manager);
        
        // User without subscription tries to create a campaign with non-zero minimum_contribution
        create_campaign(
            &test_account,
            string::utf8(b"Test Campaign"),
            string::utf8(b"Test Description"),
            string::utf8(b"Test Prompt"),
            100, // unit_price
            5, // minimum_contribution > 0, so it should error
            70, // minimum_score
            1000, // reward_pool
            b"Test Public Key"
        );
    }
}

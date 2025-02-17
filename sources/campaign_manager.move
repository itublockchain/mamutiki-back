module marketplace::campaign_manager {
    use std::signer;
    use std::table;
    use std::vector;
    use std::string::{String};
    use std::event;
    use std::timestamp;
    use aptos_framework::account;

    #[test_only]
    use std::string::{Self};
    #[test_only]
    use aptos_framework::aptos_coin;
    #[test_only]
    use aptos_framework::coin;

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
        reward_pool: u64,
        remaining_reward: u64,
        public_key_for_encryption: vector<u8>,
        active: bool,
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
        public_key_for_encryption: vector<u8>,
        timestamp: u64
    }

    const ERR_UNAUTHORIZED: u64 = 1000;

    const ERR_INSUFFICIENT_FUNDS: u64 = 1;

    /// When the module is initialized, it runs automatically
    fun init_module(account: &signer) {
        let store = CampaignStore {
            campaigns: table::new<u64, Campaign>(),
            next_id: 1,
            create_campaign_events: account::new_event_handle<CampaignCreatedEvent>(account),
        };
        move_to(account, store);
    }

    // Creates a new campaign and adds it to the store.
    public entry fun create_campaign(
        account: &signer,
        title: String,
        description: String,
        prompt: String,
        unit_price: u64,
        minimum_contribution: u64,
        reward_pool: u64,
        public_key_for_encryption: vector<u8>
    ) acquires CampaignStore {
        // Get store from module address
        let module_addr = @marketplace;
        let store_ref = borrow_global_mut<CampaignStore>(module_addr);
        let id = store_ref.next_id;
        store_ref.next_id = id + 1;

        // First, lock the funds in the escrow
        marketplace::escrow_manager::lock_funds(account, id, reward_pool, module_addr);

        let new_campaign = Campaign {
            id,
            creator: signer::address_of(account),
            title,
            description,
            prompt,
            unit_price,
            minimum_contribution,
            reward_pool,
            remaining_reward: reward_pool,
            public_key_for_encryption,
            active: true,
        };
        table::add(&mut store_ref.campaigns, id, new_campaign);

        // Emit the event
        event::emit_event(&mut store_ref.create_campaign_events, CampaignCreatedEvent {
            campaign_id: id,
            creator: signer::address_of(account),
            title,
            reward_pool,
            unit_price,
            public_key_for_encryption,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Returns the campaign with the specified ID.
    #[view]
    public fun get_campaign(campaign_id: u64): Campaign acquires CampaignStore {
        let store_ref = borrow_global<CampaignStore>(@marketplace);
        let campaign = *table::borrow(&store_ref.campaigns, campaign_id);
        
        // Get the remaining amount in the escrow
        campaign.remaining_reward = marketplace::escrow_manager::get_locked_amount(campaign_id, @marketplace);
        campaign
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
                camp.remaining_reward = marketplace::escrow_manager::get_locked_amount(i, @marketplace);
                vector::push_back(&mut campaigns, camp);
            };
            i = i + 1;
        };
        campaigns
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
        let campaign_manager = account::create_account_for_test(@marketplace);
        let escrow_manager = account::create_account_for_test(@marketplace);
        let framework_signer = account::create_account_for_test(@aptos_framework);
        
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&framework_signer);
        
        // Initialize AptosCoin
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&framework_signer);

        // Create coin records for test accounts and add balance
        coin::register<aptos_coin::AptosCoin>(&test_account);
        let coins = coin::mint<aptos_coin::AptosCoin>(10000, &mint_cap);
        coin::deposit(signer::address_of(&test_account), coins);
        
        // Initialize modules
        init_module(&campaign_manager);
        marketplace::escrow_manager::initialize_for_test(&escrow_manager);
        
        // Prepare test data
        let title = string::utf8(b"Test Campaign");
        let description = string::utf8(b"Test Description");
        let prompt = string::utf8(b"Test Prompt");
        let unit_price = 100;
        let minimum_contribution = 0;
        let reward_pool = 1000;
        let public_key_for_encryption = b"Test Public Key";
        
        // Create campaign
        create_campaign(&test_account, title, description, prompt, unit_price, minimum_contribution, reward_pool, public_key_for_encryption);
        
        // Check campaign
        let campaign = get_campaign(1);
        assert!(campaign.creator == signer::address_of(&test_account), 1);
        assert!(campaign.title == title, 2);
        assert!(campaign.description == description, 3);
        assert!(campaign.prompt == prompt, 4);
        assert!(campaign.unit_price == unit_price, 5);
        assert!(campaign.minimum_contribution == minimum_contribution, 6);
        assert!(campaign.reward_pool == reward_pool, 7);
        assert!(campaign.public_key_for_encryption == public_key_for_encryption, 8);
        assert!(campaign.active == true, 9);

        // Clean up capabilities
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
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
        
        // Initialize AptosCoin
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&framework_signer);

        // Create coin records for test accounts and add balance
        coin::register<aptos_coin::AptosCoin>(&test_account);
        let coins = coin::mint<aptos_coin::AptosCoin>(20000, &mint_cap);
        coin::deposit(signer::address_of(&test_account), coins);
        
        // Initialize modules
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
        assert!(campaign1.reward_pool == 1000, 4);
        assert!(campaign2.reward_pool == 2000, 5);

        // Clean up capabilities
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
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
        
        // Initialize AptosCoin
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&framework_signer);

        // Create coin records for test accounts and add balance
        coin::register<aptos_coin::AptosCoin>(&test_account);
        let coins = coin::mint<aptos_coin::AptosCoin>(10000, &mint_cap);
        coin::deposit(signer::address_of(&test_account), coins);
        
        // Initialize modules
        init_module(&campaign_manager);
        marketplace::escrow_manager::initialize_for_test(&escrow_manager);
        
        // Prepare test data
        let unit_price = 150;
        
        // Create campaign
        create_campaign(
            &test_account,
            string::utf8(b"Test Campaign"),
            string::utf8(b"Test Description"),
            string::utf8(b"Test Data Spec"),
            unit_price,
            0,
            1000,
            b"Test Public Key"
        );
        
        // Check unit price
        let price = get_unit_price(1);
        assert!(price == unit_price, 1);

        // Clean up capabilities
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
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
}

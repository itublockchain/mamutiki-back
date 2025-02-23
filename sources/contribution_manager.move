module marketplace::contribution_manager {
    use std::signer;
    use std::vector;
    use std::table::{Self, Table};
    use std::string::{Self, String, length};
    use std::event;
    use aptos_framework::timestamp;
    use aptos_framework::account;

    use marketplace::mamu;

    use marketplace::campaign_manager;
    use marketplace::escrow_manager;
    use marketplace::verifier;

    #[test_only]
    use aptos_framework::aptos_coin;
    #[test_only]
    use aptos_framework::coin;
    #[test_only]
    use std::string::{Self};

    // Sturctre of Contribution
    struct Contribution has store, drop, copy {
        campaign_id: u64,
        contributor: address,
        data_count: u64,
        store_cid: String,
        score: u64,
        key_for_decryption: String,
        signature: vector<u8>
    }

    // Store for Contribution
    struct ContributionStore has key {
        contributions: Table<u64, vector<Contribution>>, // campaign_id -> contributions
        contribution_events: event::EventHandle<ContributionEvent>,
    }

    // Event structure for contribution.
    struct ContributionEvent has drop, store {
        campaign_id: u64,
        contributor: address,
        data_count: u64,
        score: u64,
        reward_amount: u64,
        timestamp: u64
    }

    // Error codes
    const ERR_CAMPAIGN_NOT_FOUND: u64 = 1;
    const ERR_INVALID_DATA_COUNT: u64 = 2;
    const ERR_NO_VALID_SIGNATURE: u64 = 6;
    const ERR_ALREADY_CONTRIBUTED: u64 = 7;
    const ERR_INSUFFICIENT_CONTRIBUTION: u64 = 8;
    const ERR_INSUFFICIENT_SCORE: u64 = 9;

    const ERR_INVALID_CAMPAIGN_ID: u64 = 10;
    const ERR_INVALID_STORE_CID: u64 = 11;
    const ERR_INVALID_SCORE: u64 = 12;
    const ERR_INVALID_KEY_FOR_DECRYPTION: u64 = 13;
    const ERR_INVALID_SIGNATURE: u64 = 14;

    const ERR_EXCEED_MAX_SCORE: u64 = 15;

    const MAX_SCORE: u64 = 100;

    fun init_module(account: &signer) {
        let store = ContributionStore {
            contributions: table::new(),
            contribution_events: account::new_event_handle<ContributionEvent>(account),
        };
        move_to(account, store);

        // Initialize Verifier module
        verifier::initialize(account);
    }

    // Check if a contributor has already contributed to a campaign
    fun has_contributed(campaign_id: u64, contributor: address): bool acquires ContributionStore {
        let store = borrow_global<ContributionStore>(@marketplace);
        if (!table::contains(&store.contributions, campaign_id)) {
            return false
        };
        
        let campaign_contributions = table::borrow(&store.contributions, campaign_id);
        let i = 0;
        while (i < vector::length(campaign_contributions)) {
            let contribution = vector::borrow(campaign_contributions, i);
            if (contribution.contributor == contributor) {
                return true
            };
            i = i + 1;
        };
        false
    }

    public fun add_contributibon_check_input_validity(
        campaign_id: u64,
        data_count: u64,
        store_cid: String,
        score: u64,
        key_for_decryption: String,
        signature: vector<u8>)
        {
        assert!(campaign_id > 0, ERR_INVALID_CAMPAIGN_ID);
        assert!(data_count > 0, ERR_INVALID_DATA_COUNT);
        assert!(length(&store_cid) > 0, ERR_INVALID_STORE_CID);
        assert!(score >= 0, ERR_INVALID_SCORE);
        assert!(score <= MAX_SCORE, ERR_EXCEED_MAX_SCORE);
        assert!(length(&key_for_decryption) > 0, ERR_INVALID_KEY_FOR_DECRYPTION);
        assert!(vector::length(&signature) > 0, ERR_INVALID_SIGNATURE);
    }

    // Add a new contribution
    public entry fun add_contribution(
        account: &signer,
        campaign_id: u64,
        data_count: u64,
        store_cid: String,
        score: u64,
        key_for_decryption: String,
        signature: vector<u8>,
        ) acquires ContributionStore {
        mamu::check_register(account);
        
        let contributor = signer::address_of(account);

        add_contributibon_check_input_validity(campaign_id,
        data_count,
        store_cid,
        score,
        key_for_decryption,
        signature);

        // Verify the signature
        assert!(
            verifier::verify_contribution_signature(contributor, campaign_id, data_count, store_cid, score, key_for_decryption, signature),
            ERR_NO_VALID_SIGNATURE
        );
        
        // Check if user has already contributed to this campaign
        assert!(!has_contributed(campaign_id, contributor), ERR_ALREADY_CONTRIBUTED);

        // Check if the contribution amount is greater than the minimum contribution
        let minimum_contribution = campaign_manager::get_minimum_contribution(campaign_id);
        let contributor_contributions = get_contributor_contributions(contributor);
        assert!(vector::length(&contributor_contributions) >= minimum_contribution, ERR_INSUFFICIENT_CONTRIBUTION);

        // Check if the contribution score is greater than the minimum score
        let minimum_score = campaign_manager::get_minimum_score(campaign_id);
        assert!(score >= minimum_score, ERR_INSUFFICIENT_SCORE);

        let contribution = Contribution {
            campaign_id,
            contributor: signer::address_of(account),
            data_count,
            store_cid,
            score,
            key_for_decryption,
            signature
        };

        let store = borrow_global_mut<ContributionStore>(@marketplace);
        
        if (!table::contains(&store.contributions, campaign_id)) {
            table::add(&mut store.contributions, campaign_id, vector::empty<Contribution>());
        };
        
        let contributions = table::borrow_mut(&mut store.contributions, campaign_id);
        vector::push_back(contributions, contribution);

        let unit_price = campaign_manager::get_unit_price(campaign_id);
        let total_reward = data_count * unit_price;
        
        escrow_manager::release_funds_for_contribution(
            campaign_id,
            signer::address_of(account),
            total_reward
        );

        // Emit the event
        event::emit_event(&mut store.contribution_events, ContributionEvent {
            campaign_id,
            contributor: signer::address_of(account),
            data_count,
            score,
            reward_amount: total_reward,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Get all contributions
    #[view]
    public fun get_all_contributions(): vector<Contribution> acquires ContributionStore {
        let store = borrow_global<ContributionStore>(@marketplace);
        let result = vector::empty<Contribution>();
        let campaign_ids = campaign_manager::get_all_campaign_ids();
        let i = 0;
        while (i < vector::length(&campaign_ids)) {
            let campaign_id = *vector::borrow(&campaign_ids, i);
            if (table::contains(&store.contributions, campaign_id)) {
                let campaign_contributions = table::borrow(&store.contributions, campaign_id);
                let j = 0;
                while (j < vector::length(campaign_contributions)) {
                    let contribution = vector::borrow(campaign_contributions, j);
                    vector::push_back(&mut result, *contribution);
                    j = j + 1;
                };
            };
            i = i + 1;
        };
        result
    }

    // Get all contributions for a campaign
    #[view]
    public fun get_campaign_contributions(campaign_id: u64): vector<Contribution> acquires ContributionStore {
        let store = borrow_global<ContributionStore>(@marketplace);
        if (!table::contains(&store.contributions, campaign_id)) {
            return vector::empty<Contribution>();
        };
        *table::borrow(&store.contributions, campaign_id)
    }

    // Get all contributions for a contributor
    #[view]
    public fun get_contributor_contributions(contributor: address): vector<Contribution> acquires ContributionStore {
        let store = borrow_global<ContributionStore>(@marketplace);
        let result = vector::empty<Contribution>();
        let campaign_ids = campaign_manager::get_all_campaign_ids();
        let i = 0;
        while (i < vector::length(&campaign_ids)) {
            let campaign_id = *vector::borrow(&campaign_ids, i);
            if (table::contains(&store.contributions, campaign_id)) {
                let campaign_contributions = table::borrow(&store.contributions, campaign_id);
                let j = 0;
                while (j < vector::length(campaign_contributions)) {
                    let contribution = vector::borrow(campaign_contributions, j);
                    if (contribution.contributor == contributor) {
                        vector::push_back(&mut result, *contribution);
                    };
                    j = j + 1;
                };
            };
            i = i + 1;
        };
        result
    }

    #[test]
    #[expected_failure(abort_code = 65538, location = aptos_std::ed25519)]
    fun test_add_contribution() acquires ContributionStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let campaign_manager_account = account::create_account_for_test(@marketplace);
        let contribution_manager = account::create_account_for_test(@marketplace);
        let escrow_manager = account::create_account_for_test(@marketplace);
        let framework_signer = account::create_account_for_test(@aptos_framework);
        
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&framework_signer);
        
        // Initialize AptosCoin
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&framework_signer);

        // Register coin stores and add balance
        coin::register<aptos_coin::AptosCoin>(&test_account);
        coin::register<aptos_coin::AptosCoin>(&campaign_manager_account);
        let coins = coin::mint<aptos_coin::AptosCoin>(1000_000_000_000, &mint_cap);
        coin::deposit(signer::address_of(&campaign_manager_account), coins);
        
        // Initialize modules in correct order
        marketplace::subscription_manager::initialize_for_test(&campaign_manager_account);
        campaign_manager::initialize_for_test(&campaign_manager_account);
        escrow_manager::initialize_for_test(&escrow_manager);
        init_module(&contribution_manager);

        // Create test campaign
        let campaign_id = 1;
        let unit_price = 100;
        let title = string::utf8(b"Test Campaign");
        let description = string::utf8(b"Test Description");
        let prompt = string::utf8(b"Test Prompt");
        let minimum_contribution = 0;
        let minimum_score = 0;
        let reward_pool = 1000;
        let public_key_for_encryption = b"Test Public Key";
        
        campaign_manager::create_campaign(
            &campaign_manager_account,
            title,
            description,
            prompt,
            unit_price,
            minimum_contribution,
            minimum_score,
            reward_pool,
            public_key_for_encryption
        );
        
        // Add test public key
        let test_public_key = b"test_public_key_1";
        verifier::add_trusted_key(&contribution_manager, test_public_key);
        
        // Prepare test data with invalid signature (expected to fail)
        let data_count = 1;
        let store_cid = string::utf8(b"test");
        let score = 100;
        let key_for_decryption = string::utf8(b"test_key_for_decryption");
        let signature = b"test_signature";
        
        // This should fail because signature is not a valid ED25519 signature
        add_contribution(&test_account, campaign_id, data_count, store_cid, score, key_for_decryption, signature);
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test]
    fun test_get_empty_campaign_contributions() acquires ContributionStore {
        // Test hesabini olustur
        let contribution_manager = account::create_account_for_test(@marketplace);
        
        // Modulu baslat
        init_module(&contribution_manager);
        
        // Var olmayan kampanya icin katkilari al
        let contributions = get_campaign_contributions(999);
        assert!(vector::length(&contributions) == 0, 1);
    }

    #[test]
    #[expected_failure(abort_code = 65538, location = aptos_std::ed25519)]
    fun test_multiple_contributions() acquires ContributionStore {
        // Create test accounts
        let test_account1 = account::create_account_for_test(@0x1);
        let test_account2 = account::create_account_for_test(@0x2);
        let campaign_manager_account = account::create_account_for_test(@marketplace);
        let contribution_manager = account::create_account_for_test(@marketplace);
        let escrow_manager = account::create_account_for_test(@marketplace);
        let framework_signer = account::create_account_for_test(@aptos_framework);
        
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(&framework_signer);
        
        // Initialize AptosCoin
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&framework_signer);

        // Register coin stores and add balance
        coin::register<aptos_coin::AptosCoin>(&test_account1);
        coin::register<aptos_coin::AptosCoin>(&test_account2);
        coin::register<aptos_coin::AptosCoin>(&campaign_manager_account);
        let coins = coin::mint<aptos_coin::AptosCoin>(1000_000_000_000, &mint_cap);
        coin::deposit(signer::address_of(&campaign_manager_account), coins);
        
        // Initialize modules in correct order
        marketplace::subscription_manager::initialize_for_test(&campaign_manager_account);
        campaign_manager::initialize_for_test(&campaign_manager_account);
        escrow_manager::initialize_for_test(&escrow_manager);
        init_module(&contribution_manager);

        // Create test campaign
        let campaign_id = 1;
        let unit_price = 100;
        let title = string::utf8(b"Test Campaign");
        let description = string::utf8(b"Test Description");
        let prompt = string::utf8(b"Test Prompt");
        let minimum_contribution = 0;
        let minimum_score = 0;
        let reward_pool = 1000;
        let public_key_for_encryption = b"Test Public Key";
        
        campaign_manager::create_campaign(
            &campaign_manager_account,
            title,
            description,
            prompt,
            unit_price,
            minimum_contribution,
            minimum_score,
            reward_pool,
            public_key_for_encryption
        );
        
        // Add test public key
        let test_public_key = b"test_public_key_1";
        verifier::add_trusted_key(&contribution_manager, test_public_key);
        
        // Prepare test data with invalid signature (expected to fail)
        let data_count = 1;
        let store_cid = string::utf8(b"test");
        let score = 100;
        let key_for_decryption = string::utf8(b"test_key_for_decryption");
        let signature = b"test_signature";
        
        // These should fail because signature is not a valid ED25519 signature
        add_contribution(&test_account1, campaign_id, data_count, store_cid, score, key_for_decryption, signature);
        add_contribution(&test_account2, campaign_id, data_count, store_cid, score, key_for_decryption, signature);
        
        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}
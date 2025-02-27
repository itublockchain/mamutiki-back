module marketplace::escrow_manager {
    use std::signer;
    use std::table::{Self, Table};
    use std::account;

    use data::DATA::{Self};
    use marketplace::subscription_manager;

    friend marketplace::contribution_manager;

    /// Escrow structure
    struct EscrowStore has key {
        escrows: Table<u64, u64>, // campaign_id -> amount
        signer_cap: account::SignerCapability,
    }

    struct PlatformStore has key {
        platform_fee: u64,
        platform_fee_for_subscribers: u64,
        platform_fee_divisor: u64,
    }

    const STANDARD_FEE: u64 = 20; // 2%
    const STANDARD_SUBSCRIBER_FEE: u64 = 5; // 0.5%
    const STANDARD_FEE_DIVISOR: u64 = 1000;

    /// Error codes
    const ERR_NOT_ENOUGH_BALANCE: u64 = 1;
    const ERR_ESCROW_NOT_FOUND: u64 = 2;
    const ERR_UNAUTHORIZED: u64 = 3;

    const MIN_FEE_EXCEED: u64 = 1000;
    const MAX_FEE_EXCEED: u64 = 1001;

    const MIN_DIVISOR_EXCEED: u64 = 2000;

    /// Automatically runs when the module is initialized
    fun init_module(account: &signer) {
        let (resource_signer, signer_cap) = account::create_resource_account(account, b"escrow_manager");

        let store = EscrowStore {
            escrows: table::new(),
            signer_cap,
        };

        let platform_store = PlatformStore {
            platform_fee: STANDARD_FEE,
            platform_fee_for_subscribers: STANDARD_SUBSCRIBER_FEE,
            platform_fee_divisor: STANDARD_FEE_DIVISOR,
        };

        move_to(account, platform_store);
        move_to(account, store);
    }

    public entry fun set_platform_fee(admin: &signer, new_fee: u64) acquires PlatformStore {
        assert!(signer::address_of(admin) == @marketplace, ERR_UNAUTHORIZED);
        assert!(new_fee >= 0, MIN_FEE_EXCEED);

        let store = borrow_global_mut<PlatformStore>(@marketplace);
        assert!(new_fee <= store.platform_fee_divisor, MAX_FEE_EXCEED);

        store.platform_fee = new_fee;
    }

    public entry fun set_subscriber_platform_fee(admin: &signer, new_fee: u64) acquires PlatformStore {
        assert!(signer::address_of(admin) == @marketplace, ERR_UNAUTHORIZED);
        assert!(new_fee >= 0, MIN_FEE_EXCEED);
        
        let store = borrow_global_mut<PlatformStore>(@marketplace);
        assert!(new_fee <= store.platform_fee_divisor, MAX_FEE_EXCEED);

        store.platform_fee_for_subscribers = new_fee;
    } 

    public entry fun set_platform_fee_divisor(admin: &signer, new_divisor: u64) acquires PlatformStore {
        assert!(signer::address_of(admin) == @marketplace, ERR_UNAUTHORIZED);
        assert!(new_divisor >= 0, MIN_DIVISOR_EXCEED);

        let store = borrow_global_mut<PlatformStore>(@marketplace);
        store.platform_fee_divisor = new_divisor;
    } 

    #[view]
    public fun get_platform_fee(): u64 acquires PlatformStore {
        let platform_store = borrow_global<PlatformStore>(@marketplace);
        platform_store.platform_fee
    }

    #[view]
    public fun get_platform_fee_for_subscribers(): u64 acquires PlatformStore {
        let platform_store = borrow_global<PlatformStore>(@marketplace);
        platform_store.platform_fee_for_subscribers
    }

    #[view]
    public fun get_platform_fee_divisor(): u64 acquires PlatformStore {
        let platform_store = borrow_global<PlatformStore>(@marketplace);
        platform_store.platform_fee_divisor
    }   
    
    /// Locks funds for a specific campaign
    public fun lock_funds(
        account: &signer,
        campaign_id: u64,
        amount: u64,
        store_addr: address
    ) acquires EscrowStore {
        // Check if the user has enough balance
        assert!(DATA::get_balance(signer::address_of(account)) >= amount, ERR_NOT_ENOUGH_BALANCE);

        let store = borrow_global_mut<EscrowStore>(store_addr);
        let resource_signer = account::create_signer_with_capability(&store.signer_cap);
        let resource_addr = signer::address_of(&resource_signer);

        // Transfer the funds to marketplace account
        DATA::transfer(account, resource_addr, amount);

        // Create the escrow record
        table::add(&mut store.escrows, campaign_id, amount);
    }

    /// Releases locked funds
    public fun release_funds(
        account: &signer,
        campaign_id: u64,
        recipient: address,
        store_addr: address
    ) acquires EscrowStore {
        let store = borrow_global_mut<EscrowStore>(store_addr);
        
        // Check if there are locked funds for the campaign
        assert!(table::contains(&store.escrows, campaign_id), ERR_ESCROW_NOT_FOUND);
        
        // Only the store owner can release the funds
        assert!(signer::address_of(account) == store_addr, ERR_UNAUTHORIZED);

        let amount = table::remove(&mut store.escrows, campaign_id);
        let resource_signer = account::create_signer_with_capability(&store.signer_cap);
        DATA::transfer(&resource_signer, recipient, amount);
    }

    /// Releases funds for data contribution
    public(friend) fun release_funds_for_contribution(
        campaign_id: u64,
        recipient: address,
        amount: u64
    ) acquires EscrowStore, PlatformStore {
        let store = borrow_global_mut<EscrowStore>(@marketplace);
        let platform_store = borrow_global_mut<PlatformStore>(@marketplace);

        assert!(table::contains(&store.escrows, campaign_id), ERR_ESCROW_NOT_FOUND);

        let locked_amount = *table::borrow(&store.escrows, campaign_id);

        let (subscription_status, subscription_end) = subscription_manager::check_subscription(recipient);

        let fee_factor: u64;

        if (subscription_status && (subscription_end > 0)){
            fee_factor = platform_store.platform_fee_for_subscribers;
        } else {
            fee_factor = platform_store.platform_fee;
        };

        let platform_fee = (amount * fee_factor) / platform_store.platform_fee_divisor;
        
        let total_deduction = amount + platform_fee;
        assert!(locked_amount >= total_deduction, ERR_NOT_ENOUGH_BALANCE);

        // Update the locked amount (amount + fee)
        table::upsert(&mut store.escrows, campaign_id, locked_amount - total_deduction);

        let account_signer = account::create_signer_with_capability(&store.signer_cap);

        DATA::transfer(&account_signer, recipient, amount);
        DATA::transfer(&account_signer, @marketplace, platform_fee); 
    }

    // Displays the amount of locked funds
    #[view]
    public fun get_locked_amount(campaign_id: u64, store_addr: address): u64 acquires EscrowStore {
        let store = borrow_global<EscrowStore>(store_addr);
        assert!(table::contains(&store.escrows, campaign_id), ERR_ESCROW_NOT_FOUND);
        *table::borrow(&store.escrows, campaign_id)
    }

    #[test_only]
    public fun initialize_for_test(account: &signer) {
        init_module(account);
    }

    #[test]
    fun test_lock_funds() acquires EscrowStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let escrow_manager = account::create_account_for_test(@marketplace);
        
        DATA::initialize_for_test(&escrow_manager);


        // Give test tokens to test account
        DATA::mint_to(&escrow_manager, signer::address_of(&test_account), 10000);
        
        // Initialize module
        init_module(&escrow_manager);
        
        // Prepare test data
        let campaign_id = 1;
        let amount = 1000;
        
        // Lock funds
        lock_funds(&test_account, campaign_id, amount, @marketplace);
        
        // Check locked amount
        let locked_amount = get_locked_amount(campaign_id, @marketplace);
        assert!(locked_amount == amount, 1);
    }

    #[test]
    fun test_release_funds() acquires EscrowStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let recipient = account::create_account_for_test(@0x2);
        let escrow_manager = account::create_account_for_test(@marketplace);
        
        DATA::initialize_for_test(&escrow_manager);

        // Give test tokens to test account
        DATA::mint_to(&escrow_manager, signer::address_of(&test_account), 10000);
        
        // Initialize module
        init_module(&escrow_manager);
        
        // Prepare test data
        let campaign_id = 1;
        let amount = 1000;
        
        // Lock funds
        lock_funds(&test_account, campaign_id, amount, @marketplace);
        
        // Release funds
        release_funds(&escrow_manager, campaign_id, signer::address_of(&recipient), @marketplace);
        
        // Check balances
        let recipient_balance = DATA::get_balance(signer::address_of(&recipient));
        assert!(recipient_balance == amount, 1);
    }

    #[test]
    fun test_release_funds_for_data() acquires EscrowStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let contributor = account::create_account_for_test(@0x2);
        let escrow_manager = account::create_account_for_test(@marketplace);
        
        DATA::initialize_for_test(&escrow_manager);

        // Give test tokens to test account
        DATA::mint_to(&escrow_manager, signer::address_of(&test_account), 10000);
        
        // Initialize module
        init_module(&escrow_manager);
        
        // Prepare test data
        let campaign_id = 1;
        let total_amount = 1000;
        let release_amount = 500;
        let platform_fee = release_amount * 2 / 100;
        let total_deduction = release_amount + platform_fee;
        
        // Lock funds
        lock_funds(&test_account, campaign_id, total_amount, @marketplace);
        
        // Release funds for data contribution
        release_funds_for_contribution(campaign_id, signer::address_of(&contributor), release_amount);
        
        // Check remaining locked amount
        let remaining_locked = get_locked_amount(campaign_id, @marketplace);
        assert!(remaining_locked == total_amount - total_deduction, 1);
    }

    #[test]
    #[expected_failure(abort_code = ERR_ESCROW_NOT_FOUND)]
    fun test_get_locked_amount_nonexistent_campaign() acquires EscrowStore {
        // Create test account
        let escrow_manager = account::create_account_for_test(@marketplace);
        
        DATA::initialize_for_test(&escrow_manager);
        
        // Initialize module
        init_module(&escrow_manager);
        
        // Check locked amount for nonexistent campaign
        get_locked_amount(999, @marketplace);
    }
} 
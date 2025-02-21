module marketplace::escrow_manager {
    use std::signer;
    use std::table::{Self, Table};
    use marketplace::mamu;

    #[test_only]
    use aptos_framework::account;

    friend marketplace::contribution_manager;

    /// Escrow structure
    struct EscrowStore has key {
        escrows: Table<u64, u64>, // campaign_id -> amount
    }

    /// Error codes
    const ERR_NOT_ENOUGH_BALANCE: u64 = 1;
    const ERR_ESCROW_NOT_FOUND: u64 = 2;
    const ERR_UNAUTHORIZED: u64 = 3;

    /// Automatically runs when the module is initialized
    fun init_module(account: &signer) {
        // Register MAMU store for the marketplace account
        if (!mamu::is_account_registered(signer::address_of(account))) {
            mamu::register(account);
        };

        let store = EscrowStore {
            escrows: table::new(),
        };
        move_to(account, store);
    }

    /// Locks funds for a specific campaign
    public fun lock_funds(
        account: &signer,
        campaign_id: u64,
        amount: u64,
        store_addr: address
    ) acquires EscrowStore {
        // Check if the user has enough balance
        assert!(mamu::get_balance(signer::address_of(account)) >= amount, ERR_NOT_ENOUGH_BALANCE);

        let store = borrow_global_mut<EscrowStore>(store_addr);

        // Transfer the funds to marketplace account
        mamu::transfer(account, store_addr, amount);

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
        mamu::transfer(account, recipient, amount);
    }

    /// Releases funds for data contribution
    public(friend) fun release_funds_for_contribution(
        campaign_id: u64,
        recipient: address,
        amount: u64
    ) acquires EscrowStore {
        let store = borrow_global_mut<EscrowStore>(@marketplace);
        
        assert!(table::contains(&store.escrows, campaign_id), ERR_ESCROW_NOT_FOUND);

        let locked_amount = *table::borrow(&store.escrows, campaign_id);

        let platform_fee = amount * 2 / 100;
        let total_deduction = amount + platform_fee;
        assert!(locked_amount >= total_deduction, ERR_NOT_ENOUGH_BALANCE);

        // Update the locked amount (amount + fee)
        table::upsert(&mut store.escrows, campaign_id, locked_amount - total_deduction);

        // Since we can't get the marketplace signer here, we'll just track the amounts
        // The actual transfers will be handled by the marketplace account separately
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
        
        // Initialize MAMU token
        mamu::initialize_for_test(&escrow_manager);

        // Register accounts for MAMU
        mamu::register(&test_account);
        mamu::register(&escrow_manager);

        // Give test tokens to test account
        mamu::mint_to(&escrow_manager, signer::address_of(&test_account), 10000);
        
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
        
        // Initialize MAMU token
        mamu::initialize_for_test(&escrow_manager);

        // Register accounts for MAMU
        mamu::register(&test_account);
        mamu::register(&recipient);
        mamu::register(&escrow_manager);

        // Give test tokens to test account
        mamu::mint_to(&escrow_manager, signer::address_of(&test_account), 10000);
        
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
        let recipient_balance = mamu::get_balance(signer::address_of(&recipient));
        assert!(recipient_balance == amount, 1);
    }

    #[test]
    fun test_release_funds_for_data() acquires EscrowStore {
        // Create test accounts
        let test_account = account::create_account_for_test(@0x1);
        let contributor = account::create_account_for_test(@0x2);
        let escrow_manager = account::create_account_for_test(@marketplace);
        
        // Initialize MAMU token
        mamu::initialize_for_test(&escrow_manager);

        // Register accounts for MAMU
        mamu::register(&test_account);
        mamu::register(&contributor);
        mamu::register(&escrow_manager);

        // Give test tokens to test account
        mamu::mint_to(&escrow_manager, signer::address_of(&test_account), 10000);
        
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
        
        // Initialize MAMU token
        mamu::initialize_for_test(&escrow_manager);

        // Register account for MAMU
        mamu::register(&escrow_manager);
        
        // Initialize module
        init_module(&escrow_manager);
        
        // Check locked amount for nonexistent campaign
        get_locked_amount(999, @marketplace);
    }
} 
module mamutiki::mamu {
    use std::string;
    use std::signer;
    use std::vector;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability, CoinStore};
    use aptos_framework::account;

    /// =================== Constants ===================

    /// Token configuration
    const MOVEMENT_NAME: vector<u8> = b"MAMUTIKI";
    const MOVEMENT_SYMBOL: vector<u8> = b"MAMU";
    const MOVEMENT_DECIMALS: u8 = 6;

    /// Error codes
    const ENOT_AUTHORIZED: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EZERO_MINT_AMOUNT: u64 = 4;
    const EZERO_BURN_AMOUNT: u64 = 5;
    const ENOT_REGISTERED: u64 = 6;

    /// =================== Resources & Structs ===================

    /// Holds the refs for managing Movement
    struct MovementCapabilities has key {
        mint_cap: MintCapability<MAMU>,
        burn_cap: BurnCapability<MAMU>,
        freeze_cap: FreezeCapability<MAMU>,
    }

    /// The MAMU token type
    struct MAMU has key {}

    /// =================== Initialization ===================

    /// Initialize the Movement token
    fun init_module(module_signer: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MAMU>(
            module_signer,
            string::utf8(MOVEMENT_NAME),
            string::utf8(MOVEMENT_SYMBOL),
            MOVEMENT_DECIMALS,
            true // monitored_supply
        );

        move_to(module_signer, MovementCapabilities {
            mint_cap,
            burn_cap,
            freeze_cap,
        });
    }

    /// =================== View Functions ===================

    /// Get the balance of an account
    #[view]
    public fun get_balance(account: address): u64 {
        if (coin::is_account_registered<MAMU>(account)) {
            coin::balance<MAMU>(account)
        } else {
            0
        }
    }

    /// Get balances for multiple accounts
    #[view]
    public fun get_balances(accounts: vector<address>): vector<u64> {
        let balances = vector::empty<u64>();
        let i = 0;
        let len = vector::length(&accounts);
        
        while (i < len) {
            let account = *vector::borrow(&accounts, i);
            vector::push_back(&mut balances, get_balance(account));
            i = i + 1;
        };
        
        balances
    }

    /// Check if account is registered
    #[view]
    public fun is_account_registered(account: address): bool {
        coin::is_account_registered<MAMU>(account)
    }

    /// =================== Management Functions ===================

    /// Register an account to hold MAMU
    public entry fun register(account: &signer) {
        coin::register<MAMU>(account);
    }

    public entry fun check_register(account: &signer) {
        assert!(safe_register(account), ENOT_REGISTERED);
    }

    public fun safe_register(account: &signer): bool {
        if (!is_account_registered(signer::address_of(account))) {
            register(account);
        };

        is_account_registered(signer::address_of(account))
    }

    /// Mint new MAMU tokens to an account
    public entry fun mint_to(_admin: &signer, recipient: address, amount: u64) acquires MovementCapabilities {
        assert!(amount > 0, EZERO_MINT_AMOUNT);
        assert!(signer::address_of(_admin) == @mamutiki, ENOT_AUTHORIZED);
        check_register(_admin);

        let caps = borrow_global<MovementCapabilities>(@mamutiki);
        let coins = coin::mint<MAMU>(amount, &caps.mint_cap);
        coin::deposit(recipient, coins);
    }
    
    public entry fun mint(recipient: &signer, amount: u64) acquires MovementCapabilities {
        assert!(amount > 0, EZERO_MINT_AMOUNT);
        assert!(signer::address_of(recipient) == @mamutiki, ENOT_AUTHORIZED);
        check_register(recipient);

        let caps = borrow_global<MovementCapabilities>(@mamutiki);
        let coins = coin::mint<MAMU>(amount, &caps.mint_cap);
        coin::deposit(signer::address_of(recipient), coins);
    }

    /// =================== User Functions ===================

    /// Transfer MAMU between accounts
    public entry fun transfer(
        from: &signer,
        to: address,
        amount: u64,
    ) {
        assert!(amount > 0, EZERO_MINT_AMOUNT);
        assert!(coin::is_account_registered<MAMU>(to), ENOT_REGISTERED);
        coin::transfer<MAMU>(from, to, amount);
    }

    /// =================== Tests ===================

    #[test_only]
    public fun initialize_for_test(account: &signer) {
        init_module(account);
    }

    #[test(creator = @mamutiki)]
    fun test_init_and_mint(creator: &signer) acquires MovementCapabilities {
        // Initialize token
        init_module(creator);

        // Create test account
        let test_account = account::create_account_for_test(@0x123);

        // Register test account
        register(&test_account);

        // Mint tokens
        mint_to(creator, signer::address_of(&test_account), 1000);

        // Verify balance
        assert!(get_balance(@0x123) == 1000, 1);
    }
}

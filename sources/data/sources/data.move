module data::DATA {
    use std::string::{Self, String};
    use std::option;
    use std::signer;
    use aptos_framework::math64;
    use aptos_framework::object;
    use aptos_framework::event;
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, FungibleStore, Metadata};
    use aptos_framework::primary_fungible_store;

    /// =================== Constants ===================

    /// Token configuration
    const DATA_NAME: vector<u8> = b"Data Shares";
    const DATA_SYMBOL: vector<u8> = b"DATA";
    const DATA_DECIMALS: u8 = 6;
    const DATA_ICON: vector<u8> = b"https://datagora.xyz/token.png";
    const DATA_PROJECT_URI: vector<u8> = b"https://datagora.xyz/";
    const DATA_MAX_SUPPLY: u128 = 1000000000;

    /// Error codes
    const ENOT_AUTHORIZED: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const ESTORE_FROZEN: u64 = 3;
    const EZERO_MINT_AMOUNT: u64 = 4;
    const EZERO_BURN_AMOUNT: u64 = 5;
    const EFAUCET_LOCKED: u64 = 6;

    const ADMIN_ADDRESS: address = @data;

    /// =================== Resources & Structs ===================

    /// Holds the refs for managing DATA
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct DataManagement has key {
        mint_ref: MintRef,
        burn_ref: BurnRef,
        transfer_ref: TransferRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Faucet has key {
        is_locked: bool,
    }

    /// Events
    #[event]
    struct MintEvent has drop, store {
        amount: u64,
        recipient: address,
    }

    #[event]
    struct BurnEvent has drop, store {
        amount: u64,
        from: address,
    }

    #[event]
    struct TransferEvent has drop, store {
        amount: u64,
        from: address,
        to: address,
    }

    #[event]
    struct FreezeEvent has drop, store {
        account: address,
        frozen: bool,
    }

    /// =================== Initialization ===================

    /// Initialize the Movement token
    fun init_module(module_signer: &signer) {
        // Create metadata object with deterministic address
        let constructor_ref = &object::create_named_object(
            module_signer,
            DATA_SYMBOL,
        );

        // Create the fungible asset with support for primary stores
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::some(DATA_MAX_SUPPLY * (math64::pow(10, (DATA_DECIMALS as u64)) as u128)),
            string::utf8(DATA_NAME),
            string::utf8(DATA_SYMBOL),
            DATA_DECIMALS,
            string::utf8(DATA_ICON),
            string::utf8(DATA_PROJECT_URI),
        );

        move_to(
            module_signer,
            Faucet {
                is_locked: false,
            }
        );
        // Generate management references
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);

        // Store the management refs in metadata object
        let metadata_signer = &object::generate_signer(constructor_ref);
        move_to(
            metadata_signer,
            DataManagement {
                mint_ref,
                burn_ref,
                transfer_ref,
            }
        );
    }

    /// =================== View Functions ===================

    /// Get the metadata object of Movement
    #[view]
    public fun get_metadata(): object::Object<fungible_asset::Metadata> {
        object::address_to_object(
            object::create_object_address(&ADMIN_ADDRESS, DATA_SYMBOL)
        )
    }

    /// Get the balance of an account
    #[view]
    public fun get_balance(account: address): u64 {
        if (primary_fungible_store::primary_store_exists(account, get_metadata())) {
            primary_fungible_store::balance(account, get_metadata())
        } else {
            0
        }
    }

    /// Check if account store is frozen
    #[view]
    public fun is_frozen(account: address): bool {
        if (primary_fungible_store::primary_store_exists(account, get_metadata())) {
            primary_fungible_store::is_frozen(account, get_metadata())
        } else {
            false
        }
    }

    /// =================== Management Functions ===================

    /// Mint new tokens to recipient
    public entry fun mint_to(
        admin: &signer,
        recipient: address,
        amount: u64
    ) acquires DataManagement {
        // Verify amount
        assert!(signer::address_of(admin) == ADMIN_ADDRESS, ENOT_AUTHORIZED);
        assert!(amount > 0, EZERO_MINT_AMOUNT);

        // Get management struct
        let management = borrow_global<DataManagement>(
            object::object_address(&get_metadata())
        );

        // Mint tokens
        primary_fungible_store::mint(&management.mint_ref, recipient, amount);

        // Emit event
        event::emit(MintEvent {
            amount,
            recipient,
        });
    }

    public entry fun mint(
        admin: &signer,
        amount: u64
    ) acquires DataManagement {
        assert!(signer::address_of(admin) == ADMIN_ADDRESS, ENOT_AUTHORIZED);

        mint_to(admin, signer::address_of(admin), amount);
    }

    // =================== Faucet Functions ===================

    public fun mint_for_faucet(
        admin: &signer,
        amount: u64
    ) acquires DataManagement {
        assert!(amount > 0, EZERO_MINT_AMOUNT);

        // Get management struct
        let management = borrow_global<DataManagement>(
            object::object_address(&get_metadata())
        );

        let recipient = signer::address_of(admin);

        // Mint tokens
        primary_fungible_store::mint(&management.mint_ref, recipient, amount);

        // Emit event
        event::emit(MintEvent {
            amount,
            recipient,
        });
    }

    #[view]
    public fun is_faucet_locked(): bool acquires Faucet {
        borrow_global<Faucet>(@data).is_locked
    }

    public entry fun lock_faucet(
        admin: &signer
    ) acquires Faucet {
        assert!(signer::address_of(admin) == ADMIN_ADDRESS, ENOT_AUTHORIZED);

        let _faucet = borrow_global_mut<Faucet>(@data);
        _faucet.is_locked = true;
    }

    public entry fun unlock_faucet(
        admin: &signer
    ) acquires Faucet {
        assert!(signer::address_of(admin) == ADMIN_ADDRESS, ENOT_AUTHORIZED);

        let _faucet = borrow_global_mut<Faucet>(@data);
        _faucet.is_locked = false;
    }

    public entry fun faucet(
        admin: &signer,
    ) acquires DataManagement, Faucet {
        assert!(!is_faucet_locked(), EFAUCET_LOCKED);

        let _amount = 5000 * math64::pow(10, (DATA_DECIMALS as u64));
        mint_for_faucet(admin, _amount);
    }

    // =================== Burn Functions ===================

    /// Burn tokens from an account
    public entry fun burn_from(
        admin: &signer,
        account: address,
        amount: u64
    ) acquires DataManagement {
        // Verify amount
        assert!(amount > 0, EZERO_BURN_AMOUNT);

        // Get management struct
        let management = borrow_global<DataManagement>(
            object::object_address(&get_metadata())
        );

        // Burn tokens
        primary_fungible_store::burn(&management.burn_ref, account, amount);

        // Emit event
        event::emit(BurnEvent {
            amount,
            from: account,
        });
    }

    /// Freeze or unfreeze an account
    public entry fun set_frozen(
        admin: &signer,
        account: address,
        frozen: bool
    ) acquires DataManagement {
        // Get management struct
        let management = borrow_global<DataManagement>(
            object::object_address(&get_metadata())
        );

        // Set frozen status
        primary_fungible_store::set_frozen_flag(&management.transfer_ref, account, frozen);

        // Emit event
        event::emit(FreezeEvent {
            account,
            frozen,
        });
    }

    /// =================== User Functions ===================

    /// Transfer tokens from sender to recipient
    public entry fun transfer(
        from: &signer,
        to: address,
        amount: u64
    ) {
        // Verify amount
        assert!(amount > 0, EINSUFFICIENT_BALANCE);

        // Perform transfer
        primary_fungible_store::transfer(from, get_metadata(), to, amount);
    }

    /// Force transfer (admin only)
    public entry fun force_transfer(
        admin: &signer,
        from: address,
        to: address,
        amount: u64
    ) acquires DataManagement {
        // Get management struct
        let management = borrow_global<DataManagement>(
            object::object_address(&get_metadata())
        );

        // Perform force transfer
        primary_fungible_store::transfer_with_ref(
            &management.transfer_ref,
            from,
            to,
            amount
        );

        // Emit event
        event::emit(TransferEvent {
            amount,
            from,
            to,
        });
    }

    /// =================== Tests ===================

    #[test_only]
    use aptos_framework::account;

    #[test(creator = ADMIN_ADDRESS)]
    fun test_init_and_mint(creator: &signer) acquires DataManagement {
        // Initialize token
        init_module(creator);

        // Create test account
        let test_account = account::create_account_for_test(@0x123);

        // Mint tokens
        mint_to(creator, @0x123, 1000);

        // Verify balance
        assert!(get_balance(@0x123) == 1000, 1);
    }

    #[test(creator = ADMIN_ADDRESS)]
    fun test_freeze_unfreeze(creator: &signer) acquires DataManagement {
        // Initialize
        init_module(creator);

        // Create test account
        let test_account = account::create_account_for_test(@0x123);

        // Mint tokens
        mint_to(creator, @0x123, 1000);

        // Freeze account
        set_frozen(creator, @0x123, true);
        assert!(is_frozen(@0x123), 1);

        // Unfreeze account
        set_frozen(creator, @0x123, false);
        assert!(!is_frozen(@0x123), 2);
    }
}

module marketplace::verifier {
    use std::signer;
    use std::vector;
    use std::string::String;
    use aptos_std::ed25519;
    use aptos_std::hash;
    use aptos_std::bcs;

    friend marketplace::contribution_manager;

    // Trusted public keys store
    struct TrustedPublicKeys has key {
        creator: address,
        keys: vector<vector<u8>>,
    }

    // Error codes
    const ERR_NOT_CREATOR: u64 = 1;
    const ERR_KEY_ALREADY_EXISTS: u64 = 2;
    const ERR_KEY_NOT_FOUND: u64 = 3;

    public fun initialize(account: &signer) {
        // Initialize trusted public keys with empty vector
        let trusted_keys = TrustedPublicKeys {
            creator: signer::address_of(account),
            keys: vector::empty<vector<u8>>(),
        };
        move_to(account, trusted_keys);
    }

    // Add a new trusted public key
    public entry fun add_trusted_key(account: &signer, public_key: vector<u8>) acquires TrustedPublicKeys {
        let trusted_keys = borrow_global_mut<TrustedPublicKeys>(@marketplace);
        assert!(signer::address_of(account) == trusted_keys.creator, ERR_NOT_CREATOR);
        
        // Check if key already exists
        let i = 0;
        let len = vector::length(&trusted_keys.keys);
        while (i < len) {
            assert!(*vector::borrow(&trusted_keys.keys, i) != public_key, ERR_KEY_ALREADY_EXISTS);
            i = i + 1;
        };
        
        vector::push_back(&mut trusted_keys.keys, public_key);
    }

    // Remove a trusted public key
    public entry fun remove_trusted_key(account: &signer, public_key: vector<u8>) acquires TrustedPublicKeys {
        let trusted_keys = borrow_global_mut<TrustedPublicKeys>(@marketplace);
        assert!(signer::address_of(account) == trusted_keys.creator, ERR_NOT_CREATOR);
        
        let i = 0;
        let len = vector::length(&trusted_keys.keys);
        let found = false;
        
        while (i < len) {
            if (*vector::borrow(&trusted_keys.keys, i) == public_key) {
                vector::remove(&mut trusted_keys.keys, i);
                found = true;
                break
            };
            i = i + 1;
        };
        
        assert!(found, ERR_KEY_NOT_FOUND);
    }

    // Get all trusted public keys
    #[view]
    public fun get_trusted_keys(): vector<vector<u8>> acquires TrustedPublicKeys {
        let trusted_keys = borrow_global<TrustedPublicKeys>(@marketplace);
        trusted_keys.keys
    }

    // Verify signature for contribution data
    public(friend) fun verify_contribution_signature(
        sender: address,
        campaign_id: u64,
        data_count: u64,
        store_cid: String,
        score: u64,
        key_for_decryption: String,
        signature: vector<u8>
    ): bool acquires TrustedPublicKeys {
        // Create a simple message to sign
        let message = vector::empty<u8>();
        vector::append(&mut message, *&sender_to_bytes(sender));
        vector::append(&mut message, *&u64_to_bytes(campaign_id));
        vector::append(&mut message, *&u64_to_bytes(data_count));
        vector::append(&mut message, *&string_to_bytes(store_cid));
        vector::append(&mut message, *&u64_to_bytes(score));
        vector::append(&mut message, *&string_to_bytes(key_for_decryption));
        
        let message_hash = hash::sha2_256(message);
        let signature = ed25519::new_signature_from_bytes(signature);
        
        let trusted_keys = borrow_global<TrustedPublicKeys>(@marketplace);
        let i = 0;
        let len = vector::length(&trusted_keys.keys);
        
        while (i < len) {
            let public_key = vector::borrow(&trusted_keys.keys, i);
            let unvalidated_public_key = ed25519::new_unvalidated_public_key_from_bytes(*public_key);
            if (ed25519::signature_verify_strict(&signature, &unvalidated_public_key, message_hash)) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    // Helper function to convert address to bytes
    fun sender_to_bytes(sender: address): vector<u8> {
        let bytes = vector::empty<u8>();
        let addr_bytes = std::bcs::to_bytes(&sender);
        let i = 0;
        let len = vector::length(&addr_bytes);
        while (i < len) {
            vector::push_back(&mut bytes, *vector::borrow(&addr_bytes, i));
            i = i + 1;
        };
        bytes
    }

    // Helper function to convert u64 to bytes
    fun u64_to_bytes(value: u64): vector<u8> {
        let bytes = vector::empty<u8>();
        let i = 0;
        while (i < 8) {
            vector::push_back(&mut bytes, ((value >> ((7 - i) * 8)) as u8));
            i = i + 1;
        };
        bytes
    }

    // Helper function to convert string to bytes
    fun string_to_bytes(value: String): vector<u8> {
        let bytes = vector::empty<u8>();
        let str_bytes = std::string::bytes(&value);
        let len = vector::length(str_bytes);
        let i = 0;
        while (i < len) {
            vector::push_back(&mut bytes, *vector::borrow(str_bytes, i));
            i = i + 1;
        };
        bytes
    }

    #[test_only]
    public fun initialize_for_test(account: &signer) {
        initialize(account);
    }

    #[test]
    fun test_add_and_remove_key() acquires TrustedPublicKeys {
        // Create test account
        let test_account = aptos_framework::account::create_account_for_test(@marketplace);
        
        // Initialize module
        initialize(&test_account);
        
        // Add test key
        let test_key = b"test_key_1";
        add_trusted_key(&test_account, test_key);
        
        // Verify key was added
        let keys = get_trusted_keys();
        assert!(vector::length(&keys) == 1, 1);
        assert!(*vector::borrow(&keys, 0) == test_key, 2);
        
        // Remove test key
        remove_trusted_key(&test_account, test_key);
        
        // Verify key was removed
        let keys = get_trusted_keys();
        assert!(vector::length(&keys) == 0, 3);
    }

    #[test]
    #[expected_failure(abort_code = ERR_KEY_ALREADY_EXISTS)]
    fun test_add_duplicate_key() acquires TrustedPublicKeys {
        // Create test account
        let test_account = aptos_framework::account::create_account_for_test(@marketplace);
        
        // Initialize module
        initialize(&test_account);
        
        // Add test key twice
        let test_key = b"test_key_1";
        add_trusted_key(&test_account, test_key);
        add_trusted_key(&test_account, test_key); // Should fail
    }

    #[test]
    #[expected_failure(abort_code = ERR_NOT_CREATOR)]
    fun test_add_key_unauthorized() acquires TrustedPublicKeys {
        // Create test accounts
        let marketplace_account = aptos_framework::account::create_account_for_test(@marketplace);
        let unauthorized_account = aptos_framework::account::create_account_for_test(@0x1);
        
        // Initialize module
        initialize(&marketplace_account);
        
        // Try to add key with unauthorized account
        add_trusted_key(&unauthorized_account, b"test_key_1"); // Should fail
    }
} 
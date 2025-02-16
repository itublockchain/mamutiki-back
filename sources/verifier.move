module marketplace::verifier {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_framework::bcs;
    use aptos_std::ed25519;
    use aptos_std::hash;

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
        campaign_id: u64,
        data_count: u64,
        store_cid: String,
        score: u64,
        key_for_decryption: String,
        signature: vector<u8>
    ): bool acquires TrustedPublicKeys {
        let message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&campaign_id));
        vector::append(&mut message, bcs::to_bytes(&data_count));
        
        let store_cid_bytes = string::bytes(&store_cid);
        vector::append(&mut message, bcs::to_bytes(&(store_cid_bytes.length() as u64)));
        vector::append(&mut message, *store_cid_bytes);
        
        vector::append(&mut message, bcs::to_bytes(&score));
        vector::append(&mut message, bcs::to_bytes(&key_for_decryption));
        
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

    #[test_only]
    public fun initialize_for_test(account: &signer) {
        initialize(account);
    }
} 
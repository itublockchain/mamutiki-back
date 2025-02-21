module marketplace::verifier {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
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
    const ERR_INVALID_SIGNATURE: u64 = 4;
    const ERR_INVALID_MESSAGE: u64 = 5;
    const ERR_NO_TRUSTED_KEYS: u64 = 6;

    fun append_bytes(message: &mut vector<u8>, bytes: vector<u8>) {
        let i = 0;
        let len = vector::length(&bytes);
        while (i < len) {
            vector::push_back(message, *vector::borrow(&bytes, i));
            i = i + 1;
        }
    }

    public fun initialize(account: &signer) {
        let trusted_keys = TrustedPublicKeys {
            creator: signer::address_of(account),
            keys: vector::empty<vector<u8>>(),
        };
        move_to(account, trusted_keys);
    }

    public entry fun add_trusted_key(account: &signer, public_key: vector<u8>) acquires TrustedPublicKeys {
        let trusted_keys = borrow_global_mut<TrustedPublicKeys>(@marketplace);
        assert!(signer::address_of(account) == trusted_keys.creator, ERR_NOT_CREATOR);
        
        let i = 0;
        let len = vector::length(&trusted_keys.keys);
        while (i < len) {
            if (*vector::borrow(&trusted_keys.keys, i) == public_key) {
                assert!(false, ERR_KEY_ALREADY_EXISTS)
            };
            i = i + 1;
        };
        
        vector::push_back(&mut trusted_keys.keys, public_key);
    }

    public entry fun remove_trusted_key(account: &signer, public_key: vector<u8>) acquires TrustedPublicKeys {
        let trusted_keys = borrow_global_mut<TrustedPublicKeys>(@marketplace);
        assert!(signer::address_of(account) == trusted_keys.creator, ERR_NOT_CREATOR);
        
        let i = 0;
        let len = vector::length(&trusted_keys.keys);
        let found = false;
        let index = 0;
        
        while (i < len) {
            if (*vector::borrow(&trusted_keys.keys, i) == public_key) {
                found = true;
                index = i;
                break
            };
            i = i + 1;
        };
        
        assert!(found, ERR_KEY_NOT_FOUND);
        vector::remove(&mut trusted_keys.keys, index);
    }

    #[view]
    public fun get_trusted_keys(): vector<vector<u8>> acquires TrustedPublicKeys {
        let trusted_keys = borrow_global<TrustedPublicKeys>(@marketplace);
        trusted_keys.keys
    }

    public(friend) fun verify_contribution_signature(
        sender: address,
        campaign_id: u64,
        data_count: u64,
        store_cid: String,
        score: u64,
        key_for_decryption: String,
        signature: vector<u8>
    ): bool acquires TrustedPublicKeys {
        let trusted_keys = borrow_global<TrustedPublicKeys>(@marketplace);
        assert!(vector::length(&trusted_keys.keys) > 0, ERR_NO_TRUSTED_KEYS);

        let message = vector::empty<u8>();
        let sender_bytes = bcs::to_bytes(&sender);
        let campaign_id_bytes = bcs::to_bytes(&campaign_id);
        let data_count_bytes = bcs::to_bytes(&data_count);
        let store_cid_bytes = *string::bytes(&store_cid);
        let score_bytes = bcs::to_bytes(&score);
        let key_bytes = *string::bytes(&key_for_decryption);

        append_bytes(&mut message, sender_bytes);
        append_bytes(&mut message, campaign_id_bytes);
        append_bytes(&mut message, data_count_bytes);
        append_bytes(&mut message, store_cid_bytes);
        append_bytes(&mut message, score_bytes);
        append_bytes(&mut message, key_bytes);
        
        let message_hash = hash::sha2_256(message);
        let signature = ed25519::new_signature_from_bytes(signature);
        
        let i = 0;
        let len = vector::length(&trusted_keys.keys);
        while (i < len) {
            let public_key = vector::borrow(&trusted_keys.keys, i);
            let pk = ed25519::new_unvalidated_public_key_from_bytes(*public_key);
            if (ed25519::signature_verify_strict(&signature, &pk, message_hash)) {
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

    #[test]
    fun test_add_and_remove_key() acquires TrustedPublicKeys {
        use aptos_framework::account;
        
        let test_account = account::create_account_for_test(@marketplace);
        initialize(&test_account);
        
        let test_key = b"test_key_1";
        add_trusted_key(&test_account, test_key);
        
        let keys = get_trusted_keys();
        assert!(vector::length(&keys) == 1, 1);
        assert!(*vector::borrow(&keys, 0) == test_key, 2);
        
        remove_trusted_key(&test_account, test_key);
        
        let keys = get_trusted_keys();
        assert!(vector::length(&keys) == 0, 3);
    }

    #[test]
    #[expected_failure(abort_code = ERR_KEY_ALREADY_EXISTS)]
    fun test_add_duplicate_key() acquires TrustedPublicKeys {
        use aptos_framework::account;
        
        let test_account = account::create_account_for_test(@marketplace);
        initialize(&test_account);
        
        let test_key = b"test_key_1";
        add_trusted_key(&test_account, test_key);
        add_trusted_key(&test_account, test_key);
    }

    #[test]
    #[expected_failure(abort_code = ERR_NOT_CREATOR)]
    fun test_add_key_unauthorized() acquires TrustedPublicKeys {
        use aptos_framework::account;
        
        let marketplace_account = account::create_account_for_test(@marketplace);
        let unauthorized_account = account::create_account_for_test(@0x1);
        
        initialize(&marketplace_account);
        add_trusted_key(&unauthorized_account, b"test_key_1");
    }
} 
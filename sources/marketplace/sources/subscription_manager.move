module marketplace::subscription_manager {
    use std::signer;
    use aptos_framework::timestamp;
    use std::table::{Self, Table};

    use mamutiki::mamu::{Self, MAMU};

    #[test_only]
    use aptos_framework::account;

    /// Structure that holds the subscription price
    struct SubscriptionPrice has key {
        price: u64 // Price in MAMU tokens
    }

    /// Structure that holds subscriptions
    struct Subscriptions has key {
        subscriptions: Table<address, u64> // address -> expiration time
    }

    /// Error codes
    const ENOT_CREATOR: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EINVALID_PRICE: u64 = 3;
    const EACTIVE_SUBSCRIPTION_EXISTS: u64 = 4;

    /// Initial price (10 MAMU = 1_000_000_000 octa)
    const INITIAL_PRICE: u64 = 100_000_000;
    const SUBSCRIPTION_DURATION: u64 = 2592000; // 30 days (in seconds)

    fun init_module(creator: &signer) {
        // Set initial price
        move_to(creator, SubscriptionPrice {
            price: INITIAL_PRICE
        });

        // Create subscription table
        move_to(creator, Subscriptions {
            subscriptions: table::new()
        });
    }

    /// Update subscription price (creator only)
    public entry fun update_price(creator: &signer, new_price: u64) acquires SubscriptionPrice {
        assert!(signer::address_of(creator) == @marketplace, ENOT_CREATOR);
        assert!(new_price > 0, EINVALID_PRICE);

        let price = borrow_global_mut<SubscriptionPrice>(@marketplace);
        price.price = new_price;
    }

    /// Subscribe to the service
    public entry fun subscribe(subscriber: &signer) acquires SubscriptionPrice, Subscriptions {
        let subscriber_addr = signer::address_of(subscriber);
        let price = borrow_global<SubscriptionPrice>(@marketplace).price;
        
        // Check if user has active subscription
        let subscriptions = borrow_global<Subscriptions>(@marketplace);
        if (table::contains(&subscriptions.subscriptions, subscriber_addr)) {
            let current_time = timestamp::now_seconds();
            let end_time = table::borrow(&subscriptions.subscriptions, subscriber_addr);
            assert!(current_time > *end_time, EACTIVE_SUBSCRIPTION_EXISTS);
        };
        
        // Process payment directly to marketplace address
        mamu::transfer(subscriber, @marketplace, price);

        // Set subscription duration
        let end_time = timestamp::now_seconds() + SUBSCRIPTION_DURATION;
        let subscriptions = borrow_global_mut<Subscriptions>(@marketplace);
        
        if (table::contains(&subscriptions.subscriptions, subscriber_addr)) {
            let current_end_time = table::borrow_mut(&mut subscriptions.subscriptions, subscriber_addr);
            *current_end_time = end_time;
        } else {
            table::add(&mut subscriptions.subscriptions, subscriber_addr, end_time);
        };
    }

    #[view]
    public fun check_subscription(subscriber: address): (bool, u64) acquires Subscriptions {
        let subscriptions = borrow_global<Subscriptions>(@marketplace);
        
        if (!table::contains(&subscriptions.subscriptions, subscriber)) {
            return (false, 0)
        };

        let end_time = table::borrow(&subscriptions.subscriptions, subscriber);
        let current_time = timestamp::now_seconds();
        
        if (current_time > *end_time) {
            (false, 0)
        } else {
            (true, *end_time - current_time)
        }
    }

    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test(creator = @marketplace, subscriber = @0x123, framework = @aptos_framework)]
    fun test_subscription_flow(
        creator: &signer,
        subscriber: &signer,
        framework: &signer
    ) acquires SubscriptionPrice, Subscriptions {
        // Create test accounts
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(subscriber));

        // Initialize timestamp
        timestamp::set_time_has_started_for_testing(framework);

        // Initialize MAMU token
        MAMU::initialize_for_test(creator);

        // Register accounts for MAMU
        MAMU::register(creator);
        MAMU::register(subscriber);

        // Give test tokens to subscriber (100 MAMU)
        MAMU::mint_to(creator, signer::address_of(subscriber), 100_000_000_000);

        // Initialize subscription module
        init_module(creator);

        // Subscribe
        subscribe(subscriber);

        // Check subscription status
        let (is_subscribed, remaining_time) = check_subscription(signer::address_of(subscriber));
        assert!(is_subscribed, 1);
        assert!(remaining_time > 0, 2);
        assert!(remaining_time <= SUBSCRIPTION_DURATION, 3);
    }
} 
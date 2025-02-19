import BaseManager from "./BaseManager";
import AptosUtils from "../utils/AptosUtils";

class SubscriptionManager extends BaseManager {
  async subscribe(): Promise<string> {
    const payload = AptosUtils.createEntryPayload(
      `${this.moduleAddress}::subscription_manager::subscribe`,
      []
    );

    return this.executeTransaction(payload);
  }

  async checkSubscription(subscriber: string): Promise<[boolean, number]> {
    try {
      const response = await this.viewFunction(
        "subscription_manager::check_subscription",
        [subscriber]
      );
      return [response[0], Number(response[1])];
    } catch {
      return [false, 0];
    }
  }

  async updatePrice(newPrice: number): Promise<string> {
    const payload = AptosUtils.createEntryPayload(
      `${this.moduleAddress}::subscription_manager::update_price`,
      [newPrice.toString()]
    );

    return this.executeTransaction(payload);
  }
}

export default SubscriptionManager;

import BaseManager from "./BaseManager";
import terminal from "../utils/console";

// Campaign Manager
class EscrowManager extends BaseManager {
  async setPlatformFeeDivisor(divisor: number): Promise<string> {
    try {
      const txn = await this.executeTransaction({
        type: "entry_function_payload",
        function: `${this.moduleAddress}::escrow_manager::set_platform_fee_divisor`,
        type_arguments: [],
        arguments: [divisor],
      });

      return txn;
    } catch (error) {
      terminal.error(
        "- [Escrow Manager] An error occurred while setting the platform fee divisor:",
        error
      );
      throw error;
    }
  }

  async setPlatformFee(fee: number): Promise<string> {
    try {
      const txn = await this.executeTransaction({
        type: "entry_function_payload",
        function: `${this.moduleAddress}::escrow_manager::set_platform_fee`,
        type_arguments: [],
        arguments: [fee],
      });

      return txn;
    } catch (error) {
      terminal.error(
        "- [Escrow Manager] An error occurred while setting the platform fee:",
        error
      );
      throw error;
    }
  }

  async setPlatformFeeForSubscribers(fee: number): Promise<string> {
    try {
      const txn = await this.executeTransaction({
        type: "entry_function_payload",
        function: `${this.moduleAddress}::escrow_manager::set_subscriber_platform_fee`,
        type_arguments: [],
        arguments: [fee],
      });

      return txn;
    } catch (error) {
      terminal.error(
        "- [Escrow Manager] An error occurred while setting the platform fee for subscribers:",
        error
      );
      throw error;
    }
  }
}

export default EscrowManager;

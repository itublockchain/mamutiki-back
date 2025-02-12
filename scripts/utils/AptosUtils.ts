import { Types } from "aptos";

// Utility Functions
class AptosUtils {
    static stringToBytes(str: string): number[] {
      return Array.from(Buffer.from(str));
    }
  
    static bytesToString(bytes: number[]): string {
      return Buffer.from(bytes).toString();
    }
  
    static hexToBytes(hex: string): number[] {
      return Array.from(
        Buffer.from(hex.startsWith("0x") ? hex.slice(2) : hex, "hex")
      );
    }
  
    static formatBalance(amount: number, decimals: number = 8): string {
      return (amount / Math.pow(10, decimals)).toFixed(decimals);
    }
  
    static createEntryPayload(
      func: string,
      args: any[]
    ): Types.EntryFunctionPayload {
      return {
        function: func,
        type_arguments: [],
        arguments: args,
      };
  }
}

export default AptosUtils;

import CustomConsole from "@batikankutluer/custom-console";
import dotenv from "dotenv";
dotenv.config();

export const isTest = process.env.TEST === "true";
export default CustomConsole({ test: isTest });

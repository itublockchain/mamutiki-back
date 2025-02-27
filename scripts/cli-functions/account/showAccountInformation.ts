import terminal from "../../utils/console";

export default async function showAccountInformation(sdk: any) {
  terminal.write("\nAccount loaded!");
  terminal.write("Address:", `${sdk._account.accountAddress}`);

  const balance = await sdk.account.getBalance();
  terminal.write("Balance:", balance.formatted, "$MOVE\n");
}

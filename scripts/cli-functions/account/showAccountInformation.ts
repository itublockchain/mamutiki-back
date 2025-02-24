import terminal from "../../utils/console";

export default async function showAccountInformation(sdk: any) {
  terminal.write("\nHesap yüklendi!");
  terminal.write("Adres:", `${sdk._account.accountAddress}`);

  const balance = await sdk.account.getBalance();
  terminal.write("Bakiye:", balance.formatted, "MOVE\n");
}

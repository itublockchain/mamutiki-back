import inquirer from "inquirer";
import terminal from "../utils/console";

export default async function help() {
  terminal.write("\nAvailable commands:");
  terminal.write("1. Add trusted key");
  terminal.write("\n2. Create campaign (with default values)");
  terminal.write("\n3. List campaigns");
  terminal.write("\n4. Add contribution");
  terminal.write("\n5. List contributions");
  terminal.write("\n6. Create subscription");
  terminal.write("\n7. Update subscription price");
  terminal.write("\n8. Mint token");
  terminal.write("\n9. Transfer token");
  terminal.write("\n10. Help");
  terminal.write("\n11. Exit");

  await inquirer.prompt([
    {
      type: "input",
      name: "input",
      message: "Press any key to continue...",
    },
  ]);
}

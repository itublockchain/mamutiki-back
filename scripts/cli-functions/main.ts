import inquirer from "inquirer";
import chalk from "chalk";

import cli from "./index";

export default async function main() {
  const answer = await inquirer.prompt([
    {
      type: "rawlist",
      name: "action",
      message: "What do you want to do?",
      choices: [
        { name: chalk.yellow("Add trusted key"), value: "Add trusted key" },
        new inquirer.Separator(),
        {
          name: chalk.greenBright("Create campaign"),
          value: "Create campaign",
        },
        { name: chalk.green("Add contribution"), value: "Add contribution" },
        new inquirer.Separator(),
        { name: chalk.blueBright("List campaigns"), value: "List campaigns" },
        { name: chalk.blue("List contributions"), value: "List contributions" },
        new inquirer.Separator(),
        { name: chalk.magenta("Mint token"), value: "Mint token" },
        { name: chalk.magenta("Transfer token"), value: "Transfer token" },
        { name: chalk.magenta("Faucet"), value: "Faucet" },
        new inquirer.Separator(),
        { name: "Register", value: "Register" },
        { name: "Subscribe", value: "Subscribe" },
        { name: "Update price", value: "Update price" },
        new inquirer.Separator(),
        { name: chalk.yellowBright("Publish"), value: "Publish" },
        new inquirer.Separator(),
        { name: chalk.gray("Help"), value: "Help" },
        { name: chalk.red("Exit"), value: "Exit" },
      ],
    },
  ]);

  switch (answer.action) {
    case "Add trusted key":
      await cli.addTrustedKey();
      break;
    case "Create campaign":
      await cli.createCampaign();
      break;
    case "List campaigns":
      await cli.listCampaigns();
      break;
    case "Add contribution":
      await cli.addContribution();
      break;
    case "List contributions":
      await cli.listContributions();
      break;
    case "Mint token":
      await cli.mintToken();
      break;
    case "Transfer token":
      await cli.transferToken();
      break;
    case "Faucet":
      await cli.faucet();
      break;
    case "Register":
      await cli.register();
      break;
    case "Subscribe":
      await cli.subscribe();
      break;
    case "Update price":
      await cli.updatePrice();
      break;
    case "Publish":
      await cli.publish();
      break;
    case "Help":
      await cli.help();
      break;
    case "Exit":
      process.exit(0);
  }
}

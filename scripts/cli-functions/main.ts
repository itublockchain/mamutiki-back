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
        {
          name: chalk.yellow("Remove trusted key"),
          value: "Remove trusted key",
        },
        new inquirer.Separator(),
        {
          name: chalk.greenBright("Create campaign"),
          value: "Create campaign",
        },
        { name: chalk.green("Add contribution"), value: "Add contribution" },
        new inquirer.Separator(),
        { name: chalk.blueBright("List campaigns"), value: "List campaigns" },
        { name: chalk.blue("List contributions"), value: "List contributions" },
        {
          name: chalk.blue("Get all active campaigns"),
          value: "Get all active campaigns",
        },
        {
          name: chalk.blue("Get last created campaign"),
          value: "Get last created campaign",
        },
        {
          name: chalk.blue("Close campaign by id"),
          value: "Close campaign by id",
        },
        new inquirer.Separator(),
        { name: chalk.yellowBright("Publish Module"), value: "Publish" },
        new inquirer.Separator(),
        { name: chalk.magenta("Mint token"), value: "Mint token" },
        { name: chalk.magenta("Transfer token"), value: "Transfer token" },
        { name: chalk.magenta("Faucet"), value: "Faucet" },
        new inquirer.Separator(),
        {
          name: chalk.cyanBright("Set platform fee"),
          value: "Set platform fee",
        },
        {
          name: chalk.cyan("Set subscriber platform fee"),
          value: "Set subscriber platform fee",
        },
        {
          name: chalk.cyan("Set platform fee divisor"),
          value: "Set platform fee divisor",
        },
        new inquirer.Separator(),
        { name: "Subscribe", value: "Subscribe" },
        { name: "Update price", value: "Update price" },
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
    case "Remove trusted key":
      await cli.removeTrustedKey();
      break;
    case "Create campaign":
      await cli.createCampaign();
      break;
    case "List campaigns":
      await cli.listCampaigns();
      break;
    case "Get all active campaigns":
      await cli.getAllActiveCampaigns();
      break;
    case "Get last created campaign":
      await cli.lastCreatedCampaign();
      break;
    case "Close campaign by id":
      await cli.closeCampaignById();
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
    case "Subscribe":
      await cli.subscribe();
      break;
    case "Update price":
      await cli.updatePrice();
      break;
    case "Publish":
      await cli.publish();
      break;
    case "Set platform fee":
      await cli.setPlatformFee();
      break;
    case "Set platform fee divisor":
      await cli.setPlatformFeeDivisor();
      break;
    case "Set subscriber platform fee":
      await cli.setSubscriberPlatformFee();
      break;
    case "Help":
      await cli.help();
      break;
    case "Exit":
      process.exit(0);
  }
}

import { Command } from "commander";

import * as dotenv from "dotenv";
dotenv.config();

import cli from "./cli-functions/index";

const mamutiki = new Command();

mamutiki.version("1.0.0");
mamutiki.name("mamutiki");
mamutiki.description("MAMUTIKI CLI");

mamutiki
  .command("add-trusted-key")
  .argument("<publicKey>")
  .action(async (publicKey: string) => await cli.addTrustedKey(publicKey));

mamutiki
  .command("create-campaign")
  .action(async () => await cli.createCampaign());

mamutiki
  .command("list-campaigns")
  .action(async () => await cli.listCampaigns());

mamutiki
  .command("add-contribution")
  .argument("<campaignId>")
  .action(async (campaignId) => await cli.addContribution(campaignId));

mamutiki
  .command("list-contributions")
  .argument("<campaignId>")
  .action(async (campaignId) => await cli.listContributions(campaignId));

mamutiki
  .command("mint-token")
  .argument("<amount>")
  .action(async (amount) => await cli.mintToken(amount));

mamutiki.command("subscribe").action(async () => await cli.subscribe());

mamutiki.command("update-price").action(async () => await cli.updatePrice());

mamutiki.command("help").action(async () => await cli.help());

mamutiki.parse(process.argv);

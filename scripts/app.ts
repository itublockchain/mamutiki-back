import { Command } from "commander";

import * as dotenv from "dotenv";
dotenv.config();

import cli from "./cli-functions/index";

const datagora = new Command();

datagora.version("1.0.0");
datagora.name("Datagora");
datagora.description("Datagora CLI");

datagora.command("help").action(async () => await cli.help());

datagora.command("start").action(async () => await cli.main());

datagora.parse(process.argv);

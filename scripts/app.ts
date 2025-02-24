import { Command } from "commander";

import * as dotenv from "dotenv";
dotenv.config();

import cli from "./cli-functions/index";

const mamutiki = new Command();

mamutiki.version("1.0.0");
mamutiki.name("mamutiki");
mamutiki.description("MAMUTIKI CLI");

mamutiki.command("help").action(async () => await cli.help());

mamutiki.command("start").action(async () => await cli.main());

mamutiki.parse(process.argv);

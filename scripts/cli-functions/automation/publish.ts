import inquirer from "inquirer";
import { initSDK } from "../../utils/init-sdk";

import { execSync } from "node:child_process";

import fs from "fs";
import { resolve } from "path";
import { parseDocument } from "yaml";
import toml from "toml";

import cli from "../";
import terminal from "../../utils/console";
import chalk from "chalk";

type CONFIG_YAML = {
  profiles: {
    [profile_name: string]: PROFILE;
  };
};

type PROFILE = {
  network: string;
  private_key: string;
  public_key: string;
  account: string;
  rest_url: string;
  faucet_url?: string;
};

export default async function publish() {
  try {
    // Parse config.yaml
    const modules = ["mamutiki", "marketplace", "data"];

    const module_sources = [
      {
        name: "mamutiki",
        source: "sources/mamu",
      },
      {
        name: "marketplace",
        source: "sources/marketplace",
      },
      {
        name: "data",
        source: "sources/data",
      },
    ];

    // Starts...

    const { module_name } = await inquirer.prompt([
      {
        type: "rawlist",
        name: "module_name",
        message: "Choose module to publish:",
        choices: modules,
      },
    ]);

    const module_source = module_sources.find(
      (module) => module.name === module_name
    )?.source;

    const file = fs.readFileSync(
      resolve(`${module_source}/.movement/config.yaml`),
      "utf8"
    );
    const doc = parseDocument(file);

    const json: CONFIG_YAML = doc.toJSON();

    let profiles = [];

    for (let name in json.profiles) {
      profiles.push({ name, profile: json.profiles[name] });
    }

    const { selected_profile } = await inquirer.prompt([
      {
        type: "rawlist",
        name: "selected_profile",
        message: "Select a profile to use:",
        choices: profiles.map((prf) => ({
          name: prf.name,
          value: prf,
        })),
      },
    ]);

    const command = `movement move publish --package-dir ${module_source} --url ${selected_profile.profile.rest_url}`;

    console.log(
      `Komut Çalıştırılıyor...\nKomut: ${chalk.yellow(
        `${command} --private-key ...`
      )}`
    );

    const output = execSync(
      `${command} --private-key ${selected_profile.profile.private_key}`,
      { input: "yes", encoding: "utf8" }
    );

    console.log(output);
  } catch (error: any) {
    console.error("Publishlenirken bir hata oluştu:");
    if (error) if (error.stdout) console.error(error.stdout);
  }
}

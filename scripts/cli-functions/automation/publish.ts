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
    const file = fs.readFileSync(resolve(".movement/config.yaml"), "utf8");
    const doc = parseDocument(file);

    const json: CONFIG_YAML = doc.toJSON();

    let profiles = [];

    for (let name in json.profiles) {
      profiles.push({ name, profile: json.profiles[name] });
    }

    // Parse Move.toml

    const toml_string = fs.readFileSync(resolve("Move.toml"), "utf8");
    const data = toml.parse(toml_string);

    const modules = [];

    for (let name in data.addresses) {
      modules.push({
        name,
        address: data.addresses[name],
      });
    }

    // Starts...

    const [sdk, { module_name, selected_profile }] = await Promise.all([
      initSDK(),
      inquirer.prompt([
        {
          type: "rawlist",
          name: "selected_profile",
          message: "Select a profile to use:",
          choices: profiles.map((prf) => ({
            name: prf.name,
            value: prf,
          })),
        },
        {
          type: "rawlist",
          name: "module_name",
          message: "Choose module to publish:",
          choices: modules.map((module) => module.name),
        },
      ]),
    ]);
    await cli.showAccountInformation(sdk);

    const command = `movement move publish --named-address ${module_name}=${selected_profile.profile.account} --profile ${selected_profile.name}`;

    console.log(`Komut Çalıştırılıyor...\nKomut: ${chalk.yellow(command)}`);
    const output = await execSync(command);

    console.log(output.toString());
  } catch (error) {
    console.error("Publishlenirken bir hata oluştu:", error);
    throw error;
  }
}

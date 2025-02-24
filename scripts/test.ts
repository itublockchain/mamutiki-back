import toml from "toml";
import terminal from "./utils/console";

import fs from "fs";
import { resolve } from "path";

const toml_string = fs.readFileSync(resolve("Move.toml"), "utf8");
const data = toml.parse(toml_string);

for (let address_name in data.addresses) {
  terminal.log(address_name, data.addresses[address_name]);
}

import inquirer from "inquirer";
import terminal from "../utils/console";

export default async function help() {
  terminal.write("\nKullanılabilir komutlar:");
  terminal.write("1. Güvenilir anahtar ekleme:");
  terminal.write("   npm run add-trusted-key -- <publicKey>");

  terminal.write("\n2. Kampanya oluşturma (default değerlerle):");
  terminal.write("   npm run create-campaign");

  terminal.write("\n3. Kampanyaları listeleme:");
  terminal.write("   npm run list-campaigns");

  terminal.write("\n4. Katkı ekleme:");
  terminal.write("   npm run add-contribution -- <campaignId>");

  terminal.write("\n5. Katkıları listeleme:");
  terminal.write("   npm run list-contributions -- <campaignId>");

  terminal.write("\n6. Abonelik oluşturma:");
  terminal.write("   npm run subscribe");

  terminal.write("\n7. Abonelik fiyatı güncelleme:");
  terminal.write("   npm run update-price");

  terminal.write("\n8. Token mintleme:");
  terminal.write("   npm run mint-token -- <amount>");

  terminal.write("\n9. Token transferleme:");
  terminal.write("   npm run transfer-token -- <amount> <recipient>");

  terminal.write("\n10. Register:");
  terminal.write("   npm run register");

  terminal.write("\n11. Help:");
  terminal.write("   npm run help");

  await inquirer.prompt([
    {
      type: "input",
      name: "input",
      message: "Devam etmek için bir tuşa basın...",
    },
  ]);
}

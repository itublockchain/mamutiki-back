export default async function help() {
  console.log("\nKullanılabilir komutlar:");
  console.log("1. Güvenilir anahtar ekleme:");
  console.log("   npm run add-trusted-key -- <publicKey>");

  console.log("\n2. Kampanya oluşturma (default değerlerle):");
  console.log("   npm run create-campaign");

  console.log("\n3. Kampanyaları listeleme:");
  console.log("   npm run list-campaigns");

  console.log("\n4. Katkı ekleme:");
  console.log("   npm run add-contribution -- <campaignId>");

  console.log("\n5. Katkıları listeleme:");
  console.log("   npm run list-contributions -- <campaignId>");

  console.log("\n6. Abonelik oluşturma:");
  console.log("   npm run subscribe");

  console.log("\n7. Abonelik fiyatı güncelleme:");
  console.log("   npm run update-price");

  console.log("\n8. Token mintleme:");
  console.log("   npm run mint-token -- <amount>");

  console.log("\n9. Token transferleme:");
  console.log("   npm run transfer-token -- <amount> <recipient>");

  console.log("\n10. Register:");
  console.log("   npm run register");

  console.log("\n11. Help:");
  console.log("   npm run help");
}

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

  console.log("\n6. Token mintleme:");
  console.log("   npm run mint-token -- <amount>");

  console.log("\n7. Yardım:");
  console.log("   npm run help");
}

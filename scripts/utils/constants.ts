export const DEFAULT_VALUES = {
  campaign: {
    title: "Test Campaign",
    description: "Test Description",
    prompt: "Test Prompt",
    unitPrice: 0.01, // APT
    minContribution: 0, // APT
    minScore: 1,
    rewardPool: 0.1, // APT
    publicKeyForEncryption:
      "30820122300d06092a864886f70d01010105000382010f003082010a0282010100d62089b83d36864fc47d2dd1646944d5260cbc0067b35dae13b2e4eed7a3f461ff219259e60a09e7318c5395bfd2a24cc60326bf325bd19f938a472cef52cc3b10d25be1863bf1e1d477aecbc80697624e1f93e923b3ff58617c3bd500ef76b22214ea801f311459c1496c6e2e35a177a4082833444883013788374f43f1a1f379c5a150077d734618b001ad17e2626ac483c9a504045d81ce960797b2f61e47b919c75486978540d32d1e2113dac2fba1e6535e40cac36c63975399d852e6e445b51bac4c92bec27fe9003d195173c8fb01346a5c05ce9db38fdcb5082e8b621c10f75b2ce84976dac19d87bf11c9aa91c772c1831af736a3cc04e33ed1b7570203010001",
  },
  contribution: {
    dataCount: 1,
    storeCid: "test",
    score: 1,
    keyForDecryption: "test",
  },
  subscription: {
    price: 10, // APT
  },
};

export const ONE_MAMU = 1000000;

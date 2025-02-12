# Move Akıllı Kontrat API Dokümantasyonu

Bu dokümantasyon, Move akıllı kontratlarındaki public entry ve view fonksiyonlarını detaylı bir şekilde açıklamaktadır.

## İçindekiler
- [Campaign Manager](#campaign-manager)
- [Contribution Manager](#contribution-manager)
- [Escrow Manager](#escrow-manager)

## Campaign Manager

### Public Entry Fonksiyonları

#### `create_campaign`
Yeni bir kampanya oluşturur ve kampanya için gerekli ödül havuzunu escrow'a kilitler.

**Parametreler:**
- `account: &signer` - Kampanyayı oluşturan hesabın imzalayıcısı
- `title: vector<u8>` - Kampanya başlığı
- `description: vector<u8>` - Kampanya açıklaması
- `prompt: vector<u8>` - Veri toplama yönergesi
- `unit_price: u64` - Her bir veri katkısı için ödenecek ödül miktarı
- `minimum_contribution: u64` - Minimum katkı miktarı
- `reward_pool: u64` - Toplam ödül havuzu

### View Fonksiyonları

#### `get_campaign`
Belirli bir kampanyanın detaylarını döndürür.

**Parametreler:**
- `campaign_id: u64` - Kampanya ID'si

**Dönüş Değeri:**
```move
Campaign {
    id: u64,
    creator: address,
    title: vector<u8>,
    description: vector<u8>,
    prompt: vector<u8>,
    reward_pool: u64,
    remaining_reward: u64,
    unit_price: u64,
    minimum_contribution: u64,
    active: bool
}
```

#### `get_all_campaigns`
Sistemdeki tüm kampanyaları listeler.

**Dönüş Değeri:**
- `vector<Campaign>` - Tüm kampanyaların listesi

#### `get_unit_price`
Bir kampanyanın birim veri ödül miktarını döndürür.

**Parametreler:**
- `campaign_id: u64` - Kampanya ID'si

**Dönüş Değeri:**
- `u64` - Kampanyanın birim veri başına ödül miktarı

## Contribution Manager

### Public Entry Fonksiyonları

#### `add_contribution`
Bir kampanyaya veri katkısı ekler ve ödülü contributor'a transfer eder.

**Parametreler:**
- `account: &signer` - Katkıda bulunan hesabın imzalayıcısı
- `campaign_id: u64` - Kampanya ID'si
- `data_count: u64` - Katkıda bulunulan veri sayısı
- `store_cid: vector<u8>` - Verilerin IPFS CID'si
- `score: u64` - Katkının kalite skoru
- `signature: vector<u8>` - Katkının doğrulama imzası

### View Fonksiyonları

#### `get_all_contributions`
Tüm kampanyalardaki tüm katkıları listeler.

**Dönüş Değeri:**
```move
vector<Contribution> {
    campaign_id: u64,
    contributor: address,
    data_count: u64,
    store_cid: vector<u8>,
    score: u64,
    signature: vector<u8>
}
```

#### `get_campaign_contributions`
Belirli bir kampanyadaki tüm katkıları listeler.

**Parametreler:**
- `campaign_id: u64` - Kampanya ID'si

**Dönüş Değeri:**
- `vector<Contribution>` - Kampanyaya yapılan tüm katkıların listesi

#### `get_contributor_contributions`
Belirli bir kullanıcının tüm katkılarını listeler.

**Parametreler:**
- `contributor: address` - Katkıda bulunan kullanıcının adresi

**Dönüş Değeri:**
- `vector<Contribution>` - Kullanıcının tüm katkılarının listesi

## Escrow Manager

### Public Entry Fonksiyonları

#### `lock_funds`
Bir kampanya için ödül havuzunu kilitler.

**Parametreler:**
- `account: &signer` - Fonları kilitleyecek hesabın imzalayıcısı
- `campaign_id: u64` - Kampanya ID'si
- `amount: u64` - Kilitlenecek miktar
- `store_addr: address` - Escrow store'un adresi

#### `release_funds`
Kilitli fonları serbest bırakır.

**Parametreler:**
- `account: &signer` - Fonları serbest bırakacak hesabın imzalayıcısı
- `campaign_id: u64` - Kampanya ID'si
- `recipient: address` - Fonların gönderileceği adres
- `store_addr: address` - Escrow store'un adresi

### View Fonksiyonları

#### `get_locked_amount`
Bir kampanya için kilitli olan toplam miktarı döndürür.

**Parametreler:**
- `campaign_id: u64` - Kampanya ID'si
- `store_addr: address` - Escrow store'un adresi

**Dönüş Değeri:**
- `u64` - Kilitli miktar

## Önemli Notlar

1. Tüm para birimleri AptosCoin cinsindendir.
2. Veri doğrulama imzaları ED25519 algoritması kullanılarak oluşturulmalıdır.
3. Contribution eklerken verilen imza, aşağıdaki verilerin hash'i üzerinde oluşturulmalıdır:
   - campaign_id
   - data_count
   - store_cid
   - score

## Hata Kodları

- `ERR_NOT_ENOUGH_BALANCE: u64 = 1` - Yetersiz bakiye
- `ERR_ESCROW_NOT_FOUND: u64 = 2` - Escrow bulunamadı
- `ERR_UNAUTHORIZED: u64 = 3` - Yetkisiz işlem
- `ERR_INSUFFICIENT_FUNDS: u64 = 1` - Yetersiz fon 
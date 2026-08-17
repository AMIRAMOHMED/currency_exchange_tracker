enum SupportedCurrency {
  usd('USD', 'US Dollar'),
  eur('EUR', 'Euro'),
  gbp('GBP', 'British Pound'),
  sar('SAR', 'Saudi Riyal'),
  jpy('JPY', 'Japanese Yen');

  const SupportedCurrency(this.code, this.name);

  final String code;
  final String name;

  String get flagAsset => 'assets/flags/${code.toLowerCase()}.png';

  static SupportedCurrency? fromCode(String code) {
    final upper = code.toUpperCase();
    for (final currency in SupportedCurrency.values) {
      if (currency.code == upper) return currency;
    }
    return null;
  }
}

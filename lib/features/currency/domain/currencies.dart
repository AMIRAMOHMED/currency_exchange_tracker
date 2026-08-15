class CurrencyInfo {
  const CurrencyInfo({required this.code, required this.name});

  final String code;
  final String name;
}

const supportedCurrencies = [
  CurrencyInfo(code: 'USD', name: 'US Dollar'),
  CurrencyInfo(code: 'EUR', name: 'Euro'),
  CurrencyInfo(code: 'GBP', name: 'British Pound'),
  CurrencyInfo(code: 'SAR', name: 'Saudi Riyal'),
  CurrencyInfo(code: 'JPY', name: 'Japanese Yen'),
];

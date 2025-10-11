import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyInfo {
  final String code; // e.g., GHS, USD
  final String symbol; // e.g., GH₵, $
  final String locale; // e.g., en_GH, en_US
  final int decimalDigits; // e.g., 2 for USD, 0 for JPY

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
  });
}

/// Supported currencies (extendable)
const Map<String, CurrencyInfo> kSupportedCurrencies = {
  'GHS': CurrencyInfo(code: 'GHS', symbol: 'GH₵', locale: 'en_GH', decimalDigits: 2),
  'USD': CurrencyInfo(code: 'USD', symbol: '\$', locale: 'en_US', decimalDigits: 2),
  'EUR': CurrencyInfo(code: 'EUR', symbol: '€', locale: 'en_US', decimalDigits: 2),
  'GBP': CurrencyInfo(code: 'GBP', symbol: '£', locale: 'en_GB', decimalDigits: 2),
  'JPY': CurrencyInfo(code: 'JPY', symbol: '¥', locale: 'ja_JP', decimalDigits: 0),
  'IDR': CurrencyInfo(code: 'IDR', symbol: 'Rp', locale: 'id_ID', decimalDigits: 0),
  'NGN': CurrencyInfo(code: 'NGN', symbol: '₦', locale: 'en_NG', decimalDigits: 2),
  'AUD': CurrencyInfo(code: 'AUD', symbol: '\$', locale: 'en_AU', decimalDigits: 2),
  'CAD': CurrencyInfo(code: 'CAD', symbol: '\$', locale: 'en_CA', decimalDigits: 2),
};

class CurrencyNotifier extends StateNotifier<CurrencyInfo> {
  CurrencyNotifier() : super(kSupportedCurrencies['USD']!) {
    _loadCurrency();
  }

  static const String _currencyKey = 'currency_code';

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_currencyKey) ?? 'USD';
      state = kSupportedCurrencies[code] ?? kSupportedCurrencies['USD']!;
    } catch (_) {
      state = kSupportedCurrencies['USD']!;
    }
  }

  Future<void> _saveCurrency(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, code);
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<void> setCurrency(String code) async {
    if (!kSupportedCurrencies.containsKey(code)) return;
    state = kSupportedCurrencies[code]!;
    await _saveCurrency(code);
  }

  /// Format amounts using intl NumberFormat with current settings
  String format(num? amount, {int? overrideDecimalDigits}) {
    final dec = overrideDecimalDigits ?? state.decimalDigits;
    final formatter = NumberFormat.currency(
      locale: state.locale,
      symbol: state.symbol,
      decimalDigits: dec,
    );
    final value = (amount ?? 0).toDouble();
    return formatter.format(value);
  }
}

/// Riverpod provider for currency settings
final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyInfo>((ref) {
  return CurrencyNotifier();
});
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit(this._prefs) : super(LocaleState(_read(_prefs))) ;

  static const _key = 'app_locale';
  final SharedPreferences _prefs;

  static Locale _read(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    if (code == 'en') return const Locale('en');
    return const Locale('ar');
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_key, locale.languageCode);
    emit(LocaleState(locale));
  }

  Future<void> toggle() async {
    final next = state.locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }
}

class LocaleState extends Equatable {
  const LocaleState(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  @override
  List<Object?> get props => [locale];
}

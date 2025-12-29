import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'countries.dart';
import 'languages/en.dart';
import 'languages/es.dart';
import 'languages/fr.dart';
import 'languages/pt.dart';
import 'languages/ru.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': enTranslations,
    'es': esTranslations,
    'fr': frTranslations,
    'pt': ptTranslations,
    'ru': ruTranslations,
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static Widget buildLanguageDropdown(BuildContext context, Locale currentLocale, void Function(Locale?) onChanged) {
    final localizations = AppLocalizations.of(context)!;

    final Map<String, String> languageMap = {
      'en': localizations.translate('english'),
      'es': localizations.translate('spanish'),
      'fr': localizations.translate('french'),
      'pt': localizations.translate('portuguese'),
      'ru': localizations.translate('russian'),
    };
    return InkWell(
      onTap: () => _showLanguageSearchDialog(context, currentLocale, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(languageMap[currentLocale.languageCode] ?? currentLocale.languageCode),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  static void _showLanguageSearchDialog(BuildContext context, Locale currentLocale, void Function(Locale?) onChanged) {
    String searchQuery = '';
    final Map<String, String> languageMap = {
      'en': AppLocalizations.of(context)!.translate('english'),
      'es': AppLocalizations.of(context)!.translate('spanish'),
      'fr': AppLocalizations.of(context)!.translate('french'),
      'pt': AppLocalizations.of(context)!.translate('portuguese'),
      'ru': AppLocalizations.of(context)!.translate('russian'),
    };
    final languages = const [
      Locale('en', ''),
      Locale('es', ''),
      Locale('fr', ''),
      Locale('pt', ''),
      Locale('ru', ''),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredLanguages = languages.where((locale) => languageMap[locale.languageCode]!.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: const Text('Select Language'),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(hintText: 'Search languages'),
                    ),
                    Expanded(
                      child: ListView(
                        children: filteredLanguages.map((locale) {
                          return ListTile(
                            title: Text(languageMap[locale.languageCode]!),
                            selected: locale.languageCode == currentLocale.languageCode,
                            onTap: () {
                              onChanged(locale);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget buildCountryDropdown(BuildContext context, String currentCountry, void Function(String?) onChanged) {
    return InkWell(
      onTap: () => _showCountrySearchDialog(context, currentCountry, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(countries[currentCountry] ?? currentCountry),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  static void _showCountrySearchDialog(BuildContext context, String currentCountry, void Function(String?) onChanged) {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredCountries = countries.entries.where((entry) => entry.value.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: const Text('Select Country'),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(hintText: 'Search countries'),
                    ),
                    Expanded(
                      child: ListView(
                        children: filteredCountries.map((entry) {
                          return ListTile(
                            title: Text(entry.value),
                            selected: entry.key == currentCountry,
                            onTap: () {
                              onChanged(entry.key);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'pt', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
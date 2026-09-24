import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common_widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t('settingsFavorites'))),
      body: EmptyState(
        icon: Icons.star_outline_rounded,
        title: t('favoritesEmptyTitle'),
        message: t('favoritesEmptyMessage'),
      ),
    );
  }
}

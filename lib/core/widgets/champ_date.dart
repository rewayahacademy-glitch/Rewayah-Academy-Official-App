import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../theme/app_radius.dart';
import 'pressable.dart';

/// L'heure que les formulaires lisent pour borner une date a venir.
///
/// Un provider plutot qu'un `DateTime.now()` en dur : un test pose l'horloge,
/// et les bornes du calendrier ne bougent plus avec le jour ou l'on le lance.
final Provider<DateTime Function()> horlogeFormulairesProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// Un champ date a choisir dans un calendrier, jamais a taper (FORM-L4).
///
/// Taper `JJ/MM/AAAA` sur un telephone est la saisie qui se trompe : un jour
/// 31 en novembre, un mois a l'envers. Le calendrier ne propose que des jours
/// qui existent, de [aujourdhui] a un an plus tard. La langue du calendrier est
/// celle de l'application (`fr`).
class ChampDate extends StatelessWidget {
  /// Cree le champ.
  const ChampDate({
    required this.libelle,
    required this.valeur,
    required this.onChoix,
    required this.aujourdhui,
    super.key,
    this.dernier,
    this.aide,
  });

  /// Le nom du champ.
  final String libelle;

  /// Le jour choisi, ou `null` tant que rien n'est choisi.
  final DateTime? valeur;

  /// Appele avec le jour choisi (a minuit, sans heure).
  final ValueChanged<DateTime> onChoix;

  /// Le jour d'aujourd'hui : la premiere date permise.
  final DateTime aujourdhui;

  /// La derniere date permise, quand ce n'est pas « dans un an » : un jour
  /// passe a choisir (le jour d'une demande recue) borne le calendrier a
  /// aujourd'hui. Nul : dans un an.
  final DateTime? dernier;

  /// La phrase sous le champ, quand elle n'est pas « Entre aujourd'hui et dans
  /// un an. » : elle dit alors l'etendue reelle du calendrier.
  final String? aide;

  /// La premiere date permise : aujourd'hui, a minuit.
  DateTime get premierJour =>
      DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);

  /// La derniere date permise : [dernier], sinon dans un an.
  DateTime get dernierJour {
    final DateTime? d = dernier;
    return d != null
        ? DateTime(d.year, d.month, d.day)
        : DateTime(premierJour.year + 1, premierJour.month, premierJour.day);
  }

  /// Ecrit un jour `JJ/MM/AAAA`, pour l'afficher.
  static String ecrire(DateTime jour) =>
      '${jour.day.toString().padLeft(2, '0')}/'
      '${jour.month.toString().padLeft(2, '0')}/${jour.year}';

  Future<void> _ouvrir(BuildContext context) async {
    final DateTime? actuel = valeur;
    final DateTime depart =
        actuel == null ||
            actuel.isBefore(premierJour) ||
            actuel.isAfter(dernierJour)
        ? premierJour
        : actuel;
    final DateTime? choisie = await showDatePicker(
      context: context,
      initialDate: depart,
      firstDate: premierJour,
      lastDate: dernierJour,
      helpText: libelle,
      // Le calendrier de Material a des cellules et un en-tete de taille
      // fixe : a 320 de large, des 150 % le jour 20 passe sur deux lignes et
      // « dim. 4 octobre » est tronque (mesure FORM-CORR-1). On plafonne donc
      // le texte du seul calendrier a 100 % sous 360 de large et a 150 %
      // au-dela ; le champ, lui, suit le reglage en entier.
      builder: (BuildContext contexte, Widget? dialogue) => MediaQuery(
        data: MediaQuery.of(contexte).copyWith(
          textScaler: MediaQuery.textScalerOf(contexte).clamp(
            maxScaleFactor: MediaQuery.sizeOf(contexte).width < 360 ? 1.0 : 1.5,
          ),
        ),
        child: dialogue ?? const SizedBox.shrink(),
      ),
    );
    if (choisie != null) {
      onChoix(DateTime(choisie.year, choisie.month, choisie.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? jour = valeur;
    return Pressable(
      key: const ValueKey<String>('champ-date'),
      onPress: () => _ouvrir(context),
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiSm,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: libelle,
          helperText: aide ?? t.commun.champDate.aide,
          helperMaxLines: 3,
        ),
        child: Text(
          jour == null ? t.commun.champDate.choisir : ecrire(jour),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

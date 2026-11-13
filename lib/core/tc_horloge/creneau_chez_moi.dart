// HORLOGE-ET-LIEU, correction de la partie A (13/11/2026, B1) : l'heure d'un
// creneau hebdomadaire de classe, pour une personne.
//
// Tout creneau est enregistre a l'heure de La Mecque (ou, tant que la classe
// n'est pas convertie, dans le fuseau de la classe). Une personne ne lit JAMAIS
// cette heure brute, ni seule : son heure locale d'abord, calculee depuis
// l'instant reel du prochain cours, puis « Heure de La Mecque » en second.
// Jamais « Riyad », jamais « heure de la classe ».
//
// Le client n'a aucune base de fuseaux : le decalage et les changements d'heure
// du fuseau du creneau viennent du serveur (`public.fuseau_vue`). Sans cette
// lecture (serveur pas encore a jour, hors ligne), l'heure du creneau est dite
// avec la ville de son fuseau (« mercredi 19:00 (heure de Paris) ») : vraie, jamais
// une heure locale devinee.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../i18n/strings.g.dart';
import '../i18n/villes_fuseau.dart';
import 'fuseaux_interlocuteurs.dart';
import 'mon_horloge.dart';

/// Un creneau hebdomadaire lu par la personne.
@immutable
class CreneauChezMoi {
  /// Cree le creneau.
  const CreneauChezMoi({
    required this.jour,
    required this.heure,
    this.mecque,
    this.heureCreneau,
  });

  /// Le jour (1 lundi a 7 dimanche) du prochain cours chez la personne.
  final int jour;

  /// « 19:00 », chez la personne.
  final String heure;

  /// « 21:00 », a l'heure de La Mecque ; `null` quand c'est la meme heure que
  /// chez la personne, ou quand l'horloge de La Mecque n'est pas lue.
  final String? mecque;

  /// L'heure du creneau dans son propre fuseau, `null` quand la lecture du
  /// fuseau a reussi (inutile alors).
  final String? heureCreneau;

  @override
  bool operator ==(Object other) =>
      other is CreneauChezMoi &&
      other.jour == jour &&
      other.heure == heure &&
      other.mecque == mecque;

  @override
  int get hashCode => Object.hash(jour, heure, mecque);
}

/// L'instant (UTC) du prochain cours d'un creneau : jour ISO [jour], heure pleine
/// [heure] dans [fuseauCreneau]. `null` quand un changement d'heure rend le
/// decalage incertain.
DateTime? prochainCoursUtc({
  required int jour,
  required int heure,
  required FuseauVu fuseauCreneau,
  required DateTime maintenant,
}) {
  final DateTime utc = maintenant.toUtc();
  final DateTime? locale = fuseauCreneau.muraleA(utc);
  if (locale == null) return null;
  // Le premier jour, des aujourd'hui (a l'heure du fuseau du creneau), qui porte
  // ce jour de semaine et dont l'instant est a venir.
  for (int d = 0; d <= 7; d++) {
    final DateTime jourLocal = DateTime.utc(
      locale.year,
      locale.month,
      locale.day + d,
    );
    if (jourLocal.weekday != jour) continue;
    final DateTime murale = DateTime.utc(
      jourLocal.year,
      jourLocal.month,
      jourLocal.day,
      heure,
    );
    final Duration? premier = fuseauCreneau.decalageA(
      murale.subtract(fuseauCreneau.decalage),
    );
    if (premier == null) return null;
    DateTime instant = murale.subtract(premier);
    final Duration? second = fuseauCreneau.decalageA(instant);
    if (second == null) return null;
    if (second != premier) instant = murale.subtract(second);
    if (!instant.isAfter(utc)) continue;
    return instant;
  }
  return null;
}

/// Le prochain cours d'un creneau, lu a l'heure de la personne et a celle de La
/// Mecque. `null` quand un changement d'heure rend le decalage incertain.
CreneauChezMoi? creneauChezMoi({
  required int jour,
  required int heure,
  required FuseauVu fuseauCreneau,
  required DateTime maintenant,
}) {
  final DateTime? instant = prochainCoursUtc(
    jour: jour,
    heure: heure,
    fuseauCreneau: fuseauCreneau,
    maintenant: maintenant,
  );
  if (instant == null) return null;
  final DateTime chez = chezMoi(instant);
  return CreneauChezMoi(
    jour: chez.weekday,
    heure: _hhmm(chez),
    mecque: heureMecqueSiDifferente(instant),
  );
}

/// Le jour et l'heure du prochain cours d'un creneau lus dans un AUTRE fuseau
/// ([vers]) : pour comparer une heure saisie dans un fuseau a l'horaire d'une
/// classe enregistre dans un autre. `null` quand l'heure n'est pas entiere
/// ou pas sure.
({int jour, int heure})? creneauDansFuseau({
  required int jour,
  required int heure,
  required FuseauVu origine,
  required FuseauVu vers,
  required DateTime maintenant,
}) {
  final DateTime? instant = prochainCoursUtc(
    jour: jour,
    heure: heure,
    fuseauCreneau: origine,
    maintenant: maintenant,
  );
  if (instant == null) return null;
  final DateTime? murale = vers.muraleA(instant);
  if (murale == null || murale.minute != 0) return null;
  return (jour: murale.weekday, heure: murale.hour);
}

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// « Mercredi 19:00 · Heure de La Mecque : 21:00 » (jour en minuscule quand
/// [capitale] est faux).
String libelleCreneauChezMoi(CreneauChezMoi c, {bool capitale = false}) {
  final String nom = t.disponibilites.joursLongs[c.jour - 1];
  final String jour = capitale
      ? nom
      : nom.replaceRange(0, 1, nom.substring(0, 1).toLowerCase());
  final String base = '$jour ${c.heure}';
  final String? mecque = c.mecque;
  return mecque == null
      ? base
      : '$base · ${t.tc.groupe.horloges.mecqueEnSecond(heure: mecque)}';
}

/// Le jour et l'heure d'un creneau, a mettre dans une phrase (« {jour} a {heure} »).
/// Avec la lecture : le jour et l'heure chez la personne, puis « Heure de La
/// Mecque » en second. Sans elle : l'heure du creneau et la ville de son fuseau.
({String jour, String heure}) partiesDuCreneau(
  CreneauChezMoi? lu,
  CleCreneau c,
) {
  if (lu == null) {
    return (
      jour: t.disponibilites.joursLongs[c.jour - 1],
      heure: t.tc.groupe.horloges.heureDeVille(
        heure: '${c.heure.toString().padLeft(2, '0')}:00',
        ville: villeDuFuseauLibelle(c.fuseau),
      ),
    );
  }
  final String? mecque = lu.mecque;
  return (
    jour: t.disponibilites.joursLongs[lu.jour - 1],
    heure: mecque == null
        ? lu.heure
        : '${lu.heure} \u00b7 ${t.tc.groupe.horloges.mecqueEnSecond(heure: mecque)}',
  );
}

/// L'acces a `public.fuseau_vue`.
abstract interface class PortFuseauVu {
  /// Le decalage et les changements d'heure de [fuseau], ou `null` quand le
  /// serveur ne sait pas repondre.
  Future<FuseauVu?> lire(String fuseau);
}

/// Sans serveur (PLAYGROUND, test) : aucune reponse.
class FuseauVuAbsent implements PortFuseauVu {
  /// Cree le port vide.
  const FuseauVuAbsent();

  @override
  Future<FuseauVu?> lire(String fuseau) async => null;
}

/// L'adaptateur de `public.fuseau_vue`.
class FuseauVuSupabase implements PortFuseauVu {
  /// Cree l'adaptateur.
  const FuseauVuSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<FuseauVu?> lire(String fuseau) async {
    try {
      return FuseauVu.lire(
        await _client.rpc<Object?>(
          'fuseau_vue',
          params: <String, dynamic>{'p_fuseau': fuseau},
        ),
      );
    } on PostgrestException catch (e) {
      // 42501 : compte non valide ; 22023 : fuseau inconnu ; PGRST202 et
      // 42883 : la fonction n'est pas encore installee.
      if (e.code == '42501' ||
          e.code == '22023' ||
          e.code == 'PGRST202' ||
          e.code == '42883') {
        return null;
      }
      rethrow;
    }
  }
}

/// Le port employe par l'application.
final Provider<PortFuseauVu> portFuseauVuProvider = Provider<PortFuseauVu>((
  Ref ref,
) {
  if (Env.playgroundActif) return const FuseauVuAbsent();
  try {
    return FuseauVuSupabase(Supabase.instance.client);
  } on Object {
    return const FuseauVuAbsent();
  }
});

/// Le fuseau d'un creneau, lu une fois par fuseau.
final FutureProviderFamily<FuseauVu?, String> fuseauVuProvider =
    FutureProvider.family<FuseauVu?, String>(
      (Ref ref, String fuseau) => ref.watch(portFuseauVuProvider).lire(fuseau),
      retry: (int _, Object _) => null,
    );

/// La cle d'un creneau : son jour, son heure et son fuseau d'origine.
typedef CleCreneau = ({int jour, int heure, String fuseau});

/// Le creneau lu par la personne, `null` tant que le fuseau n'est pas lu ou
/// quand il ne peut pas l'etre.
final FutureProviderFamily<CreneauChezMoi?, CleCreneau>
creneauChezMoiProvider = FutureProvider.family<CreneauChezMoi?, CleCreneau>((
  Ref ref,
  CleCreneau c,
) async {
  // L'horloge de la personne et celle de La Mecque d'abord : sans elles, aucune
  // heure locale n'est posee.
  try {
    await ref.watch(monHorlogeProvider.future);
  } on Object {
    // Lecture en echec : l'heure de l'appareil, dite comme telle ailleurs.
  }
  final FuseauVu? f = await ref.watch(fuseauVuProvider(c.fuseau).future);
  if (f == null) return null;
  return creneauChezMoi(
    jour: c.jour,
    heure: c.heure,
    fuseauCreneau: f,
    maintenant: DateTime.now(),
  );
}, retry: (int _, Object _) => null);

/// Le libelle du creneau pour l'ecran, sur une ligne : « Mercredi 19:00 · Heure
/// de La Mecque : 21:00 », ou, sans lecture du fuseau, « Mercredi 19:00 (heure de
/// Paris) ».
String libelleDuCreneau(
  CreneauChezMoi? lu,
  CleCreneau c, {
  bool capitale = true,
}) {
  final ({String jour, String heure}) p = partiesDuCreneau(lu, c);
  final String jour = capitale
      ? p.jour
      : p.jour.replaceRange(0, 1, p.jour.substring(0, 1).toLowerCase());
  return '$jour ${p.heure}';
}

/// Les fuseaux d'un ensemble de creneaux, lus pour la personne : a appeler dans
/// `build`. L'horloge de la personne est surveillee aussi, pour que l'ecran se
/// redessine quand elle arrive.
Map<String, FuseauVu?> fuseauxDesCreneaux(
  WidgetRef ref,
  Iterable<String> fuseaux,
) {
  ref.watch(monHorlogeProvider);
  return <String, FuseauVu?>{
    for (final String f in fuseaux.toSet())
      f: ref.watch(fuseauVuProvider(f)).value,
  };
}

/// Le creneau [c] lu a partir de fuseaux deja lus ([fuseauxDesCreneaux]).
CreneauChezMoi? creneauLu(Map<String, FuseauVu?> fuseaux, CleCreneau c) {
  final FuseauVu? f = fuseaux[c.fuseau];
  return f == null
      ? null
      : creneauChezMoi(
          jour: c.jour,
          heure: c.heure,
          fuseauCreneau: f,
          maintenant: DateTime.now(),
        );
}

/// Le libelle du creneau [c] lu a partir de fuseaux deja lus.
String libelleCreneauLu(
  Map<String, FuseauVu?> fuseaux,
  CleCreneau c, {
  bool capitale = true,
}) => libelleDuCreneau(creneauLu(fuseaux, c), c, capitale: capitale);

// HORLOGE-ET-LIEU (12/11/2026, H1 et H3) : l'apercu d'un creneau pour l'ecran.
//
// Tout creneau de classe est enregistre a l'heure de La Mecque. Quand la
// direction choisit un creneau a l'heure de l'enseignant, l'ecran dit a quelle
// heure de La Mecque il sera enregistre, et ce que devient l'heure de
// l'enseignant au prochain changement d'heure de son pays (« 19:00, puis 20:00
// a partir du dimanche 28 mars »). Le calcul est fait par la base
// (`public.apercu_creneau_academie`) : le client n'a aucune regle IANA.
//
// Sans reponse du serveur (fonction pas encore installee, test sans Supabase),
// aucune phrase : jamais une heure fabriquee.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/suivi_foyer/filtres_historique.dart'
    show dateLongueHistorique;
import '../accessibilite/texte_sans_coupure.dart';
import '../config/env.dart';
import '../i18n/strings.g.dart';
import '../i18n/villes_fuseau.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'mon_horloge.dart';

/// La reponse de `public.apercu_creneau_academie` : l'heure locale d'un
/// creneau aujourd'hui, et apres le prochain changement d'heure du fuseau.
@immutable
class ApercuCreneau {
  /// Cree l'apercu.
  const ApercuCreneau({
    required this.jourMaintenant,
    required this.heureMaintenant,
    required this.meme,
    this.dateChangement,
    this.jourApres,
    this.heureApres,
  });

  /// Lit la reponse, ou `null` quand elle ne se lit pas.
  static ApercuCreneau? lire(Object? brut) {
    if (brut is! Map) return null;
    final Object? jour = brut['jour_maintenant'];
    final Object? heure = brut['maintenant'];
    final Object? meme = brut['meme'];
    if (jour is! int || jour < 1 || jour > 7) return null;
    if (heure is! String || meme is! bool) return null;
    final Object? date = brut['date_changement'];
    final Object? jourApres = brut['jour_apres'];
    final Object? heureApres = brut['heure_apres'];
    return ApercuCreneau(
      jourMaintenant: jour,
      heureMaintenant: heure,
      meme: meme,
      dateChangement: date is String ? DateTime.tryParse(date) : null,
      jourApres: jourApres is int ? jourApres : null,
      heureApres: heureApres is String ? heureApres : null,
    );
  }

  /// Le jour (1 lundi a 7 dimanche) et l'heure du creneau chez la personne
  /// aujourd'hui.
  final int jourMaintenant;

  /// « 19:00 ».
  final String heureMaintenant;

  /// Vrai quand l'heure locale ne change jamais dans l'annee.
  final bool meme;

  /// Le jour du prochain changement d'heure, quand l'heure locale change.
  final DateTime? dateChangement;

  /// Le jour (1 a 7) du creneau apres ce changement.
  final int? jourApres;

  /// L'heure du creneau apres ce changement.
  final String? heureApres;
}

/// L'acces au calcul de la base.
abstract interface class PortApercuCreneau {
  /// L'heure locale, chez [fuseau], du creneau [jour] / [heure], defini a
  /// l'heure de l'academie, ou de [fuseauCreneau] quand il est donne. `null`
  /// quand le serveur ne sait pas repondre.
  Future<ApercuCreneau?> lire({
    required String fuseau,
    required int jour,
    required int heure,
    String? fuseauCreneau,
  });
}

/// Sans serveur (PLAYGROUND, test) : aucune reponse.
class ApercuCreneauAbsent implements PortApercuCreneau {
  /// Cree le port vide.
  const ApercuCreneauAbsent();

  @override
  Future<ApercuCreneau?> lire({
    required String fuseau,
    required int jour,
    required int heure,
    String? fuseauCreneau,
  }) async => null;
}

/// L'adaptateur de `public.apercu_creneau_academie`.
class ApercuCreneauSupabase implements PortApercuCreneau {
  /// Cree l'adaptateur.
  const ApercuCreneauSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ApercuCreneau?> lire({
    required String fuseau,
    required int jour,
    required int heure,
    String? fuseauCreneau,
  }) async {
    try {
      final Object? brut = await _client.rpc<Object?>(
        'apercu_creneau_academie',
        params: <String, dynamic>{
          'p_fuseau': fuseau,
          'p_weekday': jour,
          'p_heure': heure,
          'p_fuseau_creneau': ?fuseauCreneau,
        },
      );
      return ApercuCreneau.lire(brut);
    } on PostgrestException catch (e) {
      // 42501 : compte non valide ; 22023 : fuseau inconnu ; PGRST202 et
      // 42883 : la fonction n'est pas encore installee. Pas d'apercu.
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
final Provider<PortApercuCreneau> portApercuCreneauProvider =
    Provider<PortApercuCreneau>((Ref ref) {
      if (Env.playgroundActif) return const ApercuCreneauAbsent();
      try {
        return ApercuCreneauSupabase(Supabase.instance.client);
      } on Object {
        return const ApercuCreneauAbsent();
      }
    });

/// Ce que la direction lit pour un creneau choisi a l'heure d'un enseignant.
@immutable
class ResumeCreneauEnseignant {
  /// Cree le resume.
  const ResumeCreneauEnseignant({
    required this.jourAcademie,
    required this.heureAcademie,
    required this.chezEnseignant,
  });

  /// Le jour (1 a 7) du creneau a l'heure de La Mecque.
  final int jourAcademie;

  /// « 21:00 ».
  final String heureAcademie;

  /// L'heure chez l'enseignant avant et apres son prochain changement d'heure.
  final ApercuCreneau chezEnseignant;
}

/// La demande d'un resume : le fuseau de l'enseignant et le creneau choisi a
/// son heure.
typedef DemandeResume = ({String fuseauEnseignant, int jour, int heure});

/// Deux lectures : le creneau de l'enseignant converti a l'heure de La
/// Mecque, puis ce creneau-la revu chez l'enseignant (avant et apres son
/// prochain changement d'heure).
final FutureProviderFamily<ResumeCreneauEnseignant?, DemandeResume>
resumeCreneauEnseignantProvider =
    FutureProvider.family<ResumeCreneauEnseignant?, DemandeResume>((
      Ref ref,
      DemandeResume d,
    ) async {
      final PortApercuCreneau port = ref.watch(portApercuCreneauProvider);
      final String academie = horlogeAcademie?.fuseau ?? fuseauAcademieDefaut;
      final ApercuCreneau? enregistre = await port.lire(
        fuseau: academie,
        jour: d.jour,
        heure: d.heure,
        fuseauCreneau: d.fuseauEnseignant,
      );
      if (enregistre == null) return null;
      final int? heureAcademie = int.tryParse(
        enregistre.heureMaintenant.split(':').first,
      );
      if (heureAcademie == null) return null;
      final ApercuCreneau? chez = await port.lire(
        fuseau: d.fuseauEnseignant,
        jour: enregistre.jourMaintenant,
        heure: heureAcademie,
      );
      if (chez == null) return null;
      return ResumeCreneauEnseignant(
        jourAcademie: enregistre.jourMaintenant,
        heureAcademie: enregistre.heureMaintenant,
        chezEnseignant: chez,
      );
    }, retry: (int _, Object _) => null);

/// Le fuseau de l'academie quand le serveur ne l'a pas encore dit : la valeur
/// decidee le 12/11/2026 (La Mecque).
const String fuseauAcademieDefaut = 'Asia/Riyadh';

/// « Enregistree a l'heure de La Mecque : mercredi 21:00. Chez l'enseignant
/// (Paris) : 19:00, puis 20:00 a partir du dimanche 28 mars 2027. »
String phraseResumeCreneau(ResumeCreneauEnseignant r, String fuseauEnseignant) {
  final h = t.tc.groupe.horloges;
  final String enregistre = h.apercuClasse(
    jour: t.commun.dates.jours[r.jourAcademie - 1].toLowerCase(),
    heure: r.heureAcademie,
  );
  final String ou = h.apercuOuEnseignant(
    ville: villeDuFuseauLibelle(fuseauEnseignant),
  );
  final ApercuCreneau c = r.chezEnseignant;
  final DateTime? date = c.dateChangement;
  final String? apres = c.heureApres;
  final String chez = c.meme || date == null || apres == null
      ? h.apercuChez(ou: ou, heure: c.heureMaintenant)
      : h.apercuChezPuis(
          ou: ou,
          heure: c.heureMaintenant,
          apres: apres,
          date: dateLongueHistorique(date),
        );
  return '$enregistre $chez';
}

/// La phrase d'apercu d'un creneau choisi a l'heure d'un enseignant, sous le
/// choix du creneau. Rien tant que le serveur ne repond pas, et rien quand
/// l'enseignant vit deja a l'heure de La Mecque.
class LigneApercuClasse extends ConsumerWidget {
  /// Cree la ligne.
  const LigneApercuClasse({
    required this.fuseauEnseignant,
    required this.jour,
    required this.heure,
    super.key,
  });

  /// Le fuseau de l'enseignant, dans lequel le creneau est choisi.
  final String fuseauEnseignant;

  /// Le jour (1 a 7) choisi.
  final int jour;

  /// L'heure choisie, a l'heure de l'enseignant.
  final int heure;

  /// Cle de la ligne.
  static const Key cle = ValueKey<String>('apercu-classe');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String academie = horlogeAcademie?.fuseau ?? fuseauAcademieDefaut;
    if (fuseauEnseignant == academie) return const SizedBox.shrink();
    final ResumeCreneauEnseignant? r = ref
        .watch(
          resumeCreneauEnseignantProvider((
            fuseauEnseignant: fuseauEnseignant,
            jour: jour,
            heure: heure,
          )),
        )
        .value;
    if (r == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: TexteSansCoupure(
        key: cle,
        phraseResumeCreneau(r, fuseauEnseignant),
        style: AppTypography.tabulaire(
          Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// L'equivalent a La Mecque d'une heure saisie dans [fuseauSaisie] : « A l'heure
/// de La Mecque, la classe aura lieu le mercredi a 21:00. », montre AVANT
/// d'envoyer (HORLOGE-ET-LIEU, correction B2). Rien quand l'heure est deja saisie
/// a l'heure de La Mecque, ou quand le serveur ne repond pas.
class LigneEquivalentMecque extends ConsumerWidget {
  /// Cree la ligne.
  const LigneEquivalentMecque({
    required this.fuseauSaisie,
    required this.jour,
    required this.heure,
    super.key,
  });

  /// Le fuseau dans lequel l'heure est saisie.
  final String fuseauSaisie;

  /// Le jour (1 a 7) saisi, ou `null` tant qu'il n'est pas choisi.
  final int? jour;

  /// L'heure saisie, ou `null` tant qu'elle n'est pas choisie.
  final int? heure;

  /// Cle de la ligne.
  static const Key cle = ValueKey<String>('equivalent-mecque');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String academie = horlogeAcademie?.fuseau ?? fuseauAcademieDefaut;
    final int? j = jour;
    final int? h = heure;
    if (fuseauSaisie == academie || j == null || h == null) {
      return const SizedBox.shrink();
    }
    final ResumeCreneauEnseignant? lu = ref
        .watch(
          resumeCreneauEnseignantProvider((
            fuseauEnseignant: fuseauSaisie,
            jour: j,
            heure: h,
          )),
        )
        .value;
    if (lu == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: TexteSansCoupure(
        key: cle,
        t.tc.groupe.horloges.apercuClasse(
          jour: t.commun.dates.jours[lu.jourAcademie - 1].toLowerCase(),
          heure: lu.heureAcademie,
        ),
        style: AppTypography.tabulaire(
          Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        ),
      ),
    );
  }
}

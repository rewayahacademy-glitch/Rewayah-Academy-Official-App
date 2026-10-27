// La deconnexion (fiche du 27/10/2026, lignes 16 a 18, arbitrages du pilote
// du 27/10) : les cahiers de transmission encore en file ont une derniere
// chance de partir (envoi borne) ; s'il en reste, la personne choisit de les
// perdre ou d'annuler ; puis la session locale est fermee d'abord, le serveur
// prevenu ensuite au mieux sans bloquer ; les donnees de la personne sont
// retirees de la base locale, les reglages de l'appareil restent ; la memoire
// de l'application repart de zero.

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appairage/profils_locaux.dart' show baseLocaleProvider;
import '../auth/service_auth.dart';
import '../cache/db/app_database.dart';
import '../cache/sync/file_rapports.dart';
import '../domain/enums.dart';
import '../enseignant/depot_cahiers.dart';
import '../i18n/strings.g.dart';
import '../observabilite/journal_dev.dart';
import '../theme/app_delais.dart';
import '../widgets/confirm_destructive.dart';
import 'session_controleur.dart';

/// Remet toute la memoire de l'application a zero : la racine renouvelle sa
/// `ProviderScope`, et chaque provider se reconstruit a sa prochaine lecture.
/// Par defaut rien : c'est la racine reelle (`RacineDemonstrable`) qui le
/// fournit ; un ecran teste seul, la galerie ou une session d'observation
/// n'ont rien a renouveler.
final Provider<void Function()> remiseAZeroProvider = Provider<void Function()>(
  (Ref ref) => () {},
);

/// Vide les tables de la personne dans la base locale, en une transaction :
/// profils du foyer, seances a venir, ressources hors ligne, rapports en
/// attente. `PreferenceLocale` (theme, repli de navigation, raccourcis) est
/// un reglage de l'appareil, pas une donnee de la personne : elle reste
/// (arbitrage du pilote, 27/10/2026).
Future<void> viderTablesDeLaPersonne(AppDatabase base) =>
    base.transaction(() async {
      final String reglages = base.preferenceLocale.actualTableName;
      for (final TableInfo<Table, dynamic> table in base.allTables) {
        if (table.actualTableName == reglages) continue;
        await base.delete(table).go();
      }
    });

/// Ce que « Se deconnecter » fait, dans l'ordre.
class Deconnexion {
  /// Cree la deconnexion.
  const Deconnexion({
    required this.auth,
    required this.rapportsRestants,
    required this.viderAppareil,
    required this.remiseAZero,
  });

  /// Ferme la session locale ; le serveur est prevenu au mieux, sans que
  /// l'appel ne l'attende.
  final ServiceAuth auth;

  /// Tente d'envoyer les cahiers encore en file, dans la limite de
  /// [AppDelais.envoiAvantDeconnexion], puis rend le nombre de ceux qui
  /// restent. Sans cahier en file, rien n'est tente.
  final Future<int> Function() rapportsRestants;

  /// Retire les donnees de la personne de la base locale.
  final Future<void> Function() viderAppareil;

  /// Remet la memoire de l'application a zero.
  final void Function() remiseAZero;

  /// Execute la deconnexion. Rend `false` quand la personne l'a annulee pour
  /// ne pas perdre ses cahiers ; `true` quand elle est sortie.
  ///
  /// [confirmerPerte] est demande avec le nombre de cahiers qui n'ont pas pu
  /// partir ; `false` annule tout, rien n'est touche.
  ///
  /// La fermeture de la session locale est la seule etape qui peut faire
  /// echouer la sortie : si elle leve, rien d'autre n'est fait et l'erreur
  /// remonte a l'ecran, qui la dit (K-59) ; la personne est encore connectee.
  /// Une base locale qui ne se vide pas est journalisee et la sortie aboutit
  /// quand meme : la personne est deja sortie, la memoire repart de zero.
  Future<bool> executer({
    required Future<bool> Function(int restants) confirmerPerte,
  }) async {
    final int restants = await rapportsRestants();
    if (restants > 0 && !await confirmerPerte(restants)) {
      return false;
    }
    await auth.deconnexion();
    try {
      await viderAppareil();
    } on Object catch (erreur) {
      journalDev('Deconnexion : base locale non videe, ${erreur.runtimeType}');
    }
    remiseAZero();
    return true;
  }
}

/// Les cahiers en file ont une derniere chance de partir, bornee : au-dela,
/// l'envoi continue en arriere-plan mais la sortie n'attend plus. Une file
/// illisible ou muette (base locale absente : test, galerie) vaut « aucun
/// cahier », dans la meme borne : la sortie n'attend jamais plus que
/// [AppDelais.envoiAvantDeconnexion] par etape. [rejouer] n'est construit que
/// s'il y a quelque chose a envoyer.
Future<int> rapportsRestantsApresEnvoi(
  DepotRapports depot,
  Future<int> Function() Function() rejouer,
) async {
  Future<int> compter() async {
    try {
      return (await depot.enAttente().timeout(AppDelais.envoiAvantDeconnexion))
          .length;
    } on Object {
      return 0;
    }
  }

  if (await compter() == 0) return 0;
  try {
    await rejouer()().timeout(AppDelais.envoiAvantDeconnexion);
  } on Object catch (erreur) {
    journalDev('Deconnexion : cahiers non partis, ${erreur.runtimeType}');
  }
  return compter();
}

/// La feuille « {n} cahiers de transmission ne sont pas envoyes. Se
/// deconnecter les perdra. » : « Annuler » ou « Se deconnecter quand meme ».
Future<bool> confirmerRapportsPerdus(BuildContext context, int restants) {
  if (!context.mounted) return Future<bool>.value(false);
  return ConfirmDestructive.demander(
    context,
    question: t.compte.tuteur.deconnexion.rapportsQuestion,
    consequence: t.compte.tuteur.deconnexion.rapportsConsequence(n: restants),
    libelleConfirmer: t.compte.tuteur.deconnexion.rapportsConfirmer,
    libelleAnnuler: t.compte.tuteur.deconnexion.rapportsAnnuler,
    irreversible: true,
  );
}

/// Le geste « Se deconnecter » d'un ecran : tout se lit avant la premiere
/// attente, la feuille de confirmation s'ouvre sur [context] s'il le faut.
Future<bool> seDeconnecter(BuildContext context, WidgetRef ref) => ref
    .read(deconnexionProvider)
    .executer(
      confirmerPerte: (int restants) =>
          confirmerRapportsPerdus(context, restants),
    );

/// La deconnexion employee par l'application. La base locale n'est lue qu'au
/// moment du geste : un ecran monte sans base locale (test, galerie) ne
/// l'ouvre jamais. Seule l'enseignante a des cahiers en file : pour les
/// autres roles, rien n'est lu avant la fermeture.
final Provider<Deconnexion> deconnexionProvider = Provider<Deconnexion>(
  (Ref ref) => Deconnexion(
    auth: ref.watch(serviceAuthProvider),
    rapportsRestants: () async {
      // Un ecran monte sans source de session (test, galerie) n'a aucune
      // file a lire : une session illisible vaut « pas une enseignante ».
      AppRole? role;
      try {
        role = ref.read(sessionProvider).role;
      } on Object {
        role = null;
      }
      if (role != AppRole.teacher) return 0;
      return rapportsRestantsApresEnvoi(
        ref.read(depotRapportsProvider),
        () => ref.read(soumissionCahierProvider).rejouer,
      );
    },
    viderAppareil: () => viderTablesDeLaPersonne(ref.read(baseLocaleProvider)),
    remiseAZero: ref.watch(remiseAZeroProvider),
  ),
);

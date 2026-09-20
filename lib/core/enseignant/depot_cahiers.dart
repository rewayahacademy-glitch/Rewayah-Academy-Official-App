import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appairage/profils_locaux.dart' show baseLocaleProvider;
import '../cache/db/app_database.dart';
import '../cache/sync/file_rapports.dart';
import 'modeles_enseignant.dart';
import 'service_enseignant.dart';

/// Ou vivent les cahiers en attente : la table drift `RapportsEnAttente`.
///
/// `DepotRapports` et `FileRapports` existaient depuis l'etape 2, avec leurs
/// tests, mais **aucune implementation de production** : la file n'etait branchee
/// sur rien. C'est ce que ce fichier repare, sans toucher a l'interface ni a la
/// table, qui suffisaient toutes les deux.
class DepotRapportsDrift implements DepotRapports {
  /// Cree le depot sur la base locale.
  const DepotRapportsDrift(this._base);

  final AppDatabase _base;

  @override
  Future<List<RapportEnAttente>> enAttente() async {
    final List<RapportsEnAttenteData> lignes =
        await (_base.select(_base.rapportsEnAttente)..orderBy(<
          OrderClauseGenerator<$RapportsEnAttenteTable>
        >[
          ($RapportsEnAttenteTable r) =>
              OrderingTerm(expression: r.redigeA),
        ])).get();

    return lignes
        .map(
          (RapportsEnAttenteData l) => RapportEnAttente(
            cleIdempotence: l.cleIdempotence,
            sessionId: l.sessionId,
            contenuJson: l.contenuJson,
            redigeA: l.redigeA,
            tentatives: l.tentatives,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> deposer(RapportEnAttente rapport) async {
    // `insertOrIgnore` et non `insertOnConflictUpdate` : un cahier deja en file
    // sous cette cle ne doit pas etre reecrit. La cle est l'identite du cahier,
    // pas une version.
    await _base
        .into(_base.rapportsEnAttente)
        .insert(
          RapportsEnAttenteCompanion.insert(
            cleIdempotence: rapport.cleIdempotence,
            sessionId: rapport.sessionId,
            contenuJson: rapport.contenuJson,
            redigeA: rapport.redigeA,
            tentatives: Value<int>(rapport.tentatives),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> retirer(String cleIdempotence) async {
    await (_base.delete(_base.rapportsEnAttente)..where(
      ($RapportsEnAttenteTable r) =>
          r.cleIdempotence.equals(cleIdempotence),
    )).go();
  }

  @override
  Future<void> majApresEchec(RapportEnAttente rapport) async {
    await (_base.update(_base.rapportsEnAttente)..where(
      ($RapportsEnAttenteTable r) =>
          r.cleIdempotence.equals(rapport.cleIdempotence),
    )).write(
      RapportsEnAttenteCompanion(tentatives: Value<int>(rapport.tentatives)),
    );
  }
}

/// Ce qu'il est advenu d'un cahier qu'on vient de valider.
enum SortCahier {
  /// Parti, et le serveur l'a accepte.
  envoye,

  /// Enregistre localement, il partira au retour du reseau.
  enFile,
}

/// La validation d'un cahier de transmission, hors ligne comprise.
///
/// **Le seul besoin d'ecriture hors ligne reel du produit.** Hors ligne, la
/// validation enregistre localement et l'ecran dit « sera envoye des le retour
/// du reseau », sans bloquer l'enseignant sur son cours suivant.
///
/// Deux garanties, qui ne reposent pas sur la meme chose :
///
/// 1. la cle d'idempotence est generee **une seule fois**, a la redaction, par
///    `FileRapports.enregistrer`, et ne change jamais au rejeu. C'est ce qui
///    permet a la contrainte d'unicite C9 de refuser un doublon en base ;
/// 2. un verrou local empeche deux vidages concurrents. Ce verrou est une
///    commodite : meme s'il sautait, la base trancherait.
class SoumissionCahier {
  /// Cree le soumetteur : la file, son depot, puis le service qui envoie.
  ///
  /// Positionnel comme `FileRapports(depot)` et `ServiceEnseignantSupabase(client)`
  /// : c'est le patron du depot pour une dependance injectee.
  const SoumissionCahier(this._file, this._depot, this._service);

  final FileRapports _file;
  final DepotRapports _depot;
  final ServiceEnseignant _service;

  /// Valide un cahier : l'enregistre, puis tente de vider la file.
  ///
  /// Retourne [SortCahier.envoye] seulement quand **ce** cahier a quitte la
  /// file. Se fier au nombre de rapports envoyes ne suffirait pas : un ancien
  /// cahier parti pendant que le nouveau echoue donnerait un compte non nul et
  /// l'ecran annoncerait a tort un envoi.
  Future<SortCahier> soumettre(CahierARendre cahier) async {
    final RapportEnAttente rapport = await _file.enregistrer(
      sessionId: cahier.seanceId,
      contenuJson: jsonEncode(cahier.versJson()),
    );

    await _file.vider(_envoyer);

    final List<RapportEnAttente> restants = await _depot.enAttente();
    final bool toujoursEnFile = restants.any(
      (RapportEnAttente r) => r.cleIdempotence == rapport.cleIdempotence,
    );
    return toujoursEnFile ? SortCahier.enFile : SortCahier.envoye;
  }

  /// Rejoue la file sans rien ecrire de nouveau. Rend le nombre de cahiers
  /// effectivement partis.
  Future<int> rejouer() => _file.vider(_envoyer);

  Future<void> _envoyer(RapportEnAttente rapport) => _service.deposerCahier(
    cleIdempotence: rapport.cleIdempotence,
    contenu: jsonDecode(rapport.contenuJson) as Map<String, dynamic>,
    seanceId: rapport.sessionId,
  );
}

/// Le depot local des cahiers en attente.
final Provider<DepotRapports> depotRapportsProvider = Provider<DepotRapports>(
  (Ref ref) => DepotRapportsDrift(ref.watch(baseLocaleProvider)),
);

/// La file de synchronisation des cahiers.
final Provider<FileRapports> fileRapportsProvider = Provider<FileRapports>(
  (Ref ref) => FileRapports(ref.watch(depotRapportsProvider)),
);

/// La validation d'un cahier, hors ligne comprise.
final Provider<SoumissionCahier> soumissionCahierProvider =
    Provider<SoumissionCahier>(
      (Ref ref) => SoumissionCahier(
        ref.watch(fileRapportsProvider),
        ref.watch(depotRapportsProvider),
        ref.watch(serviceEnseignantProvider),
      ),
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../profil/service_acceptations.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'versions_contrat.dart';

/// Q-2 = a (decision du directeur du 05/10/2026) : quand la politique de
/// controle est publiee ([VersionsContrat.politiqueControlePubliee]), un
/// enseignant qui a signe le contrat [VersionsContrat.courante] (2026-09)
/// signe la nouvelle version [VersionsContrat.textesJuridiques] (2026-10-jur).
///
/// Vrai seulement si la politique est publiee, qu'une acceptation du contrat
/// enseignant en version [VersionsContrat.courante] existe, et qu'aucune
/// n'existe en version [VersionsContrat.textesJuridiques]. Un enseignant qui
/// n'a encore rien signe passe par le portail d'attente comme avant.
///
/// `etat_dossier()` ne filtre pas la version du contrat (voir l'en-tete de
/// [VersionsContrat]) : la lecture se fait ici, sur les acceptations de la
/// personne connectee (`contract_acceptances`, lecture de soi). Ce n'est pas
/// une barriere de securite : le serveur n'exige pas encore la version
/// (DB-ADM-03, BR-1).
bool contratEnseignantARessigner(
  List<Acceptation> lues, {
  required bool politiquePubliee,
}) {
  if (!politiquePubliee) return false;
  bool ancienne = false;
  for (final Acceptation a in lues) {
    if (a.sorte != SorteContrat.contratEnseignant) continue;
    if (a.version == VersionsContrat.textesJuridiques) return false;
    if (a.version == VersionsContrat.courante) ancienne = true;
  }
  return ancienne;
}

/// L'interrupteur [VersionsContrat.politiqueControlePubliee], lu par un
/// provider pour que les tests puissent essayer les deux valeurs sans toucher
/// a la constante.
final Provider<bool> politiqueControlePublieeProvider = Provider<bool>(
  (Ref ref) => VersionsContrat.politiqueControlePubliee,
);

/// Vrai quand l'enseignant connecte doit signer de nouveau son contrat
/// ([contratEnseignantARessigner]).
///
/// Tant que la politique n'est pas publiee, rien n'est lu et la reponse est
/// faux : rien ne change. Une lecture des acceptations en cours ou en echec
/// rend faux aussi : l'enseignant n'est jamais bloque hors ligne, et la
/// question se repose a la lecture suivante.
final Provider<bool> resignatureContratEnseignantProvider = Provider<bool>((
  Ref ref,
) {
  if (!ref.watch(politiqueControlePublieeProvider)) return false;
  final AppRole? role = ref.watch(
    sessionProvider.select((SessionState session) => session.role),
  );
  if (role != AppRole.teacher) return false;
  final List<Acceptation>? lues = ref.watch(acceptationsProvider).value;
  if (lues == null) return false;
  return contratEnseignantARessigner(lues, politiquePubliee: true);
});

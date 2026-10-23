// ADM-23 : « Importer les formulaires de candidature », cote direction.
//
// Importer une fois les reponses des formulaires Google, pour reconnaitre et
// pre-remplir, sans creer de compte, d'invitation ni de candidature
// (`CATALOGUE_ECRANS_RECRUTEMENT.md`, fiche ADM-23 ; spec consolidee 3.2). Route
// `/admin/personnes/candidatures/import`, distincte de l'import des inscriptions.
//
// **Capacite `candidatures.importer`** : le super administrateur seul, en double
// verification (aal2 exigee en base). L'ecran lit `peutImporter` et
// `doubleVerificationRequise` ; il ne devine rien d'un role.
//
// Huit pas, une question chacun, jamais une fenetre : deposer le fichier, apercu,
// colonnes, doublons, erreurs, comptes, confirmation, rapport. Sur telephone, les
// pas se suivent sous une barre de progression ; sur tablette, les huit disques
// sont en haut ; sur bureau, un rail des pas est au bord de debut et le pas au
// bord de fin. Un seul bouton plein par pas, 16 sous son contenu.
//
// Etats : chargement (`Skeleton` pendant l'analyse), contenu, vide (fichier sans
// ligne), erreur (« L'analyse n'a pas abouti. » et « Reessayer »), hors ligne
// (l'apercu reste, la confirmation n'est pas rendue), capacite indisponible,
// acces refuse, double verification requise, fichier illisible, colonnes a
// associer, ecart des comptes, jeton perime. Rien n'est dit importe avant la
// reponse du serveur.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'pas_apercu.dart';
import 'pas_colonnes.dart';
import 'pas_comptes.dart';
import 'pas_confirmation.dart';
import 'pas_depot.dart';
import 'pas_doublons.dart';
import 'pas_erreurs.dart';
import 'pas_rapport.dart';

/// La largeur du rail des pas sur bureau (file de 336, contrat D).
const double largeurRail = 336;

/// La largeur du pas, a cote du rail ou seul (detail de 728, contrat D).
const double largeurPas = 728;

/// L'ecran « Importer les formulaires de candidature ».
class ImportFormulairesPage extends ConsumerWidget {
  /// Cree l'ecran.
  const ImportFormulairesPage({super.key});

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('import-formulaires-page');

  void _revenir(BuildContext context) {
    final GoRouter routeur = GoRouter.of(context);
    routeur.go(Routes.adminPersonnesCandidatures);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = t.admin.importFormulaires;
    final AsyncValue<CapacitesImportCandidatures> caps = ref.watch(
      capacitesImportCandidaturesProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final PortImportCandidatures? port = ref.watch(
      portImportCandidaturesProvider,
    );
    if (port != null && caps.hasValue && caps.requireValue.peutImporter) {
      return ParcoursImport(
        key: const ValueKey<String>('import-parcours'),
        port: port,
        onRevenir: () => _revenir(context),
      );
    }
    return PageShell(
      key: clePage,
      titre: a.titre,
      sousTitre: AppGabarit.de(context) == Gabarit.mobile ? null : a.intro,
      onRetour: () => _revenir(context),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: largeurPas),
          child: BlocAsynchrone<CapacitesImportCandidatures>(
            key: const ValueKey<String>('import-bloc'),
            valeur: caps,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: () =>
                ref.invalidate(capacitesImportCandidaturesProvider),
            erreurVersEtat: (Object e, VoidCallback? reessayer) {
              if (e is CapaciteIndisponible) {
                return EtatSysteme(
                  key: const ValueKey<String>('import-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: t.commun.etats.branchementServeur,
                  phrase: '',
                  dependance: e.dependance,
                );
              }
              if (e is PermissionInsuffisante) {
                return _refus();
              }
              return horsLigne
                  ? EtatSansDonnees(
                      key: const ValueKey<String>('import-sans-donnees'),
                      quoi: a.sansDonnees,
                      onAction: reessayer,
                    )
                  : EtatSysteme(
                      key: const ValueKey<String>('import-lecture-echec'),
                      nature: NatureEtat.echecServeur,
                      phrase: a.lectureDroits,
                      onAction: reessayer,
                    );
            },
            construire: (CapacitesImportCandidatures c) =>
                c.doubleVerificationRequise
                ? EtatDoubleVerification(
                    onAction: () =>
                        unawaited(ref.read(serviceAuthProvider).deconnexion()),
                  )
                : _refus(),
          ),
        ),
      ),
    );
  }

  Widget _refus() => EtatSysteme(
    key: const ValueKey<String>('import-refuse'),
    nature: NatureEtat.accesRefuse,
    titre: t.admin.importFormulaires.acces.refuseTitre,
    phrase: t.admin.importFormulaires.acces.refusePhrase,
  );
}

/// « Double verification requise » : le refus du serveur, en mots et en action.
/// L'action met fin a la session pour que la direction se reconnecte avec son
/// second facteur ; il n'existe pas, dans l'application, d'ecran qui monte une
/// session en double verification sans la fermer.
class EtatDoubleVerification extends StatelessWidget {
  /// Cree l'etat.
  const EtatDoubleVerification({required this.onAction, super.key});

  /// Met fin a la session.
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires.acces;
    return EtatSysteme(
      key: const ValueKey<String>('import-double'),
      nature: NatureEtat.accesRefuse,
      titre: t.admin.importInscriptions.acces.doubleTitre,
      phrase: '${a.doublePhrase} ${a.doubleSuite}',
      libelleAction: a.doubleAction,
      onAction: onAction,
    );
  }
}

/// Le parcours : le controleur et les huit pas.
class ParcoursImport extends ConsumerStatefulWidget {
  /// Cree le parcours.
  const ParcoursImport({
    required this.port,
    required this.onRevenir,
    super.key,
  });

  /// Le port de l'import.
  final PortImportCandidatures port;

  /// Revient a la file des candidatures.
  final VoidCallback onRevenir;

  @override
  ConsumerState<ParcoursImport> createState() => _ParcoursImportEtat();
}

class _ParcoursImportEtat extends ConsumerState<ParcoursImport> {
  late final ControleurImportCandidatures _c = ControleurImportCandidatures(
    port: widget.port,
    horsLigne: () => ref.read(horsLigneProvider).value ?? false,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Un refus du serveur qui ne concerne pas un pas mais tout l'import.
  Widget? _etatGlobal() {
    final Object? e = _c.erreurConfirmation ?? _c.erreurAnalyse;
    final a = t.admin.importFormulaires;
    if (e is DoubleVerificationRequise) {
      return EtatDoubleVerification(
        onAction: () => unawaited(ref.read(serviceAuthProvider).deconnexion()),
      );
    }
    if (e is PermissionInsuffisante) {
      return EtatSysteme(
        key: const ValueKey<String>('import-refuse'),
        nature: NatureEtat.accesRefuse,
        titre: a.acces.refuseTitre,
        phrase: a.acces.refusePhrase,
      );
    }
    if (e is CapaciteIndisponible) {
      return EtatSysteme(
        key: const ValueKey<String>('import-indisponible'),
        nature: NatureEtat.indisponible,
        titre: t.commun.etats.branchementServeur,
        phrase: '',
        dependance: e.dependance,
      );
    }
    return null;
  }

  Widget _pas(bool empile, bool horsLigne) {
    final Widget? global = _etatGlobal();
    if (global != null) return global;
    return switch (_c.pas) {
      PasImport.depot => PasDepot(
        controleur: _c,
        empile: empile,
        horsLigne: horsLigne,
      ),
      PasImport.apercu => PasApercu(controleur: _c, empile: empile),
      PasImport.colonnes => PasColonnes(
        controleur: _c,
        empile: empile,
        horsLigne: horsLigne,
      ),
      PasImport.doublons => PasDoublons(controleur: _c, empile: empile),
      PasImport.erreurs => PasErreurs(controleur: _c, empile: empile),
      PasImport.comptes => PasComptes(controleur: _c, empile: empile),
      PasImport.confirmation => PasConfirmation(
        controleur: _c,
        empile: empile,
        horsLigne: horsLigne,
      ),
      PasImport.rapport => PasRapport(
        controleur: _c,
        onRevenir: widget.onRevenir,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final Gabarit gabarit = AppGabarit.de(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (BuildContext context, Widget? _) {
        final bool empile = gabarit == Gabarit.mobile;
        final Widget pas = KeyedSubtree(
          key: ValueKey<String>('import-pas-${_c.pas.name}'),
          child: _pas(empile, horsLigne),
        );
        final Widget corps = switch (gabarit) {
          Gabarit.desktop => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: largeurRail,
                child: RailPas(courant: _c.pas),
              ),
              Ecart.hXxl,
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: largeurPas),
                    child: pas,
                  ),
                ),
              ),
            ],
          ),
          _ => Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: largeurPas),
              child: pas,
            ),
          ),
        };
        final Widget page = PageShell(
          // Un pas neuf repart du haut de la page.
          key: ValueKey<String>('import-page-${_c.pas.name}'),
          titre: a.titre,
          sousTitre: gabarit == Gabarit.mobile ? null : a.intro,
          onRetour: _c.occupe ? () {} : widget.onRevenir,
          entete: switch (gabarit) {
            Gabarit.mobile => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: ProgressionPas(courant: _c.pas),
            ),
            Gabarit.tablette => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: BandePas(courant: _c.pas),
            ),
            Gabarit.desktop => null,
          },
          child: corps,
        );
        // Pas de sortie pendant l'envoi : la reponse du serveur et la cle
        // d'idempotence seraient perdues.
        return PopScope(canPop: !_c.occupe, child: page);
      },
    );
  }
}

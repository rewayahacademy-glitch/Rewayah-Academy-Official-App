/// `ADM-21` : une candidature ouverte par la direction, sous Personnes.
///
/// En tete, la situation (etape, etat, pause, restriction), puis ce qui bloque,
/// la prochaine action (le seul bouton plein), les reponses, les controles, ce
/// que le serveur ne sert pas encore, le responsable, le contact et
/// l'historique. Les gestes que le serveur ouvre (`capacites_candidatures`) se
/// font chacun dans une feuille de confirmation, avec la version attendue et une
/// cle d'idempotence ; le serveur decide, et ses refus nommes se disent en mots.
///
/// **Tout vient du serveur, rien n'est recalcule ici.** La portee de genre
/// (hors portee et absente sont deux erreurs), les controles, l'etat, la version
/// et l'historique sont rendus par `lire_candidature`, `historique_candidature`
/// et les RPC des gestes. Un widget lit une capacite, jamais un role.
///
/// La route est `/admin/personnes/candidatures/<reference>` : la reference
/// `CAND-…` ne nomme personne et survit au rechargement (`CAND-F02`). La page
/// recoit l'identifiant de la ligne par `extra` quand la direction vient de la
/// file ; sinon (adresse tapee, page rechargee) elle retrouve la candidature par
/// la recherche exacte de la file, dans la portee du lecteur.
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, historique
/// vide, erreur (« Reessayer »), hors ligne (bandeau de `PageShell`, la
/// derniere lecture reste, aucun geste, une note le dit ; `EtatSansDonnees`
/// quand rien n'a pu etre lu), capacite indisponible, hors portee, absente,
/// acces refuse, genre du lecteur inconnu, blocs non servis (chacun le dit
/// seul), geste refuse (en mots, dans la feuille).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import 'blocs_candidature.dart';
import 'feuille_geste.dart';
import 'gestes_proposes.dart';
import 'libelles_candidature.dart';
import 'reponses_candidature.dart';

/// L'ecran « Candidature ».
class CandidatureDirectionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran pour la candidature de reference [reference].
  const CandidatureDirectionPage({
    required this.reference,
    super.key,
    this.identifiant,
    this.onRetour,
  });

  /// La reference `CAND-…` de l'adresse.
  final String reference;

  /// L'identifiant de la candidature, quand la navigation le connait deja.
  final String? identifiant;

  /// Revient a la file. Par defaut, retour a la pile de navigation, sinon a la
  /// file des candidatures.
  final VoidCallback? onRetour;

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('candidature-page');

  @override
  ConsumerState<CandidatureDirectionPage> createState() =>
      _EtatCandidatureDirectionPage();
}

class _EtatCandidatureDirectionPage
    extends ConsumerState<CandidatureDirectionPage> {
  /// Le retour local du dernier geste : dit seulement apres la reponse du
  /// serveur.
  String? _retour;

  DemandeDossier get _demande =>
      DemandeDossier(widget.reference, id: widget.identifiant);

  void _relire({String? identifiant}) {
    ref.invalidate(detailCandidatureProvider(_demande));
    if (identifiant != null) {
      ref.invalidate(historiqueCandidatureProvider(identifiant));
    }
    // La file affichait l'etat d'avant le geste : elle se relit au retour.
    ref
      ..invalidate(pageCandidaturesProvider)
      ..invalidate(capacitesCandidaturesProvider);
  }

  void _retourALaFile() {
    final VoidCallback? retour = widget.onRetour;
    if (retour != null) {
      retour();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.adminPersonnesCandidatures);
    }
  }

  Future<void> _geste(
    GesteCandidature geste,
    DetailCandidature detail,
    CapacitesCandidatures capacites,
  ) async {
    final SortieFeuille? sortie = await ouvrirFeuilleGeste(
      context,
      geste: geste,
      detail: detail,
      capacites: capacites,
    );
    if (!mounted || sortie == null) return;
    _relire(identifiant: detail.ligne.id);
    if (sortie.issue == IssueFeuille.fait) {
      setState(
        () => _retour = sortie.rejoue
            ? t.admin.candidatures.retours.rejoue
            : libelleRetour(geste),
      );
    } else {
      setState(() => _retour = null);
    }
  }

  /// Les etats propres a la candidature, avant le cas par defaut de
  /// [BlocAsynchrone].
  Widget? _etatErreur(Object erreur, VoidCallback? reessayer, bool horsLigne) {
    final r = t.admin.candidatures;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        key: const ValueKey<String>('candidature-indisponible'),
        nature: NatureEtat.indisponible,
        titre: t.commun.etats.branchementServeur,
        phrase: '',
        dependance: erreur.dependance,
      );
    }
    if (erreur is CandidatureHorsPortee) {
      return EtatSysteme(
        key: const ValueKey<String>('candidature-hors-portee'),
        nature: NatureEtat.accesRefuse,
        titre: r.detail.titreHorsPortee,
        phrase: r.detail.revenirALaFile,
      );
    }
    if (erreur is CandidatureIntrouvable) {
      return EtatSysteme(
        key: const ValueKey<String>('candidature-absente'),
        nature: NatureEtat.introuvable,
        titre: r.detail.titreAbsente,
        phrase: r.detail.revenirALaFile,
      );
    }
    if (erreur is GenreLecteurInconnu) {
      return EtatSysteme(
        key: const ValueKey<String>('candidature-genre-inconnu'),
        nature: NatureEtat.accesRefuse,
        titre: r.genreInconnuTitre,
        phrase: r.genreInconnu,
      );
    }
    if (erreur is PermissionInsuffisante) {
      return EtatSysteme(
        key: const ValueKey<String>('candidature-acces-refuse'),
        nature: NatureEtat.accesRefuse,
        titre: r.accesRefuse,
        phrase: '',
      );
    }
    if (horsLigne) {
      return EtatSansDonnees(
        key: const ValueKey<String>('candidature-sans-donnees'),
        quoi: r.detail.sansDonnees,
        onAction: reessayer,
      );
    }
    return EtatSysteme(
      key: const ValueKey<String>('candidature-erreur'),
      nature: NatureEtat.echecServeur,
      titre: r.detail.titreLecture,
      phrase: reessayer == null ? t.commun.etats.reessaisEpuises : '',
      onAction: reessayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DetailCandidature> valeur = ref.watch(
      detailCandidatureProvider(_demande),
    );
    final CapacitesCandidatures capacites =
        ref.watch(capacitesCandidaturesProvider).value ??
        CapacitesCandidatures.aucune;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final DetailCandidature? detail = valeur.value;
    final r = t.admin.candidatures;

    return PageShell(
      key: CandidatureDirectionPage.clePage,
      titre: detail == null
          ? referenceDuDossier(widget.reference)
          : nomAffiche(detail.ligne),
      sousTitre: detail == null ? null : referenceDuDossier(widget.reference),
      onRetour: _retourALaFile,
      entete: detail != null && capacites.peutLireHorsGenre && detail.autreCote
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: BandeauAttention(
                key: const ValueKey<String>('candidature-exception'),
                titre: r.exception.titre,
                message: r.exception.candidature,
              ),
            )
          : null,
      child: BlocAsynchrone<DetailCandidature>(
        key: const ValueKey<String>('candidature-bloc'),
        valeur: valeur,
        squelette: const Skeleton.texte(lignes: 6),
        onReessayer: _relire,
        erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
            _etatErreur(erreur, reessayer, horsLigne),
        construire: (DetailCandidature d) => _Contenu(
          detail: d,
          capacites: capacites,
          horsLigne: horsLigne,
          retour: _retour,
          onGeste: (GesteCandidature g) => _geste(g, d, capacites),
          onOuvrirDossier: () => context.go(Routes.adminPersonnesDossiers),
        ),
      ),
    );
  }
}

/// Le contenu d'une candidature lue : une colonne sur mobile et tablette, deux
/// colonnes ouvert seul sur grand ecran (au debut : situation, blocages,
/// prochaine action, controles ; a la fin, dans l'ordre de `CONS` §10 :
/// reponses, piece, entretien, responsable, affectation, contact, courriels,
/// historique).
class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.detail,
    required this.capacites,
    required this.horsLigne,
    required this.onGeste,
    required this.onOuvrirDossier,
    this.retour,
  });

  final DetailCandidature detail;
  final CapacitesCandidatures capacites;
  final bool horsLigne;
  final String? retour;
  final ValueChanged<GesteCandidature> onGeste;
  final VoidCallback onOuvrirDossier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GestesProposes gestes = gestesProposes(detail, capacites);
    final String? pays = declarationVersement(detail).pays;
    // Le nom des operateurs vient du referentiel des moyens confirmes ; sans
    // lui (liste non servie, panne), les moyens se disent par leur nombre.
    final Map<String, String> noms = pays == null || !capacites.peutDecider
        ? const <String, String>{}
        : <String, String>{
            for (final OperateurPaiement o
                in ref
                        .watch(moyensConfirmesDirectionProvider(pays))
                        .value
                        ?.operateurs ??
                    const <OperateurPaiement>[])
              o.code: o.nom,
          };

    final Widget situation = CarteSituation(detail: detail);
    final Widget blocages = BlocBlocages(detail: detail);
    final Widget action = BlocProchaineAction(
      detail: detail,
      gestes: gestes,
      horsLigne: horsLigne,
      onGeste: onGeste,
      retour: retour,
    );
    final Widget controles = BlocControles(detail: detail);
    final Widget reponses = BlocReponses(detail: detail, nomsOperateurs: noms);
    final Widget pieceEntretien = BlocPieceEntretien(
      detail: detail,
      onOuvrirDossier: onOuvrirDossier,
    );
    final Widget responsable = BlocResponsable(detail: detail);
    const Widget affectation = BlocAffectation();
    const Widget courriels = BlocCourriels();
    final Widget contact = BlocContact(
      onVoir: capacites.peutVoirContact && !horsLigne
          ? () => ouvrirFeuilleContact(context, candidatureId: detail.ligne.id)
          : null,
    );
    final Widget historique = BlocHistorique(candidatureId: detail.ligne.id);

    Widget colonne(List<Widget> blocs) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < blocs.length; i++) ...<Widget>[
          if (i > 0) Ecart.vXxl,
          blocs[i],
        ],
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool deuxColonnes =
            contraintes.maxWidth >= AppGabarit.seuilEtendu &&
            MediaQuery.textScalerOf(context).scale(16) / 16 <
                AppGabarit.seuilTexteColonne;
        if (!deuxColonnes) {
          return colonne(<Widget>[
            situation,
            blocages,
            action,
            reponses,
            controles,
            pieceEntretien,
            responsable,
            affectation,
            contact,
            courriels,
            historique,
          ]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: colonne(<Widget>[situation, blocages, action, controles]),
            ),
            Ecart.hXxl,
            Expanded(
              child: colonne(<Widget>[
                reponses,
                pieceEntretien,
                responsable,
                affectation,
                contact,
                courriels,
                historique,
              ]),
            ),
          ],
        );
      },
    );
  }
}

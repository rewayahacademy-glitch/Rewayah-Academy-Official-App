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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/gestes_candidature.dart';
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
import '../com_messages/entree_messages_contexte.dart';
import 'blocs_candidature.dart';
import 'dossier_trois_etages.dart';
import 'feuille_geste.dart';
import 'libelles_candidature.dart';
import 'plan_dossier.dart';
import 'volet_conversation.dart';

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

  /// V2-a : le retour local du dernier geste d'entretien, dit dans la section
  /// Entretien.
  String? _retourEntretien;

  /// RECRUTEMENT-SANS-SORTIE (directeur, 14/11/2026) : la conversation
  /// ouverte dans le dossier (volet de cote sur ordinateur), ou `null`.
  ConversationEnPlace? _conversation;

  /// Relit l'entree des messages (ses badges) apres une lecture faite dans
  /// le volet ou la feuille.
  int _rangMessages = 0;

  void _messagesLus() {
    if (mounted) setState(() => _rangMessages++);
  }

  /// Ouvre la conversation sans quitter le dossier : volet a droite sur
  /// ordinateur, surface plein ecran au telephone et a la tablette.
  void _ouvrirConversation(ConversationEnPlace c) {
    if (MediaQuery.sizeOf(context).width >= AppGabarit.seuilEtendu) {
      setState(() => _conversation = c);
      return;
    }
    unawaited(
      ouvrirFeuilleConversation(
        context,
        conversation: c,
        onLu: _messagesLus,
      ).whenComplete(_messagesLus),
    );
  }

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
    CapacitesCandidatures capacites, {
    Set<String> elementsInitiaux = const <String>{},
  }) async {
    final SortieFeuille? sortie = await ouvrirFeuilleGeste(
      context,
      geste: geste,
      detail: detail,
      capacites: capacites,
      elementsInitiaux: elementsInitiaux,
    );
    if (!mounted || sortie == null) return;
    _relire(identifiant: detail.ligne.id);
    _retourEntretien = null;
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

    final PlanDossier? plan = detail == null
        ? null
        : PlanDossier(
            detail: detail,
            capacites: capacites,
            horsLigne: horsLigne,
          );
    // Sur ordinateur, les etages 1 et 2 sont a gauche, dans la page ; sinon
    // l'etage 1 reste fixe sous le titre. Meme regle que l'ancienne page : la
    // largeur de la page, et le texte pas trop agrandi.
    final Widget page = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool deuxColonnes =
            contraintes.maxWidth >= AppGabarit.seuilEtendu &&
            MediaQuery.textScalerOf(context).scale(16) / 16 <
                AppGabarit.seuilTexteColonne;
        final Widget? exception =
            detail != null && capacites.peutLireHorsGenre && detail.autreCote
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: BandeauAttention(
                  key: const ValueKey<String>('candidature-exception'),
                  titre: r.exception.titre,
                  message: r.exception.candidature,
                ),
              )
            : null;
        return PageShell(
          key: CandidatureDirectionPage.clePage,
          titre: detail == null
              ? referenceDuDossier(widget.reference)
              : nomAffiche(detail.ligne),
          sousTitre: detail == null
              ? null
              : referenceDuDossier(widget.reference),
          onRetour: _retourALaFile,
          // BE-DOSSIER : la page porte son propre defilement (une seule barre,
          // celle de la page) pour que l'etage 1 reste en haut et la barre de
          // decision en bas. Voir le cahier : ecart a SANS-BARRE-FIXE, dit au
          // coordinateur.
          defilante: false,
          entete: plan == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ?exception,
                    if (!deuxColonnes) ...<Widget>[
                      Ecart.vSm,
                      EtageUnDossier(plan: plan),
                    ],
                  ],
                ),
          actions: plan == null || !capacites.peutDecider
              ? null
              : BarreDecisionDossier(
                  plan: plan,
                  onGeste: (GesteCandidature g) =>
                      _geste(g, plan.detail, capacites),
                  autresActions: actionsSupplementaires(
                    context,
                    ref,
                    plan.detail,
                  ),
                ),
          child: SingleChildScrollView(
            child: BlocAsynchrone<DetailCandidature>(
              key: const ValueKey<String>('candidature-bloc'),
              valeur: valeur,
              squelette: const Skeleton.texte(lignes: 6),
              onReessayer: _relire,
              erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                  _etatErreur(erreur, reessayer, horsLigne),
              construire: (DetailCandidature d) => CorpsDossier(
                plan: PlanDossier(
                  detail: d,
                  capacites: capacites,
                  horsLigne: horsLigne,
                ),
                deuxColonnes: deuxColonnes,
                retour: _retour,
                onGeste: (GesteCandidature g) => _geste(g, d, capacites),
                // COMPLEMENT-ET-FORMATS : « Demander une nouvelle piece » (ou
                // photo) depuis un fichier illisible : la feuille du
                // complement s'ouvre, l'element deja coche. Un geste.
                onDemanderElement: (String code) => _geste(
                  GesteCandidature.demanderComplement,
                  d,
                  capacites,
                  elementsInitiaux: <String>{code},
                ),
                // RECRUTEMENT-SANS-SORTIE : « Dossiers a valider » s'empile ;
                // son retour ramene ici.
                onOuvrirDossier: () => unawaited(
                  context.push<void>(Routes.adminPersonnesDossiers),
                ),
                onOuvrirConversation: _ouvrirConversation,
                rangMessages: _rangMessages,
                retourEntretien: _retourEntretien,
                onEntretien: (String message) {
                  _relire(identifiant: d.ligne.id);
                  setState(() {
                    _retour = null;
                    _retourEntretien = message;
                  });
                },
              ),
            ),
          ),
        );
      },
    );
    final ConversationEnPlace? conversation = _conversation;
    if (conversation == null ||
        MediaQuery.sizeOf(context).width < AppGabarit.seuilEtendu) {
      return page;
    }
    // Sur ordinateur, le volet de cote : le dossier reste a gauche, lisible
    // et utilisable ; la croix du volet le replie.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: page),
        SizedBox(
          width: AppPage.largeurVolet,
          child: VoletConversation(
            conversation: conversation,
            onLu: _messagesLus,
            onReplier: () => setState(() {
              _conversation = null;
              _rangMessages++;
            }),
          ),
        ),
      ],
    );
  }
}

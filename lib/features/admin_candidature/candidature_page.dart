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
import 'package:flutter/services.dart';
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
import '../../core/theme/app_mouvement.dart';
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
import 'navigation_dossier.dart';
import 'plan_dossier.dart';
import 'suivant_dossier.dart';
import 'synthese_tete_dossier.dart';
import 'volet_conversation.dart';

/// Les gestes qui sont une decision : apres eux, le dossier suivant s'ouvre
/// (BE-SUIVANT) : admettre, demander une precision, refuser, valider la piece.
const Set<GesteCandidature> _gestesDeDecision = <GesteCandidature>{
  GesteCandidature.admettreVerifications,
  GesteCandidature.demanderComplement,
  GesteCandidature.refuser,
  GesteCandidature.validerPiece,
};

/// L'ecran « Candidature ».
class CandidatureDirectionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran pour la candidature de reference [reference].
  const CandidatureDirectionPage({
    required this.reference,
    super.key,
    this.identifiant,
    this.onRetour,
    this.requete,
  });

  /// BE-SUIVANT : l'adresse du dossier (`depuis=liste` et le filtre et le tri
  /// de la liste d'ou il est ouvert), ou `null`. Sans file, le dossier ne
  /// propose ni « 3 sur 176 » ni passage au suivant.
  final Map<String, String>? requete;

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

/// Les gestes apres lesquels la page propose d'ecrire a la personne : aucun
/// message ne part de lui-meme (APRES-CONFIRMEE).
const Set<GesteCandidature> _gestesQuiInvitentAEcrire = <GesteCandidature>{
  GesteCandidature.restreindre,
  GesteCandidature.demanderVerificationPiece,
  GesteCandidature.demanderVerificationVersement,
  GesteCandidature.leverRestriction,
};

class _EtatCandidatureDirectionPage
    extends ConsumerState<CandidatureDirectionPage> {
  /// Le retour local du dernier geste : dit seulement apres la reponse du
  /// serveur.
  String? _retour;

  /// APRES-CONFIRMEE (pilote, 17/11) : apres une restriction, une demande de
  /// verification ou sa levee, aucun message ne part tout seul ; le retour local
  /// propose « Ecrire a la personne » (la messagerie du dossier).
  bool _ecrireApres = false;

  /// V2-a : le retour local du dernier geste d'entretien, dit dans la section
  /// Entretien.
  String? _retourEntretien;

  /// RECRUTEMENT-SANS-SORTIE (directeur, 14/11/2026) : la conversation
  /// ouverte dans le dossier (volet de cote sur ordinateur), ou `null`.
  ConversationEnPlace? _conversation;

  /// BE-SUIVANT : le minuteur du passage au suivant, et ce qui est annonce.
  Timer? _minuteurPassage;
  bool _passageEnCours = false;
  bool _finDeFile = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_toucheClavier);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_toucheClavier);
    _minuteurPassage?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CandidatureDirectionPage ancienne) {
    super.didUpdateWidget(ancienne);
    // Un autre dossier dans la meme page : rien de l'ancien ne reste annonce.
    if (ancienne.reference != widget.reference) {
      _minuteurPassage?.cancel();
      _passageEnCours = false;
      _finDeFile = false;
      _retour = null;
      _ecrireApres = false;
      _retourEntretien = null;
    }
  }

  FileDuDossier? get _file => FileDuDossier.depuis(widget.requete);

  VoisinsCandidature? get _voisins {
    final FileDuDossier? file = _file;
    if (file == null) return null;
    return ref
        .read(voisinsDuDossierProvider(DemandeVoisins(widget.reference, file)))
        .value;
  }

  /// Ouvre le dossier [reference] de la meme file ; il **remplace** le dossier
  /// courant dans la pile : « retour » ramene toujours a la liste.
  void _allerAuDossier(String reference) {
    final FileDuDossier? file = _file;
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (file == null || routeur == null || !mounted) return;
    _minuteurPassage?.cancel();
    unawaited(
      routeur.replace<void>(
        Routes.adminPersonnesCandidaturePour(
          reference,
          fileDeLaListe: file.adresse,
        ),
      ),
    );
  }

  /// Fleches du clavier sur ordinateur : precedent et suivant, jamais quand le
  /// curseur est dans un champ de texte, jamais sous une feuille ou une boite
  /// ouverte, jamais avec une touche de controle. En arabe, le sens des fleches
  /// suit celui de la lecture.
  bool _toucheClavier(KeyEvent evenement) {
    if (evenement is! KeyDownEvent || !mounted) return false;
    final LogicalKeyboardKey touche = evenement.logicalKey;
    if (touche != LogicalKeyboardKey.arrowLeft &&
        touche != LogicalKeyboardKey.arrowRight) {
      return false;
    }
    if (MediaQuery.sizeOf(context).width < AppGabarit.seuilEtendu) return false;
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isShiftPressed) {
      return false;
    }
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    final BuildContext? focus = FocusManager.instance.primaryFocus?.context;
    if (focus != null &&
        (focus.widget is EditableText ||
            focus.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    final VoisinsCandidature? v = _voisins;
    if (v == null) return false;
    final bool arabe = Directionality.of(context) == TextDirection.rtl;
    final bool versLaFin = (touche == LogicalKeyboardKey.arrowRight) != arabe;
    final String? cible = versLaFin ? v.suivant : v.precedent;
    if (cible == null) return false;
    _allerAuDossier(cible);
    return true;
  }

  /// Une decision vient d'etre enregistree : le dossier suivant s'ouvre seul
  /// apres un instant, sauf si le reglage est coupe ou si l'on reste. En fin de
  /// file, la phrase le dit.
  void _apresDecision(VoisinsCandidature? voisins) {
    if (_file == null || voisins == null || voisins.rang == null) return;
    _minuteurPassage?.cancel();
    final String? suivant = voisins.suivant;
    if (suivant == null) {
      setState(() {
        _passageEnCours = false;
        _finDeFile = true;
      });
      return;
    }
    if (!ref.read(passerAuSuivantProvider)) return;
    setState(() {
      _passageEnCours = true;
      _finDeFile = false;
    });
    _minuteurPassage = Timer(AppMouvement.retourLocalMaintien, () {
      if (mounted && _passageEnCours) _allerAuDossier(suivant);
    });
  }

  /// Reste sur ce dossier : le suivant ne s'ouvre pas. La decision, elle, est
  /// deja enregistree.
  void _resterSurLeDossier() {
    _minuteurPassage?.cancel();
    setState(() => _passageEnCours = false);
  }

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
      // Sans pile (page rechargee) : la liste, avec la file du dossier.
      final FileDuDossier? file = _file;
      context.go(
        file == null
            ? Routes.adminPersonnesCandidatures
            : Uri(
                path: Routes.adminPersonnesCandidatures,
                queryParameters: file.adresse.isEmpty ? null : file.adresse,
              ).toString(),
      );
    }
  }

  Future<void> _geste(
    GesteCandidature geste,
    DetailCandidature detail,
    CapacitesCandidatures capacites, {
    Set<String> elementsInitiaux = const <String>{},
  }) async {
    // Le suivant se lit AVANT le geste : apres, le dossier peut ne plus etre
    // dans le filtre de la file (un dossier « en examen » qu'on accepte).
    final VoisinsCandidature? voisinsAvant = _voisins;
    final SortieFeuille? sortie = await ouvrirFeuilleGeste(
      context,
      geste: geste,
      detail: detail,
      capacites: capacites,
      // PE-C10 (directeur, 19/11/2026) : « Demander un complement » s'ouvre
      // avec tous les elements manquants deja coches ; on decoche ce qu'on
      // ne veut pas. Un element nomme par l'appelant (piece illisible) prime.
      elementsInitiaux:
          elementsInitiaux.isEmpty &&
              geste == GesteCandidature.demanderComplement
          ? elementsComplementManquants(detail)
          : elementsInitiaux,
    );
    if (!mounted || sortie == null) return;
    _relire(identifiant: detail.ligne.id);
    _retourEntretien = null;
    if (sortie.issue == IssueFeuille.fait) {
      setState(() {
        _retour = sortie.rejoue
            ? t.admin.candidatures.retours.rejoue
            : libelleRetour(geste);
        _ecrireApres = _gestesQuiInvitentAEcrire.contains(geste);
      });
      if (_gestesDeDecision.contains(geste)) _apresDecision(voisinsAvant);
    } else {
      setState(() {
        _retour = null;
        _ecrireApres = false;
      });
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
    final FileDuDossier? file = _file;
    final VoisinsCandidature? voisins = file == null
        ? null
        : ref
              .watch(
                voisinsDuDossierProvider(
                  DemandeVoisins(widget.reference, file),
                ),
              )
              .value;

    // Sur ordinateur, les etages 1 et 2 sont a gauche, les rubriques a droite.
    // Meme regle que l'ancienne page : la largeur de la page, et le texte pas
    // trop agrandi.
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
          // Rien de fixe (coordinateur, 16/11 : SANS-BARRE-FIXE et DEFILEMENT) :
          // la page defile en entier, une seule barre de defilement.
          entete: exception,
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
              onPropositionTraitee: () => _relire(identifiant: d.ligne.id),
              retour: _passageEnCours || _finDeFile ? null : _retour,
              ecrireApres: _ecrireApres,
              navigation: voisins == null
                  ? null
                  : NavigationFileDossier(
                      voisins: voisins,
                      onAller: _allerAuDossier,
                    ),
              passage: _passageEnCours || _finDeFile
                  ? PassageAuSuivant(
                      enCours: _passageEnCours,
                      finDeFile: _finDeFile,
                      onRester: _resterSurLeDossier,
                      onListe: _retourALaFile,
                    )
                  : null,
              reglage: voisins == null ? null : const ReglagePasserAuSuivant(),
              onDecisionPiece: (String message) {
                _relire(identifiant: d.ligne.id);
                setState(() {
                  _retour = message;
                  _ecrireApres = false;
                  _retourEntretien = null;
                });
                _apresDecision(voisins);
              },
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
              onOuvrirConversation: _ouvrirConversation,
              autresActions: actionsSupplementaires(context, ref, d),
              rangMessages: _rangMessages,
              retourEntretien: _retourEntretien,
              onEntretien: (String message) {
                _relire(identifiant: d.ligne.id);
                setState(() {
                  _retour = null;
                  _ecrireApres = false;
                  _retourEntretien = message;
                });
              },
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

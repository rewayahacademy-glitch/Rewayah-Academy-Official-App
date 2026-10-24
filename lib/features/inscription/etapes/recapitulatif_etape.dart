import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/candidature/port_inscription_candidat.dart';
import '../../../core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import '../../../core/candidature/port_nom_latin.dart';
import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/permission_insuffisante.dart';
import '../../../core/domain/enums.dart';
import '../../../core/dossier/etat_dossier.dart';
import '../../../core/dossier/service_dossier.dart';
import '../../../core/i18n/isolat_bidi.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/recrutement/port_invitations_comptable.dart';
import '../../../core/recrutement/port_invitations_enseignant.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/champ_etiquete.dart' show TitreChamp;
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../consentements/texte_observation.dart' show CaseAccordTexte;
import '../../juridique/juridique_pages.dart' show ligneVersionJuridique;
import '../../juridique/textes_juridiques.dart';
import '../brouillon_inscription.dart';
import '../code_comptable_retenu.dart';
import '../inscription_page.dart';

/// `/inscription/recapitulatif` : les reponses, un « Modifier » par ligne, et
/// la creation du compte.
///
/// Double soumission bloquee (drapeau pose avant tout `await`). Impasse apres
/// `refreshSession` corrigee : une fois le profil cree, une nouvelle tentative
/// ne rappelle que le rafraichissement (la creation refuserait un doublon), et
/// la page part d'elle-meme vers `/attente` (`/comptable` pour le comptable
/// invite, lot F2), le routeur redirigeant selon la porte ; si la porte reste `inscription`, on revient ici avec un message et
/// deux issues (reessayer, se deconnecter).
///
/// **Candidat enseignant (CAND-04), avec ou sans code d'invitation.** Le meme
/// recapitulatif ajoute le telephone, le choix de la langue de l'application
/// (deux cartes, la langue active est deja retenue) et la case de la politique
/// de confidentialite ; la creation passe par `inscrire_candidat`
/// (`PortInscriptionCandidat`). Le serveur y repond de la meme facon au succes
/// et au depassement du plafond horaire (CAND-F03) : l'ecran ne les distingue
/// donc pas, il relit la session et laisse le routeur dire si le compte
/// existe. Il ne dit jamais qu'une adresse ou un telephone est deja connu.
class RecapitulatifEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const RecapitulatifEtape({super.key});

  @override
  ConsumerState<RecapitulatifEtape> createState() => _RecapitulatifEtapeState();
}

class _RecapitulatifEtapeState extends ConsumerState<RecapitulatifEtape> {
  static const String _route = Routes.inscriptionRecapitulatif;

  final FocusNode _focusCase = FocusNode();

  /// Les reponses du recapitulatif : quand le serveur refuse un champ, la page
  /// les ramene a l'ecran, avec leurs « Modifier ».
  final GlobalKey _cleLignes = GlobalKey();

  bool _envoi = false;
  String? _erreur;

  /// Candidat : l'inscription sans code n'est pas (ou plus) ouverte. Aucun
  /// bouton plein : il ne pourrait pas aboutir ; un lien mene au code.
  bool _fermee = false;

  /// Candidat : la case de confidentialite manque a la derniere tentative.
  bool _caseManquante = false;

  /// Candidat : la derniere tentative a echoue sans rien creer de sur ; le
  /// bouton dit « Reessayer ».
  bool _reessayer = false;

  @override
  void dispose() {
    _focusCase.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    if (_envoi) {
      return;
    }
    final BrouillonInscription brouillon = ref.read(
      brouillonInscriptionProvider,
    );
    final UsageInscription? usage = brouillon.usage;
    if (usage == null) {
      return;
    }
    if (usage == UsageInscription.comptable) {
      await _creerComptable(brouillon);
      return;
    }
    // CAND-04 : l'enseignant est un candidat, avec ou sans code d'invitation.
    if (usage == UsageInscription.enseignant) {
      await _creerCandidat(brouillon);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      if (!brouillon.profilCree) {
        await ref
            .read(serviceDossierProvider)
            .creerProfil(
              role: usage.role,
              prenom: brouillon.prenom,
              nom: brouillon.nom,
              genre: brouillon.genre,
              usage: switch (usage) {
                UsageInscription.moi => UsageTitulaire.moi,
                UsageInscription.famille => UsageTitulaire.famille,
                UsageInscription.enseignant ||
                UsageInscription.comptable => null,
              },
              suitDesCours:
                  usage == UsageInscription.moi ||
                  brouillon.parentSuitDesCours == true,
            );
        ref.read(brouillonInscriptionProvider.notifier).noterProfilCree();
      }
    } on Object {
      _echec(t.inscription.erreur);
      return;
    }
    await _actualiserPuisAller(Routes.attente);
  }

  /// Lot F2 : l'inscription du comptable invite, par
  /// `inscrire_comptable_invite` a la place de `creer_profil_inscription`.
  /// Le serveur consomme le code avec la creation du profil, actif d'emblee :
  /// l'arrivee se fait sur `/comptable`.
  Future<void> _creerComptable(BrouillonInscription brouillon) async {
    final PortInscriptionComptable? port = ref.read(
      portInscriptionComptableProvider,
    );
    final String? code = ref.read(codeComptableRetenuProvider);
    if (!brouillon.profilCree && (port == null || code == null)) {
      context.go(Routes.inscriptionInvitationComptable);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    if (!brouillon.profilCree) {
      final ResultatInscriptionComptable resultat;
      try {
        resultat = await port!.inscrire(
          code: code!,
          prenom: brouillon.prenom,
          nom: brouillon.nom,
          genre: brouillon.genre?.valeurSql,
        );
      } on Object {
        _echec(t.inscription.erreur);
        return;
      }
      if (resultat != ResultatInscriptionComptable.consommee) {
        // Aucun profil n'a ete cree : le code est oublie (K-59).
        ref.read(codeComptableRetenuProvider.notifier).oublier();
        _echec(t.inscription.erreurInvitation);
        return;
      }
      ref.read(brouillonInscriptionProvider.notifier).noterProfilCree();
      ref.read(codeComptableRetenuProvider.notifier).oublier();
    }
    await _actualiserPuisAller(Routes.comptable);
  }

  /// CAND-04 : l'inscription du candidat enseignant, par `inscrire_candidat`.
  ///
  /// Deux portes, un compte : le code d'invitation retenu, ou « Deposer ma
  /// candidature » (sans code, seulement quand le serveur l'ouvre). Ni l'un ni
  /// l'autre : le champ du code, comme avant. La case de confidentialite est
  /// exigee ici, a l'ecran, et le serveur la revérifie a la version attendue.
  Future<void> _creerCandidat(BrouillonInscription brouillon) async {
    final String? code = ref.read(codeInvitationRetenuProvider);
    if (code == null && !brouillon.sansCode) {
      context.go(Routes.inscriptionInvitation);
      return;
    }
    final Genre? genre = brouillon.genre;
    final String? telephone = brouillon.telephone;
    if (genre == null || telephone == null || !brouillon.identiteComplete) {
      context.go(brouillon.premiereEtapeManquante);
      return;
    }
    if (!brouillon.confidentialiteAcceptee) {
      setState(() => _caseManquante = true);
      _focusCase.requestFocus();
      return;
    }
    final PortInscriptionCandidat? port = ref.read(
      portInscriptionCandidatProvider,
    );
    if (port == null) {
      _echec(t.inscription.candidat.indisponible);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _fermee = false;
      _caseManquante = false;
    });
    // La version que la case accepte est celle de ce texte, compile dans
    // l'application. Si le serveur en attend une autre, on ne l'envoie pas
    // (le serveur la refuserait) et on le dit tout de suite. Une lecture qui
    // echoue ne bloque rien : le serveur reste juge a l'envoi.
    ref.invalidate(ouvertureInscriptionCandidatProvider);
    final OuvertureInscriptionCandidat? ouverture = await ref.read(
      ouvertureInscriptionCandidatProvider.future,
    );
    final String? attendue = ouverture?.versionConfidentialite;
    if (!mounted) {
      return;
    }
    if (attendue != null && attendue != VersionsJuridiques.version) {
      _echec(t.inscription.candidat.confidentialitePerimee, reessayer: false);
      return;
    }
    final ResultatInscriptionCandidat resultat;
    try {
      resultat = await port.inscrire(
        code: code,
        prenom: brouillon.prenom,
        nom: brouillon.nom,
        genre: genre.valeurSql,
        telephone: telephone,
        // La langue de l'ecran, jamais deduite d'ailleurs.
        langue: LocaleSettings.currentLocale == AppLocale.ar ? 'ar' : 'fr',
        // La version du texte que la case affiche et que la personne peut lire.
        versionConfidentialite: VersionsJuridiques.version,
      );
    } on PermissionInsuffisante {
      // Une session qui a deja un profil : il n'y a rien a creer, la suite est
      // le portail. Si le routeur renvoie ici, le message le dit.
      ref.read(brouillonInscriptionProvider.notifier).noterInscriptionEnvoyee();
      await _actualiserPuisAller(
        Routes.attente,
        echec: t.inscription.candidat.nonConfirmee,
      );
      return;
    } on CapaciteIndisponible {
      // Le lot serveur CAND-L3 n'est pas encore verse. L'invite, lui, ne doit
      // pas etre bloque : son code passe par l'ancien chemin (profil cree avec
      // le code), sans telephone ni langue. Sans code, il n'y a rien d'autre.
      if (code != null) {
        await _creerInviteSansLot(brouillon, code);
        return;
      }
      _echec(t.inscription.candidat.indisponible, reessayer: false);
      return;
    } on HorsLigneCandidature {
      // D5 : ce qui a ete envoye est non confirme.
      _echec(t.inscription.candidat.nonConfirmee);
      return;
    } on Object {
      _echec(t.inscription.candidat.creationEchec);
      return;
    }
    if (!mounted) {
      return;
    }
    switch (resultat) {
      case InscriptionAcceptee():
        // Aucun signe de plus : au-dela du plafond horaire, le serveur rend
        // exactement cette reponse sans rien creer (CAND-F03). Seule la
        // relecture de la session dit si le compte existe.
        ref
            .read(brouillonInscriptionProvider.notifier)
            .noterInscriptionEnvoyee();
        await _confirmerNomLatin(brouillon);
        // Le code reste retenu tant que la session n'a pas confirme le compte :
        // si la relecture echoue, « Reessayer » rejoue l'envoi avec ce code
        // (un compte deja cree repond 42501, donc la suite) au lieu de renvoyer
        // la personne au champ du code. Il est oublie des que la session est lue.
        await _actualiserPuisAller(
          Routes.attente,
          echec: t.inscription.candidat.nonConfirmee,
          apres: ref.read(codeInvitationRetenuProvider.notifier).oublier,
        );
      case InscriptionFermee():
        setState(() {
          _envoi = false;
          _fermee = true;
          _erreur = t.inscription.candidat.nonOuverte;
        });
      case InscriptionCourrielNonConfirme():
        _echec(t.inscription.candidat.courrielAConfirmer);
      case InscriptionCodeInconnu() ||
          InscriptionCodeDejaUtilise() ||
          InscriptionCodeExpire():
        // Aucun compte n'a ete cree : le code est oublie, le candidat en
        // demande un nouveau (K-59 : ce qui manque, pourquoi, quoi faire).
        ref.read(codeInvitationRetenuProvider.notifier).oublier();
        _echec(t.inscription.erreurInvitation, reessayer: false);
      case InscriptionInvalide(:final List<String> champs):
        _echec(
          t.inscription.candidat.aCorriger(champs: _nomsDesChamps(champs)),
          reessayer: false,
        );
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          final BuildContext? lignes = _cleLignes.currentContext;
          if (mounted && lignes != null && lignes.mounted) {
            Scrollable.ensureVisible(lignes);
          }
        });
      case InscriptionConfidentialiteRequise():
        // L'ecran a deja exige la case : ce refus n'est pas un texte perime.
        _echec(t.inscription.candidat.creationEchec, reessayer: false);
      case InscriptionConfidentialitePerimee():
        _echec(t.inscription.candidat.confidentialitePerimee, reessayer: false);
      case InscriptionConfidentialiteIndisponible():
        _echec(t.inscription.candidat.indisponible, reessayer: false);
    }
  }

  /// Envoie le nom en lettres latines que la personne a confirme a l'etape
  /// d'identite (decision du directeur du 23/10/2026), une fois la candidature
  /// creee. **Au mieux** : un echec (reseau, plafond horaire sans compte, lot
  /// serveur absent) ne bloque rien ; le nom reste « a confirmer » et la Salle
  /// d'examen le redemande. Le serveur ne translittere jamais : seul le texte
  /// confirme part.
  Future<void> _confirmerNomLatin(BrouillonInscription brouillon) async {
    final String? nomLatin = brouillon.nomLatinAEnvoyer;
    final PortNomLatin? port = ref.read(portNomLatinProvider);
    if (nomLatin == null || port == null) {
      return;
    }
    try {
      await port.confirmer(nomLatin);
    } on Object {
      // Voir ci-dessus : la Salle d'examen le redemandera.
    }
  }

  /// Repli de l'invite tant que `inscrire_candidat` n'est pas sur le serveur :
  /// le chemin d'avant (`creer_profil_inscription` avec le code d'invitation).
  Future<void> _creerInviteSansLot(
    BrouillonInscription brouillon,
    String code,
  ) async {
    try {
      if (!brouillon.profilCree) {
        await ref
            .read(serviceDossierProvider)
            .creerProfil(
              role: AppRole.teacher,
              prenom: brouillon.prenom,
              nom: brouillon.nom,
              genre: brouillon.genre,
              codeInvitation: code,
              suitDesCours: false,
            );
        ref.read(brouillonInscriptionProvider.notifier).noterProfilCree();
        ref.read(codeInvitationRetenuProvider.notifier).oublier();
      }
    } on InvitationNonConsommee {
      ref.read(codeInvitationRetenuProvider.notifier).oublier();
      _echec(t.inscription.erreurInvitation, reessayer: false);
      return;
    } on Object {
      _echec(t.inscription.erreur);
      return;
    }
    await _actualiserPuisAller(Routes.attente);
  }

  /// Les champs refuses par le serveur, nommes comme a l'ecran.
  String _nomsDesChamps(List<String> champs) {
    final List<String> noms = <String>[
      for (final String c in champs)
        switch (c) {
          'prenom' => t.inscription.prenom,
          'nom' => t.inscription.nom,
          'genre' => t.inscription.recap.genre,
          'telephone' => t.inscription.recap.telephone,
          'langue' => t.inscription.recap.langue,
          _ => c,
        },
    ];
    return noms.join(
      LocaleSettings.currentLocale == AppLocale.ar ? '، ' : ', ',
    );
  }

  void _echec(String message, {bool reessayer = true}) {
    if (mounted) {
      setState(() {
        _envoi = false;
        _erreur = message;
        _reessayer = reessayer;
      });
    }
  }

  /// Relit la session puis va a [destination] ; le routeur decide, selon la
  /// porte, si la personne y entre. [echec] remplace le message d'une session
  /// qui ne se rafraichit pas (le candidat ne sait pas encore si son compte
  /// existe, le tuteur oui).
  Future<void> _actualiserPuisAller(
    String destination, {
    String? echec,
    VoidCallback? apres,
  }) async {
    try {
      // Le role et le foyer sont injectes dans le jeton par le hook de la base :
      // le jeton emis avant la creation ne les porte pas encore.
      await ref.read(sourceSessionProvider).rafraichir();
    } on Object {
      _echec(echec ?? t.inscription.erreurActualisation);
      return;
    }
    if (mounted) {
      apres?.call();
      setState(() => _envoi = false);
      context.go(destination);
    }
  }

  void _modifier(String route) => context.go(
    Uri(
      path: route,
      queryParameters: <String, String>{parametreModifier: '1'},
    ).toString(),
  );

  /// Le telephone tel que la personne le relit : « +33 612345678 », isole pour
  /// rester dans le bon sens en arabe.
  String _telephoneAffiche(BrouillonInscription brouillon) {
    final String? international = brouillon.telephone;
    final String? code = brouillon.indicatif;
    if (international == null || code == null) {
      return '';
    }
    return '\u2066+$code ${international.substring(code.length + 1)}\u2069';
  }

  @override
  Widget build(BuildContext context) {
    final BrouillonInscription brouillon = ref.watch(
      brouillonInscriptionProvider,
    );
    exigerEtapesPrecedentes(context, brouillon, _route);
    // Le candidat peut changer la langue de l'application ici meme : la page se
    // reconstruit quand la langue change, pour que chaque texte suive.
    TranslationProvider.of(context);
    final bool candidat = brouillon.usage == UsageInscription.enseignant;
    // Le candidat ne cree rien hors ligne : le bouton n'est pas rendu et une
    // phrase dit quand ce sera possible (jamais un bouton grise).
    final bool horsLigne =
        candidat && (ref.watch(horsLigneProvider).value ?? false);
    final String? erreur =
        _erreur ??
        (candidat
            ? (brouillon.inscriptionEnvoyee && !_envoi
                  ? t.inscription.candidat.creationEchec
                  : null)
            : (brouillon.profilCree && !_envoi
                  ? t.inscription.erreurActualisation
                  : null));

    // Le profil deja cree ne se modifie plus d'ici : « Modifier » n'est pas
    // rendu (jamais grise, BOUTONS-GRISES-1) ; l'erreur d'actualisation et
    // « Reessayer » disent la suite. Pendant l'envoi, il ne repart pas. Le
    // candidat, lui, n'a rien de cree tant que la session n'a pas de profil :
    // il peut corriger.
    final bool figee = candidat ? false : brouillon.profilCree;
    Widget? modifier(String route, String cle) => figee
        ? null
        : ActionPrincipale(
            key: Key(cle),
            libelle: t.inscription.modifier,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: _envoi ? null : () => _modifier(route),
          );

    final bool refaire = candidat
        ? (_reessayer || brouillon.inscriptionEnvoyee)
        : brouillon.profilCree;
    final Widget lignes = KeyedSubtree(
      key: _cleLignes,
      child: GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: brouillon.usage == UsageInscription.famille
                ? AppIcons.foyer
                : AppIcons.profil,
            libelle: t.inscription.recap.usage,
            legende: switch (brouillon.usage) {
              UsageInscription.moi => t.inscription.usage.moiTitre,
              UsageInscription.famille => t.inscription.usage.familleTitre,
              UsageInscription.enseignant => t.inscription.recap.enseignant,
              UsageInscription.comptable => t.inscription.recap.comptable,
              null => '',
            },
            controle: modifier(
              Routes.inscriptionUsage,
              'inscription-modifier-usage',
            ),
          ),
          // L5-01 : la reponse « Suivez-vous aussi des cours ? » est montree
          // avant l'envoi, et part avec le profil.
          if (brouillon.usage == UsageInscription.famille &&
              brouillon.parentSuitDesCours != null)
            LigneRubrique(
              icone: AppIcons.livreOuvert,
              libelle: t.inscription.recap.cours,
              legende: brouillon.parentSuitDesCours!
                  ? t.inscription.recap.coursOui
                  : t.inscription.recap.coursNon,
              controle: modifier(
                Routes.inscriptionUsage,
                'inscription-modifier-cours',
              ),
            ),
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.inscription.recap.identite,
            legende: '${brouillon.prenom} ${brouillon.nom}',
            controle: modifier(
              Routes.inscriptionIdentite,
              'inscription-modifier-identite',
            ),
          ),
          if (candidat && brouillon.nomLatinAEnvoyer != null)
            LigneRubrique(
              icone: AppIcons.profil,
              libelle: t.inscription.nomLatin.libelle,
              legende: isolerSens(brouillon.nomLatinAEnvoyer!),
              controle: modifier(
                Routes.inscriptionIdentite,
                'inscription-modifier-nom-latin',
              ),
            ),
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.inscription.recap.genre,
            legende: switch (brouillon.genre) {
              Genre.femme => t.inscription.genreFemme,
              Genre.homme => t.inscription.genreHomme,
              null => '',
            },
            controle: modifier(
              Routes.inscriptionGenre,
              'inscription-modifier-genre',
            ),
          ),
          if (candidat)
            LigneRubrique(
              icone: AppIcons.appareil,
              libelle: t.inscription.recap.telephone,
              legende: _telephoneAffiche(brouillon),
              controle: modifier(
                Routes.inscriptionTelephone,
                'inscription-modifier-telephone',
              ),
            ),
        ],
      ),
    );

    return CoquilleEtape(
      route: _route,
      question: t.inscription.recapitulatif,
      libelleAction: candidat && (_fermee || horsLigne)
          ? null
          : (refaire
                ? t.inscription.reessayer
                : (candidat
                      ? t.inscription.candidat.envoyer
                      : t.inscription.creer)),
      onAction: brouillon.usage == null ? null : _creer,
      onRetour: _envoi || figee
          ? null
          : () => reculerDepuis(context, _route, usage: brouillon.usage),
      enCours: _envoi,
      souscription: horsLigne
          ? const _NoteHorsLigne()
          : (erreur == null ? null : ErreurEtape(message: erreur)),
      complement: candidat && _fermee
          ? Center(
              child: LienFleche(
                key: const Key('inscription-recap-code'),
                libelle: t.inscription.usage.enseignant,
                onPress: () => context.go(Routes.inscriptionInvitation),
              ),
            )
          : null,
      enfant: candidat
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                lignes,
                Ecart.vLg,
                Text(
                  t.inscription.candidat.ensuite,
                  key: const Key('inscription-recap-ensuite'),
                  style: AppPalette.of(context).inkMuted.applyTo(
                    Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vXxl,
                _ChoixLangue(enCours: _envoi),
                Ecart.vXxl,
                _Confidentialite(
                  cochee: brouillon.confidentialiteAcceptee,
                  manquante:
                      _caseManquante && !brouillon.confidentialiteAcceptee,
                  focusNode: _focusCase,
                  enCours: _envoi,
                  onChanged: (bool v) {
                    ref
                        .read(brouillonInscriptionProvider.notifier)
                        .accepterConfidentialite(acceptee: v);
                    if (v && _caseManquante) {
                      setState(() => _caseManquante = false);
                    }
                  },
                ),
              ],
            )
          : lignes,
    );
  }
}

/// Le choix de la langue de l'application : deux cartes, la langue active est
/// deja retenue (deduite, jamais imposee). Toucher une carte change la langue
/// de l'ecran tout de suite ; c'est cette langue que le serveur reçoit.
class _ChoixLangue extends StatelessWidget {
  const _ChoixLangue({required this.enCours});

  final bool enCours;

  /// La cle du groupe de cartes (tests).
  static const Key groupeKey = ValueKey<String>('inscription-langue');

  /// La cle de la carte d'une langue (tests).
  static Key carteKey(String code) =>
      ValueKey<String>('inscription-langue-$code');

  @override
  Widget build(BuildContext context) {
    final r = t.inscription.langue;
    final String active = LocaleSettings.currentLocale == AppLocale.ar
        ? 'ar'
        : 'fr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TitreChamp(r.question, style: Theme.of(context).textTheme.titleMedium),
        Ecart.vMd,
        IgnorePointer(
          ignoring: enCours,
          child: ChoiceCardGroup(
            key: groupeKey,
            autoriserSaisieLibre: false,
            coteACote: true,
            valeurInitiale: ReponseChoix(valeurs: <String>{active}),
            options: <OptionChoix>[
              OptionChoix(
                cle: carteKey('fr'),
                valeur: 'fr',
                libelle: r.francais,
                explication: r.francaisExplication,
                exemple: r.francaisExemple,
              ),
              OptionChoix(
                cle: carteKey('ar'),
                valeur: 'ar',
                libelle: r.arabe,
                explication: r.arabeExplication,
                exemple: r.arabeExemple,
              ),
            ],
            onChange: (ReponseChoix reponse) {
              // L'arabe est une bibliotheque chargee a la demande : le
              // changement est asynchrone, l'ecran se reconstruit a son arrivee.
              if (reponse.valeurs.contains('ar') && active != 'ar') {
                unawaited(LocaleSettings.setLocale(AppLocale.ar));
              } else if (reponse.valeurs.contains('fr') && active != 'fr') {
                unawaited(LocaleSettings.setLocale(AppLocale.fr));
              }
            },
          ),
        ),
      ],
    );
  }
}

/// La politique de confidentialite : un lien pour la lire, puis la case, jamais
/// precochee, juste au-dessus du bouton. La version que le serveur recoit est
/// celle du texte que le lien ouvre (`VersionsJuridiques`).
class _Confidentialite extends StatelessWidget {
  const _Confidentialite({
    required this.cochee,
    required this.manquante,
    required this.focusNode,
    required this.enCours,
    required this.onChanged,
  });

  final bool cochee;
  final bool manquante;
  final FocusNode focusNode;
  final bool enCours;
  final ValueChanged<bool> onChanged;

  /// La cle de la case (tests).
  static const Key caseKey = ValueKey<String>('inscription-confidentialite');

  /// La cle du lien vers la politique (tests).
  static const Key lienKey = ValueKey<String>(
    'inscription-confidentialite-lire',
  );

  /// La cle de la ligne qui dit la version du texte (tests).
  static const Key versionKey = ValueKey<String>(
    'inscription-confidentialite-version',
  );

  @override
  Widget build(BuildContext context) {
    final r = t.inscription.confidentialite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LienFleche(
          key: lienKey,
          libelle: r.lire,
          alignerEnDebut: true,
          onPress: () =>
              GoRouter.of(context).push(TexteJuridique.confidentialite.chemin),
        ),
        // La version que la case accepte, celle que le lien ouvre et celle que
        // le serveur recoit : une seule (`VersionsJuridiques`).
        Text(
          ligneVersionJuridique(),
          key: versionKey,
          textAlign: TextAlign.center,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        CaseAccordTexte(
          key: caseKey,
          libelle: r.kCase,
          cochee: cochee,
          focusNode: focusNode,
          onChanged: enCours ? null : onChanged,
        ),
        if (manquante) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              r.requise,
              style: AppPalette.of(context).inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// La phrase d'un bouton qui n'est pas rendu hors ligne : ce n'est pas une
/// erreur, elle dit quand l'action sera possible. Le bandeau de la page dit
/// deja que le reseau manque : elle ne le redit pas.
class _NoteHorsLigne extends StatelessWidget {
  const _NoteHorsLigne();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      t.inscription.candidat.horsLigne,
      key: const Key('inscription-note-hors-ligne'),
      textAlign: TextAlign.center,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}

// L'entree des Messages metier dans une page existante (COM-MSG-2 ; spec
// section 3.2, section 14, section 21, section 25).
//
// Pose une fois par le socle (COM-F) dans l'Espace Classe du tuteur
// (`ClasseTuteurPage`), l'Espace Classe enseignant (`FicheGroupePage`),
// Mes classes (`MesClassesPage`) et Ma classe de l'eleve adulte
// (`MaClasseAdultePage`) ; posee par cette voie dans le detail d'un dossier
// (`DetailDossier`, « Ecrire a la famille »). Elle est remplie ici, sans
// rouvrir la page hote (`02_DECOUPAGE`, regle des fichiers 3).
//
// Deux formes, choisies par l'objet que la page hote donne :
//
// - **sur un objet** (une Classe, un dossier) : les conversations que le
//   serveur ouvre sur cet objet (`conversationsPourObjet`, paires de la
//   section 3.2), une ligne par interlocuteur, « Ecrire a la famille »,
//   « Ecrire a l'Administration » ou « Ecrire a Mme Mariam ». Jamais un bloc
//   « Messages » general (02_DEC-11) : le titre dit l'objet ;
// - **sans objet** (Mes classes) : une ligne « Messages metier » qui ouvre la
//   liste, avec le badge des conversations a lire.
//
// Le chemin des Messages se lit sur l'ADRESSE de la page hote (la coquille
// ou elle vit), jamais sur un role : `/enseignant/...` mene a
// `/enseignant/messages`, `/tuteur/...` a `/tuteur/messages`, `/admin/...` a
// l'onglet Messages de l'Administration des communications. Ailleurs (une
// demonstration, un hote de test sans routeur) l'entree ne rend rien.
//
// Etats (spec section 25) : chargement (squelette), contenu, vide (rien n'est
// rendu : aucune section vide decorative), erreur (« Reessayer »), hors ligne
// (« Reessayer »), capacite indisponible (port neutre de production : rien
// n'est rendu, la page hote reste celle d'avant COM-MSG-2), et a l'ouverture
// d'une conversation : fil inaccessible (le serveur refuse la paire, rien du
// fil n'est montre) ou ouverture en echec. Les ecarts de la page hote
// ([ecartAvant], [ecartApres]) ne sont poses que si quelque chose est rendu.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/capacites_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'port_messages_metier.dart';

/// Le nombre de conversations rendues sur un objet ; au-dela, « Voir toutes
/// les conversations » ouvre la liste.
const int limiteConversationsEntree = 5;

/// Le chemin de la liste des Messages pour la page a l'adresse [chemin], ou
/// `null` si cette page ne vit dans aucune coquille qui en a.
///
/// Lu sur l'adresse (la coquille), jamais sur un role (CLAUDE.md).
String? cheminMessagesDepuis(String chemin) {
  bool sous(String racine) => chemin == racine || chemin.startsWith('$racine/');
  if (sous('/enseignant')) return Routes.enseignantMessages;
  if (sous(Routes.tuteurAccueil)) return Routes.tuteurMessages;
  if (sous(Routes.admin)) return Routes.adminCommunicationsMessages;
  return null;
}

/// L'emplacement d'entree des Messages metier dans une page existante.
///
/// **Contrat d'ecart, fixe par le socle** : c'est la page hote qui dit de
/// quel cote l'ecart se pose et lequel ([ecartAvant], [ecartApres]) ; il
/// n'est rendu que si l'entree rend quelque chose.
///
/// [type] et [objetId] disent de quoi parle l'entree (la Classe ou le dossier
/// affiche) ; tous deux nuls : l'entree generale d'une liste (Mes classes).
/// Ce sont des identifiants, jamais une autorisation : le port decide
/// (COM-BR-01).
class EntreeMessagesContexte extends ConsumerStatefulWidget {
  /// Cree l'emplacement.
  const EntreeMessagesContexte({
    super.key,
    this.type,
    this.objetId,
    this.ecartAvant,
    this.ecartApres,
  }) : assert(
         (type == null) == (objetId == null),
         'Un objet lie porte son type et son identifiant, ou aucun des deux.',
       );

  /// La nature de l'objet de la page hote.
  final TypeObjetLie? type;

  /// L'identifiant de l'objet de la page hote.
  final String? objetId;

  /// L'ecart a poser avant le contenu (emplacement en fin de section), ou
  /// `null`. Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartAvant;

  /// L'ecart a poser apres le contenu (emplacement en tete), ou `null`.
  /// Jamais rendu tant que l'emplacement est vide.
  final Widget? ecartApres;

  /// La cle de l'entree generale (sans objet), pour les tests.
  static const ValueKey<String> cleGenerale = ValueKey<String>(
    'entree-messages-generale',
  );

  /// La cle du groupe des conversations d'un objet, pour les tests.
  static const ValueKey<String> cleObjet = ValueKey<String>(
    'entree-messages-objet',
  );

  /// La cle de l'etat rendu sous le groupe apres une ouverture refusee ou en
  /// echec, pour les tests.
  static const ValueKey<String> cleEchec = ValueKey<String>(
    'entree-messages-echec',
  );

  @override
  ConsumerState<EntreeMessagesContexte> createState() =>
      _EntreeMessagesContexteState();
}

/// Ce qui est arrive a la derniere ouverture d'une conversation.
enum _Echec {
  /// Le serveur refuse la paire : le fil est absent (R-COM-02).
  inaccessible,

  /// La lecture a echoue (reseau, serveur).
  erreur,

  /// Le port n'a pas encore de contrat.
  indisponible,
}

class _EntreeMessagesContexteState
    extends ConsumerState<EntreeMessagesContexte> {
  AsyncValue<List<ConversationPossible>> _conversations =
      const AsyncValue<List<ConversationPossible>>.loading();
  AsyncValue<IndicateurAttention> _attention =
      const AsyncValue<IndicateurAttention>.loading();

  /// La cle de la conversation en cours d'ouverture : la paire (objet,
  /// interlocuteur), [ConversationPossible.cle], jamais l'objet seul.
  String? _ouverture;
  _Echec? _echec;

  /// La derniere conversation demandee, que « Reessayer » rouvre.
  ConversationPossible? _derniere;

  PortMessagesMetier get _port => ref.read(portMessagesMetierProvider);

  bool get _general => widget.type == null;

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  @override
  void didUpdateWidget(EntreeMessagesContexte ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.type != widget.type || ancien.objetId != widget.objetId) {
      // Le build suit : aucun setState ici, l'etat repart du chargement.
      _echec = null;
      _ouverture = null;
      _derniere = null;
      _conversations = const AsyncValue<List<ConversationPossible>>.loading();
      _attention = const AsyncValue<IndicateurAttention>.loading();
      unawaited(_charger());
    }
  }

  Future<void> _charger() async {
    final TypeObjetLie? type = widget.type;
    final String? objetId = widget.objetId;
    if (type == null || objetId == null) {
      if (!_attention.isLoading) {
        setState(
          () => _attention = const AsyncValue<IndicateurAttention>.loading(),
        );
      }
      final AsyncValue<IndicateurAttention> lue =
          await AsyncValue.guard<IndicateurAttention>(() async {
            IndicateurAttention total = IndicateurAttention.aucun;
            for (final ResumeFil f in await _port.fils()) {
              if (estFilMetier(f)) total = total.fusionner(f.attention);
            }
            return total;
          });
      if (mounted && widget.type == null) setState(() => _attention = lue);
      return;
    }
    if (!_conversations.isLoading) {
      setState(
        () => _conversations =
            const AsyncValue<List<ConversationPossible>>.loading(),
      );
    }
    final AsyncValue<List<ConversationPossible>> lues =
        await AsyncValue.guard<List<ConversationPossible>>(
          () => _port.conversationsPourObjet(type, objetId),
        );
    if (!mounted || widget.type != type || widget.objetId != objetId) return;
    setState(() => _conversations = lues);
  }

  /// Le chemin de la liste des Messages, lu sur l'adresse de la page hote.
  String? _cheminMessages(BuildContext context) {
    if (GoRouter.maybeOf(context) == null) return null;
    final String chemin;
    try {
      chemin = GoRouterState.of(context).uri.path;
    } on Object {
      return null;
    }
    return cheminMessagesDepuis(chemin);
  }

  Future<void> _ouvrir(ConversationPossible c, String liste) async {
    if (_ouverture != null) return;
    _derniere = c;
    final String? existant = c.filId;
    if (existant != null) {
      setState(() => _echec = null);
      GoRouter.of(context).go('$liste/${Uri.encodeComponent(existant)}');
      return;
    }
    setState(() {
      _ouverture = c.cle;
      _echec = null;
    });
    final FilMetier? fil;
    try {
      // Ouvert a la demande de la personne, jamais au rendu : le serveur cree
      // le fil s'il manque, et seulement pour une paire autorisee. La paire
      // (objet, interlocuteur), jamais l'objet seul : l'Administration et
      // l'enseignant peuvent partager une Classe (spec section 3.2).
      fil = await _port.ouvrirConversation(c);
    } on CapaciteIndisponible {
      if (mounted) {
        setState(() {
          _ouverture = null;
          _echec = _Echec.indisponible;
        });
      }
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _ouverture = null;
          _echec = _Echec.erreur;
        });
      }
      return;
    }
    if (!mounted) return;
    if (fil == null) {
      setState(() {
        _ouverture = null;
        _echec = _Echec.inaccessible;
      });
      return;
    }
    setState(() => _ouverture = null);
    GoRouter.of(context).go('$liste/${Uri.encodeComponent(fil.id)}');
  }

  @override
  Widget build(BuildContext context) {
    final String? liste = _cheminMessages(context);
    if (liste == null) return const SizedBox.shrink();
    final Widget? contenu = _general
        ? _entreeGenerale(liste)
        : _entreeObjet(liste);
    if (contenu == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[?widget.ecartAvant, contenu, ?widget.ecartApres],
      ),
    );
  }

  /// La ligne « Messages metier » d'une liste (Mes classes) : elle ouvre la
  /// liste des fils, avec le badge des conversations a lire quand il est lu.
  Widget? _entreeGenerale(String liste) {
    final Object? erreur = _attention.error;
    // Port neutre (production) : aucune entree vers un ecran indisponible.
    if (_attention.hasError && erreur is CapaciteIndisponible) return null;
    final IndicateurAttention attention =
        (_attention.hasValue ? _attention.value : null) ??
        IndicateurAttention.aucun;
    final e = t.com.messages.entree;
    final String legende = switch (attention.nonLus) {
      0 => e.toutes,
      1 => e.aLireUne,
      final int n => e.aLire(nombre: n),
    };
    return GroupeReglages(
      key: EntreeMessagesContexte.cleGenerale,
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.discussion,
          libelle: t.com.messages.titre,
          legende: legende,
          marque: attention.estVisible
              ? BadgeNonLu(indicateur: attention, compact: true)
              : null,
          onPress: () => GoRouter.of(context).go(liste),
        ),
      ],
    );
  }

  /// Les conversations ouvertes sur l'objet de la page, et leurs etats.
  Widget? _entreeObjet(String liste) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // COM-BR-16 : tant que la capacite n'est pas lue (ou en echec), aucune
    // conversation nouvelle ne s'ouvre ; un fil existant reste lisible.
    final bool ecrire =
        ref
            .watch(capacitesCommunicationProvider)
            .value
            ?.peut(CapaciteCommunication.ecrireDansFil) ??
        false;
    if (_conversations.isLoading) {
      return const VueEtatCommunication(etat: EtatCommunication.chargement);
    }
    if (_conversations.hasError) {
      final Object erreur = _conversations.error!;
      if (erreur is CapaciteIndisponible) return null;
      return VueEtatCommunication(
        etat: horsLigne
            ? EtatCommunication.horsLigne
            : EtatCommunication.erreur,
        onReessayer: () => unawaited(_charger()),
      );
    }
    final List<ConversationPossible> ouvertes = <ConversationPossible>[
      for (final ConversationPossible c
          in _conversations.value ?? const <ConversationPossible>[])
        if (c.filId != null || ecrire) c,
    ];
    if (ouvertes.isEmpty) return null;
    final List<ConversationPossible> rendues = ouvertes
        .take(limiteConversationsEntree)
        .toList();
    // Pendant une ouverture, le groupe est occupe : aucun toucher n'y passe,
    // et le lecteur d'ecran n'y offre plus d'action (IgnorePointer bloque les
    // actions semantiques). Les lignes ne sont pas grisees (K-56) ; la ligne
    // touchee dit « Ouverture de la conversation ». Au clavier, `_ouvrir`
    // ignore un second appui.
    final bool occupe = _ouverture != null;
    final Widget groupe = IgnorePointer(
      ignoring: occupe,
      child: _groupe(rendues, ouvertes, liste, ecrire: ecrire),
    );
    final Widget? echec = _vueEchec(horsLigne, liste);
    if (echec == null) return groupe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        groupe,
        Ecart.vLg,
        KeyedSubtree(key: EntreeMessagesContexte.cleEchec, child: echec),
      ],
    );
  }

  /// Le groupe des conversations rendues, puis « Voir toutes les
  /// conversations » s'il en reste.
  Widget _groupe(
    List<ConversationPossible> rendues,
    List<ConversationPossible> ouvertes,
    String liste, {
    required bool ecrire,
  }) {
    final e = t.com.messages.entree;
    return GroupeReglages(
      key: EntreeMessagesContexte.cleObjet,
      titre: switch (widget.type) {
        TypeObjetLie.classe => e.titreClasse,
        TypeObjetLie.dossier => e.titreDossier,
        _ => e.titreObjet,
      },
      lignes: <LigneRubrique>[
        for (final ConversationPossible c in rendues)
          _ligne(c, liste, ecrire: ecrire),
        if (ouvertes.length > rendues.length)
          LigneRubrique(
            icone: AppIcons.discussion,
            libelle: e.voirTout,
            onPress: () => GoRouter.of(context).go(liste),
          ),
      ],
    );
  }

  LigneRubrique _ligne(
    ConversationPossible c,
    String liste, {
    required bool ecrire,
  }) {
    final e = t.com.messages.entree;
    final Participant p = c.interlocuteur;
    final bool nommee = !ecrire || c.nature == NatureInterlocuteur.personne;
    final String libelle = !ecrire
        ? e.conversationAvec(nom: p.nomAffiche)
        : switch (c.nature) {
            NatureInterlocuteur.famille => e.ecrireFamille,
            NatureInterlocuteur.administration => e.ecrireAdministration,
            NatureInterlocuteur.personne => e.ecrireA(nom: p.nomAffiche),
          };
    final String? fonction = p.fonction;
    final bool enOuverture = _ouverture == c.cle;
    final String legende = enOuverture
        ? e.ouverture
        : nommee
        ? (fonction ?? c.objet.libelle)
        : fonction == null
        ? p.nomAffiche
        : t.com.messages.noms.avecFonction(
            nom: p.nomAffiche,
            fonction: fonction,
          );
    return LigneRubrique(
      icone: AppIcons.discussion,
      libelle: libelle,
      legende: legende,
      marque: c.attention.estVisible
          ? BadgeNonLu(indicateur: c.attention, compact: true)
          : null,
      onPress: () => unawaited(_ouvrir(c, liste)),
    );
  }

  /// L'etat de la derniere ouverture, sous le groupe ; `null` s'il n'y a
  /// rien a dire.
  Widget? _vueEchec(bool horsLigne, String liste) {
    final ConversationPossible? derniere = _derniere;
    final e = t.com.messages.entree;
    return switch (_echec) {
      null => null,
      // Rien du fil refuse n'est montre : ni nom, ni objet, ni message.
      _Echec.inaccessible => EtatSysteme(
        nature: NatureEtat.accesRefuse,
        titre: e.inaccessibleTitre,
        phrase: e.inaccessible,
        dependance: 'COM-BR-01',
      ),
      _Echec.erreur => EtatSysteme(
        nature: horsLigne ? NatureEtat.horsLigne : NatureEtat.echecServeur,
        titre: e.erreurOuvertureTitre,
        phrase: e.ouvertureEchouee,
        // Spec section 22 : une erreur ou le hors ligne offrent « Reessayer »,
        // qui rouvre la meme conversation.
        onAction: derniere == null
            ? null
            : () => unawaited(_ouvrir(derniere, liste)),
      ),
      _Echec.indisponible => const VueEtatCommunication(
        etat: EtatCommunication.indisponible,
        dependance: 'COM-BR-01',
      ),
    };
  }
}

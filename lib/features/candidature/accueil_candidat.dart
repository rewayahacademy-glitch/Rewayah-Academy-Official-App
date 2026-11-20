// PE-B4 (directeur, 19/11/2026, PLAN arbitrage A9) : l'accueil du candidat
// enseignant, a trois onglets : Dossier, Messages, Academie. Decisions du
// directeur du 20/11/2026 : la barre est celle de l'application ; l'onglet
// Messages y montre seulement le nombre de messages recus non lus ; dans
// Messages, trois rubriques (Messages, Annonces, A savoir).
//
// La page d'attente (`/attente`, `AttentePage`) lui delegue tout candidat
// enseignant ; les familles, l'eleve adulte et le compte suspendu gardent la
// page d'avant.
//
// Navigation (contrat du 20/11/2026) :
// - la barre est celle de l'application (`NavShell` : capsule flottante au
//   telephone, colonne sur tablette et ordinateur), jamais recomposee ;
// - l'onglet est dans l'adresse (`/attente`, `/attente?onglet=messages`,
//   `/attente?onglet=academie`) : recharger rend le meme ecran, et le retour
//   du navigateur revient a l'onglet d'avant. Changer d'onglet remplace (on
//   change de rubrique), sans empiler ;
// - toucher l'onglet deja ouvert ramene en haut de sa page.
//
// Etats : le premier chargement et l'etat illisible sont ceux de la page
// d'attente (inchanges). Ici : contenu ; relecture en echec ou hors connexion
// (ce qui est montre reste, une phrase le dit, « Reessayer ») ; chaque onglet
// porte ses etats (annonces, messages).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dossier/etat_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/etat_routeur_sur.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import 'a_savoir_candidat.dart';
import 'annonces_candidat.dart';
import 'messages_candidat.dart';
import 'onglet_academie.dart';
import 'onglet_dossier.dart';

/// Les trois onglets de l'accueil du candidat.
enum OngletCandidat {
  /// Ou en est la candidature.
  dossier(null),

  /// La conversation, les annonces, ce qu'il faut savoir.
  messages('messages'),

  /// Partager, autres talents, reglages (question ouverte au directeur).
  academie('academie');

  const OngletCandidat(this.parametre);

  /// La valeur du parametre `onglet` de l'adresse ; nulle pour Dossier.
  final String? parametre;

  /// L'adresse de l'onglet.
  String get chemin => parametre == null
      ? Routes.attente
      : '${Routes.attente}?$cleParametre=$parametre';

  /// Le nom du parametre de l'adresse.
  static const String cleParametre = 'onglet';

  /// L'onglet d'une adresse ; Dossier pour une valeur inconnue.
  static OngletCandidat depuis(String? parametre) {
    for (final OngletCandidat o in values) {
      if (o.parametre == parametre) return o;
    }
    return OngletCandidat.dossier;
  }
}

/// L'accueil du candidat enseignant.
class AccueilCandidat extends ConsumerStatefulWidget {
  /// Cree l'accueil. [etat] porte une valeur (le dossier lu, avec sa
  /// candidature) ; il peut aussi porter l'echec de la derniere relecture.
  const AccueilCandidat({
    required this.etat,
    required this.onRelire,
    super.key,
  });

  /// L'etat du dossier, tel que la page d'attente l'a lu.
  final AsyncValue<EtatDossier> etat;

  /// Relit le dossier et la session.
  final Future<void> Function() onRelire;

  /// La cle du contenu de l'onglet [o].
  static Key cleOnglet(OngletCandidat o) =>
      ValueKey<String>('accueil-candidat-${o.name}');

  /// La cle de la phrase de l'onglet Messages sans messagerie.
  static const Key cleMessagesVide = ConversationCandidat.cleVide;

  /// L'adresse de la rubrique [s] de l'onglet Messages.
  static String cheminMessages(SectionMessages s) => s.parametre == null
      ? OngletCandidat.messages.chemin
      : '${OngletCandidat.messages.chemin}&${SectionMessages.cleParametre}='
            '${s.parametre}';

  @override
  ConsumerState<AccueilCandidat> createState() => _EtatAccueilCandidat();
}

class _EtatAccueilCandidat extends ConsumerState<AccueilCandidat> {
  /// L'onglet d'un hote sans routeur (un test, une galerie).
  OngletCandidat _local = OngletCandidat.dossier;

  /// La rubrique de Messages d'un hote sans routeur.
  SectionMessages _sectionLocale = SectionMessages.messages;

  /// Le defilement de la page : toucher l'onglet ouvert ramene en haut.
  final ScrollController _defilement = ScrollController();

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  OngletCandidat _courant(BuildContext context) {
    final Uri? adresse = adresseRouteurSur(context);
    if (adresse == null) return _local;
    return OngletCandidat.depuis(
      adresse.queryParameters[OngletCandidat.cleParametre],
    );
  }

  SectionMessages _section(BuildContext context) {
    final Uri? adresse = adresseRouteurSur(context);
    if (adresse == null) return _sectionLocale;
    return SectionMessages.depuis(
      adresse.queryParameters[SectionMessages.cleParametre],
    );
  }

  /// Ouvre la rubrique [s] de l'onglet Messages (remplace, sans empiler).
  void _allerSection(SectionMessages s) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) {
      setState(() {
        _local = OngletCandidat.messages;
        _sectionLocale = s;
      });
    } else {
      routeur.go(AccueilCandidat.cheminMessages(s));
    }
  }

  void _aller(OngletCandidat cible) {
    final OngletCandidat courant = _courant(context);
    if (cible == courant) {
      // L'onglet deja ouvert : retour en haut de sa page.
      final ScrollController? page = PrimaryScrollController.maybeOf(context);
      for (final ScrollController c in <ScrollController?>[
        page,
        _defilement,
      ].whereType<ScrollController>()) {
        if (c.hasClients) {
          unawaited(
            c.animateTo(
              0,
              duration: AppMouvement.duree(context, AppMouvement.navigation),
              curve: AppMouvement.entree,
            ),
          );
        }
      }
      return;
    }
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) {
      setState(() => _local = cible);
    } else {
      routeur.go(cible.chemin);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Les libelles viennent de `t.*` : l'accueil se reconstruit quand la
    // langue change.
    TranslationProvider.of(context);
    final EtatDossier dossier = widget.etat.requireValue;
    final OngletCandidat onglet = _courant(context);
    final SectionMessages section = _section(context);
    final o = t.recrutement.accueil.onglets;
    // Le nombre de messages recus non lus, seul, sur l'onglet Messages.
    final int nonLus = ref.watch(messagesNonLusCandidatProvider).value ?? 0;
    final List<Destination> destinations = <Destination>[
      Destination(
        libelle: o.dossier,
        icone: AppIcons.dossiers,
        chemin: OngletCandidat.dossier.chemin,
      ),
      Destination(
        libelle: o.messages,
        icone: AppIcons.discussion,
        chemin: OngletCandidat.messages.chemin,
        compteur: nonLus,
        compteurLu: t.recrutement.accueil.messages.nonLus(n: nonLus),
      ),
      Destination(
        libelle: o.academie,
        icone: AppIcons.apprendre,
        chemin: OngletCandidat.academie.chemin,
      ),
    ];
    Widget borne(Widget enfant) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
        child: KeyedSubtree(
          key: AccueilCandidat.cleOnglet(onglet),
          child: enfant,
        ),
      ),
    );
    final Widget selecteur = SelecteurMessages(
      section: section,
      onChange: _allerSection,
    );
    final Widget page = switch (onglet) {
      // Dossier pose son titre lui-meme, sous l'annonce (maquette).
      OngletCandidat.dossier => PageShell(
        child: borne(
          OngletDossier(
            dossier: dossier,
            // Riverpod garde la derniere valeur quand une relecture echoue.
            perime: widget.etat.hasError,
            onRelire: widget.onRelire,
            onVoirAnnonces: () => _allerSection(SectionMessages.annonces),
          ),
        ),
      ),
      // La conversation remplit la hauteur : le fil defile seul, champ en
      // bas, au-dessus de la barre (comme la page des messages).
      OngletCandidat.messages when section == SectionMessages.messages =>
        PageShell(
          defilante: false,
          child: borne(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                selecteur,
                Ecart.vMd,
                Expanded(
                  child: ConversationCandidat(
                    onReplier: () => _aller(OngletCandidat.dossier),
                  ),
                ),
              ],
            ),
          ),
        ),
      OngletCandidat.messages => PageShell(
        child: borne(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              selecteur,
              Ecart.vLg,
              if (section == SectionMessages.annonces)
                const AnnoncesCandidat()
              else
                const ASavoirCandidat(),
            ],
          ),
        ),
      ),
      OngletCandidat.academie => PageShell(
        titre: t.recrutement.accueil.academie.titre,
        child: borne(
          OngletAcademie(
            candidature: dossier.candidature,
            onRetire: () => _aller(OngletCandidat.dossier),
          ),
        ),
      ),
    };
    return NavShell(
      destinations: destinations,
      indexActif: onglet.index,
      onAller: (String chemin) => _aller(
        OngletCandidat.values.firstWhere(
          (OngletCandidat v) => v.chemin == chemin,
        ),
      ),
      onDeconnexion: () => unawaited(seDeconnecter(context, ref)),
      child: page,
    );
  }
}

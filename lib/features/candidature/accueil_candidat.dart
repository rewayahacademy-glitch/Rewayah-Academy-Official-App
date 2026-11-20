// PE-B4 (directeur, 19/11/2026, PLAN arbitrage A9) : l'accueil du candidat
// enseignant, a trois onglets : Dossier, Messages, Academie.
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

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/ma_candidature_fil.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/etat_routeur_sur.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../com_messages/entree_messages_candidature.dart';
import 'onglet_academie.dart';
import 'onglet_dossier.dart';

/// Les trois onglets de l'accueil du candidat.
enum OngletCandidat {
  /// Ou en est la candidature.
  dossier(null),

  /// La conversation avec l'academie.
  messages('messages'),

  /// Les annonces, ce qu'il faut savoir, les reglages.
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
  static const Key cleMessagesVide = ValueKey<String>(
    'accueil-candidat-messages-vide',
  );

  @override
  ConsumerState<AccueilCandidat> createState() => _EtatAccueilCandidat();
}

class _EtatAccueilCandidat extends ConsumerState<AccueilCandidat> {
  /// L'onglet d'un hote sans routeur (un test, une galerie).
  OngletCandidat _local = OngletCandidat.dossier;

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
    final o = t.recrutement.accueil.onglets;
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
      ),
      Destination(
        libelle: o.academie,
        icone: AppIcons.apprendre,
        chemin: OngletCandidat.academie.chemin,
      ),
    ];
    final Widget contenu = switch (onglet) {
      OngletCandidat.dossier => OngletDossier(
        dossier: dossier,
        // Riverpod garde la derniere valeur quand une relecture echoue.
        perime: widget.etat.hasError,
        onRelire: widget.onRelire,
        onVoirAcademie: () => _aller(OngletCandidat.academie),
      ),
      OngletCandidat.messages => const _OngletMessages(),
      OngletCandidat.academie => OngletAcademie(
        candidature: dossier.candidature,
        onRetire: () => _aller(OngletCandidat.dossier),
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
      child: PageShell(
        titre: switch (onglet) {
          OngletCandidat.dossier => t.attente.titreDossier,
          OngletCandidat.messages => o.messages,
          OngletCandidat.academie => t.recrutement.accueil.academie.titre,
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppPage.largeurReglages,
            ),
            child: KeyedSubtree(
              key: AccueilCandidat.cleOnglet(onglet),
              child: contenu,
            ),
          ),
        ),
      ),
    );
  }
}

/// L'onglet Messages : la conversation du candidat avec l'academie, par
/// l'entree des Messages existante (MESSAGES-CANDIDAT, aucun second circuit).
class _OngletMessages extends ConsumerWidget {
  const _OngletMessages();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> id = ref.watch(maCandidatureIdProvider);
    final m = t.recrutement.accueil.messages;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    // Pas de messagerie pour cette candidature (serveur d'avant, ou aucune
    // candidature enregistree) : une phrase, jamais un onglet vide.
    final bool sans =
        id.error is CapaciteIndisponible || (id.hasValue && id.value == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!id.hasValue && !id.hasError)
          const Skeleton.liste(lignes: 2)
        else if (sans)
          Text(m.vide, key: AccueilCandidat.cleMessagesVide, style: muet)
        else ...<Widget>[
          Text(m.intro, style: muet),
          const EntreeMessagesCandidature(ecartAvant: Ecart.vLg),
        ],
      ],
    );
  }
}

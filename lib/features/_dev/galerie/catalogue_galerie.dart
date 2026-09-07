import 'package:flutter/material.dart';

import '../../../core/i18n/cle_audio.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/planning/service_planning.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/audio_label.dart';
import '../../../core/widgets/avatar_tile.dart';
import '../../../core/widgets/bento_tile.dart';
import '../../../core/widgets/child_card.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/confirm_destructive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/local_feedback.dart';
import '../../../core/widgets/nav_shell.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/page_parcours.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/permanent_notice.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/signal_row.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/widgets/status_pill.dart';
import '../../disponibilites/grille_semaine.dart';

/// Les familles d'etats obligatoires.
///
/// Reprises telles quelles de `docs/design/07-catalogue-composants.md`
/// section 4. Les deux dernieres n'ont pas de liste fixe, et c'est voulu :
///
/// - un **composant d'etat** porte les etats de son metier, qui ne se
///   devinent pas depuis une liste generale ; `ChildCard` en a sept,
///   `StatusPill` en a cinq ;
/// - un composant de **structure** n'est ni un controle ni une zone de
///   donnees : un gabarit de page n'a pas d'etat presse.
///
/// Le test `test/widgets/catalogue_galerie_test.dart` verifie la couverture
/// complete pour les quatre premieres, et se contente d'exiger **au moins deux
/// etats** pour les deux dernieres : « un composant livre avec son seul etat
/// nominal n'est pas fini ».
enum FamilleComposant {
  /// Un controle qu'on presse.
  controleInteractif(<String>[
    'default',
    'hover',
    'pressed',
    'focus',
    'disabled',
    'loading',
  ]),

  /// Une carte qu'on peut retenir.
  carteCliquable(<String>[
    'default',
    'hover',
    'pressed',
    'focus',
    'selected',
    'disabled',
  ]),

  /// Une zone qui affiche des donnees.
  zoneDeDonnees(<String>['loading', 'content', 'empty', 'error', 'offline']),

  /// Un champ de saisie.
  champDeSaisie(<String>[
    'default',
    'focus',
    'filled',
    'error',
    'disabled',
    'readonly',
  ]),

  /// Un composant dont les etats sont ceux de son metier.
  composantEtat(<String>[]),

  /// Un gabarit : ni controle, ni donnees.
  structure(<String>[]);

  const FamilleComposant(this.etatsObligatoires);

  /// Les etats que tout composant de cette famille doit porter.
  final List<String> etatsObligatoires;
}

/// Un etat d'un composant, tel que la galerie le montre.
@immutable
class EtatGalerie {
  /// Cree un etat.
  const EtatGalerie(this.nom, this.construire);

  /// Le nom de l'etat. Un identifiant technique, pas un libelle d'interface :
  /// c'est le vocabulaire du catalogue, et il ne se traduit pas.
  final String nom;

  /// Ce qu'il faut rendre.
  final Widget Function(BuildContext context) construire;
}

/// Un composant du catalogue, et tous ses etats.
@immutable
class EntreeGalerie {
  /// Cree une entree.
  const EntreeGalerie({
    required this.nom,
    required this.famille,
    required this.etats,
  });

  /// Le nom de la classe, tel qu'il est ecrit dans le catalogue.
  final String nom;

  /// La famille d'etats a laquelle le composant appartient.
  final FamilleComposant famille;

  /// Tous ses etats, dans l'ordre ou ils se lisent.
  final List<EtatGalerie> etats;
}

/// Deux creneaux poses, pour la grille de la galerie.
const List<Creneau> _creneauxExemple = <Creneau>[
  Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
  Creneau(jour: 4, heure: 18, fuseau: 'Europe/Paris'),
];

/// Trois destinations, pour les trois formes du chrome de navigation.
///
/// Celles du tuteur, prises telles quelles dans les libelles du produit : une
/// galerie qui inventerait ses propres libelles ne montrerait pas la vraie
/// longueur des mots, et c'est justement ce qui casse un rail.
List<Destination> _destinationsExemple() => <Destination>[
  Destination(
    libelle: t.nav.tuteur.foyer,
    icone: AppIcons.foyer,
    chemin: Routes.tuteurAccueil,
  ),
  Destination(
    libelle: t.nav.tuteur.disponibilites,
    icone: AppIcons.disponibilites,
    chemin: Routes.tuteurDisponibilites,
  ),
  Destination(
    libelle: t.nav.tuteur.reglages,
    icone: AppIcons.reglages,
    chemin: Routes.tuteurReglages,
  ),
];

/// Hauteur allouee a un composant qui prend toute une page.
const double _hauteurPage = AppSpacing.respiration * 6;

/// **Le catalogue, et la preuve du catalogue.**
///
/// `docs/design/07-catalogue-composants.md` section 5 : « Un composant absent
/// de la galerie est un composant dont personne ne peut verifier les etats sans
/// lancer un ecran metier. » Cette liste est donc comparee, par
/// `test/widgets/catalogue_galerie_test.dart`, a la liste des composants du
/// catalogue : un composant ajoute a `lib/core/widgets/` sans entree ici fait
/// echouer la suite.
List<EntreeGalerie> catalogueGalerie() => <EntreeGalerie>[
  // --- Les douze composants P0, dans l'ordre du catalogue -----------------
  EntreeGalerie(
    nom: 'PageShell',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      EtatGalerie(
        'titre + actions',
        (BuildContext _) => const SizedBox(
          height: _hauteurPage,
          child: PageShell(
            titre: 'Aujourd hui',
            actions: ActionPrincipale(
              libelle: 'Poser un creneau',
              onPress: _rien,
            ),
            child: Text('Le corps de la page defile ici.'),
          ),
        ),
      ),
      EtatGalerie(
        'sans titre, avec entete',
        (BuildContext _) => const SizedBox(
          height: _hauteurPage,
          child: PageShell(
            entete: SectionHeader(titre: 'Cette semaine', compteur: 0),
            child: Text('Une page sans titre d ecran.'),
          ),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'NavShell',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      EtatGalerie(
        'trois destinations',
        (BuildContext _) => SizedBox(
          height: _hauteurPage,
          child: NavShell(
            destinations: _destinationsExemple(),
            indexActif: 0,
            onAller: _allerNullePart,
            child: const _SurfaceDemonstration(),
          ),
        ),
      ),
      EtatGalerie(
        'une seule destination : aucun chrome',
        (BuildContext _) => SizedBox(
          height: _hauteurPage,
          child: NavShell(
            destinations: _destinationsExemple().take(1).toList(),
            indexActif: 0,
            onAller: _allerNullePart,
            child: const _SurfaceDemonstration(),
          ),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'AppCard',
    famille: FamilleComposant.carteCliquable,
    etats: <EtatGalerie>[
      EtatGalerie(
        'default',
        (BuildContext _) =>
            const AppCard(onPress: _rien, child: Text('Une carte')),
      ),
      EtatGalerie(
        'hover',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(survole: true),
          child: AppCard(onPress: _rien, child: Text('Une carte')),
        ),
      ),
      EtatGalerie(
        'pressed',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(presse: true),
          child: AppCard(onPress: _rien, child: Text('Une carte')),
        ),
      ),
      EtatGalerie(
        'focus',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(focus: true),
          child: AppCard(onPress: _rien, child: Text('Une carte')),
        ),
      ),
      EtatGalerie(
        'selected',
        (BuildContext _) => const AppCard(
          onPress: _rien,
          selectionnee: true,
          child: Text('Une carte retenue'),
        ),
      ),
      EtatGalerie(
        'disabled',
        (BuildContext _) => const AppCard(child: Text('Une carte inerte')),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'SectionHeader',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      EtatGalerie(
        'titre seul',
        (BuildContext _) => const SectionHeader(titre: 'A traiter'),
      ),
      EtatGalerie(
        'compteur a zero',
        (BuildContext _) =>
            const SectionHeader(titre: 'A traiter', compteur: 0),
      ),
      EtatGalerie(
        'compteur + action',
        (BuildContext _) => SectionHeader(
          titre: 'A traiter',
          compteur: 17,
          libelleAction: t.commun.continuer,
          onAction: _rien,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'StatusPill',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'neutre',
        (BuildContext _) =>
            StatusPill(libelle: t.etat.enAttente, ton: TonEtat.neutre),
      ),
      EtatGalerie(
        'accent',
        (BuildContext _) =>
            StatusPill(libelle: t.etat.imminent, ton: TonEtat.accent),
      ),
      EtatGalerie(
        'succes',
        (BuildContext _) =>
            StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
      ),
      EtatGalerie(
        'avertissement',
        (BuildContext _) =>
            StatusPill(libelle: t.etat.enRetard, ton: TonEtat.avertissement),
      ),
      EtatGalerie(
        'alerte',
        (BuildContext _) =>
            StatusPill(libelle: t.etat.annule, ton: TonEtat.alerte),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'Skeleton',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'bloc',
        (BuildContext _) =>
            const Skeleton(hauteur: AppSpacing.section, differe: false),
      ),
      EtatGalerie(
        'texte',
        (BuildContext _) => const Skeleton.texte(differe: false),
      ),
      EtatGalerie(
        'liste',
        (BuildContext _) => const Skeleton.liste(lignes: 2, differe: false),
      ),
      EtatGalerie(
        'sous 200 ms : rien',
        (BuildContext _) => const Skeleton(hauteur: AppSpacing.section),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'LocalFeedback',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'message',
        (BuildContext _) =>
            const LocalFeedback(message: 'Creneau ajoute', persistant: true),
      ),
      EtatGalerie(
        'message + annulation',
        (BuildContext _) => LocalFeedback(
          message: 'Creneau ajoute',
          persistant: true,
          libelleAnnuler: t.commun.annuler,
          onAnnuler: _rien,
        ),
      ),
      EtatGalerie(
        'sans message : rien',
        (BuildContext _) => const LocalFeedback(message: null),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'StatTile',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'zero, comme les autres valeurs',
        (BuildContext _) => StatTile(
          valeur: 0,
          libelle: t.admin.tableau.dossiers,
          onPress: _rien,
        ),
      ),
      EtatGalerie(
        'valeur',
        (BuildContext _) => StatTile(
          valeur: 17,
          libelle: t.admin.tableau.foyers,
          onPress: _rien,
        ),
      ),
      EtatGalerie(
        'ton alerte',
        (BuildContext _) => StatTile(
          valeur: 3,
          libelle: t.admin.tableau.incidents,
          ton: TonEtat.alerte,
          onPress: _rien,
        ),
      ),
      EtatGalerie(
        'sans action',
        (BuildContext _) =>
            StatTile(valeur: 42, libelle: t.admin.tableau.comptes),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'SignalRow',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'neutre',
        (BuildContext _) => SignalRow(
          phrase: t.admin.tableau.ligneDossier(prenom: 'Aicha'),
          icone: AppIcons.dossiers,
          anciennete: t.admin.tableau.attenteJours(jours: 3),
          onPress: _rien,
        ),
      ),
      EtatGalerie(
        'avertissement',
        (BuildContext _) => SignalRow(
          phrase: t.admin.tableau.lignePlafond(prenom: 'Youssef'),
          icone: AppIcons.avertissement,
          anciennete: t.admin.tableau.attenteUnJour,
          ton: TonEtat.avertissement,
          onPress: _rien,
        ),
      ),
      EtatGalerie(
        'sans anciennete',
        (BuildContext _) => SignalRow(
          phrase: t.admin.tableau.ligneRegle(prenom: 'Amina'),
          icone: AppIcons.journal,
          onPress: _rien,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'AppBottomSheet',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      EtatGalerie(
        'titre + corps',
        (BuildContext _) => const AppBottomSheet(
          titre: 'Changer d enseignant',
          child: Text('Le corps de la feuille.'),
        ),
      ),
      EtatGalerie(
        'titre + corps + actions',
        (BuildContext _) => AppBottomSheet(
          titre: 'Changer d enseignant',
          actions: ActionPrincipale(libelle: t.commun.valider, onPress: _rien),
          child: const Text('Le corps de la feuille.'),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'ConfirmDestructive',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      EtatGalerie(
        'reversible',
        (BuildContext _) => ConfirmDestructive(
          question: 'Retirer cet appareil ?',
          consequence: t.appareils.revoquerConfirmation,
          libelleConfirmer: t.appareils.revoquer,
          onConfirmer: _rien,
          onAnnuler: _rien,
        ),
      ),
      EtatGalerie(
        'irreversible',
        (BuildContext _) => ConfirmDestructive(
          question: 'Retirer cet appareil ?',
          consequence: t.appareils.revoquerConfirmation,
          libelleConfirmer: t.appareils.revoquer,
          irreversible: true,
          onConfirmer: _rien,
          onAnnuler: _rien,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'ChildCard',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'normal',
        (BuildContext _) => ChildCard(
          prenom: 'Aicha',
          etat: EnfantProchainCours(
            t.tuteur.accueil.aujourdhui(heure: '17:00', prenom: 'Youssef'),
          ),
          onOuvrir: _rien,
        ),
      ),
      EtatGalerie(
        'aucun planning',
        (BuildContext _) => const ChildCard(
          prenom: 'Ibrahim',
          etat: EnfantSansPlanning(),
          onPoserHoraire: _rien,
        ),
      ),
      EtatGalerie(
        'cours imminent',
        (BuildContext _) => ChildCard(
          prenom: 'Aicha',
          etat: EnfantImminent(
            heure: '17:00',
            minuteur: t.eleve.accueil.dansMinutes(minutes: 4),
          ),
          onOuvrir: _rien,
        ),
      ),
      EtatGalerie(
        'en cours',
        (BuildContext _) => ChildCard(
          prenom: 'Aicha',
          etat: EnfantEnCours(
            enseignant: 'Youssef',
            depuis: t.tuteur.accueil.depuisMinutes(minutes: 12),
          ),
          onAssister: _rien,
        ),
      ),
      EtatGalerie(
        'en recherche d enseignant',
        (BuildContext _) => ChildCard(
          prenom: 'Ibrahim',
          etat: EnfantEnRecherche(
            t.tuteur.accueil.enRechercheDepuis(date: '2 septembre'),
          ),
        ),
      ),
      EtatGalerie(
        'seance annulee',
        (BuildContext _) => ChildCard(
          prenom: 'Amina',
          etat: EnfantSeanceAnnulee(
            motif: t.tuteur.accueil.motifAnnulee,
            propose: t.tuteur.accueil.proposeAucun,
          ),
        ),
      ),
      EtatGalerie(
        'offline',
        (BuildContext _) => ChildCard(
          prenom: 'Aicha',
          etat: EnfantProchainCours(
            t.tuteur.accueil.aujourdhui(heure: '17:00', prenom: 'Youssef'),
          ),
          horsLigne: true,
          onReessayer: _rien,
        ),
      ),
    ],
  ),

  // --- Les onze composants repris, plus la grille -------------------------
  EntreeGalerie(
    nom: 'Pressable',
    famille: FamilleComposant.controleInteractif,
    etats: <EtatGalerie>[
      EtatGalerie('default', (BuildContext _) => const _CibleTactile()),
      EtatGalerie(
        'hover',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(survole: true),
          child: _CibleTactile(),
        ),
      ),
      EtatGalerie(
        'pressed',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(presse: true),
          child: _CibleTactile(),
        ),
      ),
      EtatGalerie(
        'focus',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(focus: true),
          child: _CibleTactile(),
        ),
      ),
      EtatGalerie(
        'disabled',
        (BuildContext _) => const _CibleTactile(actif: false),
      ),
      EtatGalerie(
        'loading',
        (BuildContext _) => const Pressable(
          onPress: null,
          child: SizedBox.square(
            dimension: AppSpacing.xxl,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'ActionPrincipale',
    famille: FamilleComposant.controleInteractif,
    etats: <EtatGalerie>[
      EtatGalerie(
        'default',
        (BuildContext _) => _quatreNiveaux(const EtatPression()),
      ),
      EtatGalerie(
        'hover',
        (BuildContext _) => _quatreNiveaux(const EtatPression(survole: true)),
      ),
      EtatGalerie(
        'pressed',
        (BuildContext _) => _quatreNiveaux(const EtatPression(presse: true)),
      ),
      EtatGalerie(
        'focus',
        (BuildContext _) => _quatreNiveaux(const EtatPression(focus: true)),
      ),
      EtatGalerie(
        'disabled',
        (BuildContext _) =>
            ActionPrincipale(libelle: t.commun.continuer, onPress: null),
      ),
      EtatGalerie(
        'loading',
        (BuildContext _) => ActionPrincipale(
          libelle: t.commun.continuer,
          enCours: true,
          onPress: _rien,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'BentoTile',
    famille: FamilleComposant.carteCliquable,
    etats: <EtatGalerie>[
      EtatGalerie(
        'default',
        (BuildContext _) =>
            const BentoTile(onPress: _rien, child: Text('Une tuile')),
      ),
      EtatGalerie(
        'hover',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(survole: true),
          child: BentoTile(onPress: _rien, child: Text('Une tuile')),
        ),
      ),
      EtatGalerie(
        'pressed',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(presse: true),
          child: BentoTile(onPress: _rien, child: Text('Une tuile')),
        ),
      ),
      EtatGalerie(
        'focus',
        (BuildContext _) => const PressionForcee(
          etat: EtatPression(focus: true),
          child: BentoTile(onPress: _rien, child: Text('Une tuile')),
        ),
      ),
      EtatGalerie(
        'selected',
        (BuildContext contexte) => BentoTile(
          surface: AppPalette.of(contexte).washAccent,
          onPress: _rien,
          child: const Text('Une tuile retenue'),
        ),
      ),
      EtatGalerie(
        'disabled',
        (BuildContext _) => const BentoTile(child: Text('Une tuile inerte')),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'AvatarTile',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'sans photo, deux mots',
        (BuildContext _) => const AvatarTile(prenom: 'Amina Bah'),
      ),
      EtatGalerie(
        'sans photo, un mot',
        (BuildContext _) => const AvatarTile(prenom: 'Ibrahim'),
      ),
      EtatGalerie(
        'photo introuvable : meme repli',
        (BuildContext _) => const AvatarTile(
          prenom: 'Ibrahim',
          urlSignee: 'https://exemple.invalid/introuvable.webp',
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'AudioLabel',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'sur le fond general',
        (BuildContext _) =>
            const AudioLabel(cle: ClesAudio.eleveAccueilRejoindre),
      ),
      EtatGalerie(
        'sur une surface coloree',
        (BuildContext contexte) => BentoTile(
          surface: AppPalette.of(contexte).surfacePrimary,
          child: AudioLabel(
            cle: ClesAudio.eleveAccueilRejoindre,
            surface: AppPalette.of(contexte).surfacePrimary,
          ),
        ),
      ),
      EtatGalerie(
        'sans texte',
        (BuildContext _) => const AudioLabel(
          cle: ClesAudio.eleveAccueilRejoindre,
          afficherTexte: false,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'PermanentNotice',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      // Un seul rendu possible, et c'est tout l'ADR-011 : le bandeau ne prend
      // aucun parametre, donc il ne peut pas avoir de second etat.
      EtatGalerie(
        'unique, sans parametre',
        (BuildContext _) => const PermanentNotice(),
      ),
      EtatGalerie(
        'en arabe : le meme, en miroir',
        (BuildContext _) => const Directionality(
          textDirection: TextDirection.rtl,
          child: PermanentNotice(),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'PinPad',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'default',
        (BuildContext _) => const PinPad(onCodeComplet: _codeIgnore),
      ),
      EtatGalerie(
        'error',
        (BuildContext _) =>
            const PinPad(onCodeComplet: _codeIgnore, enErreur: true),
      ),
      EtatGalerie(
        'six chiffres',
        (BuildContext _) =>
            const PinPad(onCodeComplet: _codeIgnore, longueur: 6),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'EmptyState',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'actionnable',
        (BuildContext _) => EmptyState(
          message: t.vide.aucunCreneau,
          invitation: t.disponibilites.effet,
          libelleAction: t.tuteur.accueil.poserDesHeures,
          onAction: _rien,
        ),
      ),
      EtatGalerie(
        'subi',
        (BuildContext _) => EmptyState(
          message: t.vide.aucunCours,
          invitation: t.vide.aucunCoursDetail,
          registre: RegistreVide.subi,
        ),
      ),
      EtatGalerie(
        'bonne nouvelle',
        (BuildContext _) => EmptyState(
          message: t.dossiers.aucun,
          invitation: t.dossiers.aucunDetail,
          registre: RegistreVide.bonneNouvelle,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'OfflineBanner',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      // Le bandeau lit le reseau reel : dans la galerie, il est donc vide tant
      // que la machine est en ligne. Ce qui se montre ici est sa forme, rendue
      // par le meme code sur une surface de demonstration.
      EtatGalerie('en ligne : rien', (BuildContext _) => const OfflineBanner()),
      EtatGalerie(
        'hors ligne : la forme',
        (BuildContext _) => const _BandeauHorsLigneFige(),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'ChoiceCardGroup',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'choix simple',
        (BuildContext _) => const ChoiceCardGroup(
          options: <OptionChoix>[
            OptionChoix(
              valeur: 'debutant',
              libelle: 'Debutant',
              icone: AppIcons.suivi,
            ),
            OptionChoix(
              valeur: 'intermediaire',
              libelle: 'Intermediaire',
              icone: AppIcons.suivi,
            ),
          ],
          onChange: _choixIgnore,
        ),
      ),
      EtatGalerie(
        'selection posee',
        (BuildContext _) => const ChoiceCardGroup(
          options: <OptionChoix>[
            OptionChoix(
              valeur: 'debutant',
              libelle: 'Debutant',
              icone: AppIcons.suivi,
            ),
          ],
          valeurInitiale: ReponseChoix(valeurs: <String>{'debutant'}),
          onChange: _choixIgnore,
        ),
      ),
      EtatGalerie(
        'choix multiple',
        (BuildContext _) => const ChoiceCardGroup(
          options: <OptionChoix>[
            OptionChoix(valeur: 'lundi', libelle: 'Lundi'),
            OptionChoix(valeur: 'mardi', libelle: 'Mardi'),
          ],
          selectionMultiple: true,
          onChange: _choixIgnore,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'GrilleSemaine',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'deux cases posees',
        (BuildContext _) => const GrilleSemaine(
          creneaux: _creneauxExemple,
          fuseau: 'Europe/Paris',
          onBasculer: _basculeIgnoree,
        ),
      ),
      EtatGalerie(
        'enregistrement en cours',
        (BuildContext _) => const GrilleSemaine(
          creneaux: _creneauxExemple,
          fuseau: 'Europe/Paris',
          enCours: true,
          onBasculer: _basculeIgnoree,
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'PageParcours',
    famille: FamilleComposant.structure,
    etats: <EtatGalerie>[
      EtatGalerie(
        'premiere page',
        (BuildContext _) => SizedBox(
          height: _hauteurPage,
          child: PageParcours(
            numero: 1,
            total: 3,
            question: t.inscription.roleQuestion,
            libelleAction: t.commun.continuer,
            minutesRestantes: 2,
            onAction: _rien,
            enfant: const Text('Le corps de la page.'),
          ),
        ),
      ),
      EtatGalerie(
        'page intermediaire, envoi en cours',
        (BuildContext _) => SizedBox(
          height: _hauteurPage,
          child: PageParcours(
            numero: 2,
            total: 3,
            question: t.inscription.identiteQuestion,
            explication: t.inscription.identiteRaison,
            libelleAction: t.commun.continuer,
            enCours: true,
            onRetour: _rien,
            onAction: _rien,
            enfant: const Text('Le corps de la page.'),
          ),
        ),
      ),
    ],
  ),
];

/// Les quatre niveaux d'action, dans un etat d'interaction donne.
Widget _quatreNiveaux(EtatPression etat) => PressionForcee(
  etat: etat,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final NiveauAction niveau in NiveauAction.values)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ActionPrincipale(
            libelle: niveau.name,
            niveau: niveau,
            onPress: _rien,
          ),
        ),
    ],
  ),
);

/// Une cible tactile nue, pour mesurer ce que `Pressable` garantit.
class _CibleTactile extends StatelessWidget {
  const _CibleTactile({this.actif = true});

  final bool actif;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Pressable(
      onPress: actif ? _rien : null,
      libelleSemantique: t.commun.continuer,
      arrondiFocus: AppRadius.arrondiSm,
      child: DecoratedBox(
        decoration: palette.surfaceSunken.decoration(
          borderRadius: AppRadius.arrondiSm,
          side: palette.borderResting.asBorderSide(),
        ),
        child: Center(child: Text(t.commun.continuer)),
      ),
    );
  }
}

/// Le bandeau hors ligne, fige dans sa forme visible.
///
/// Le vrai composant lit l'etat du reseau : sur une machine en ligne, il ne
/// rend rien du tout. Celui-ci rejoue **la meme composition**, pour que la
/// forme soit verifiable sans debrancher la machine. S'ils divergent un jour,
/// c'est ici qu'il faut corriger, jamais dans le composant.
class _BandeauHorsLigneFige extends StatelessWidget {
  const _BandeauHorsLigneFige();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.washWarning.background,
        border: Border(bottom: palette.borderStrong.asBorderSide()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            IconTheme(
              data: IconThemeData(
                color: palette.washWarning.onBackground,
                size: AppSpacing.xl,
              ),
              child: Icon(AppIcons.horsLigne.repos),
            ),
            Ecart.hSm,
            Expanded(
              child: Text(
                t.reseau.horsLigne,
                style: palette.washWarning.applyTo(
                  Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une surface de demonstration, pour montrer ce que `NavShell` entoure.
class _SurfaceDemonstration extends StatelessWidget {
  const _SurfaceDemonstration();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppPalette.of(context).surfaceCanvas.background,
      child: Center(child: Text(t.galerie.composants)),
    );
  }
}

void _rien() {}

void _allerNullePart(String chemin) {}

void _codeIgnore(String code) {}

void _choixIgnore(ReponseChoix reponse) {}

void _basculeIgnoree(Creneau creneau, bool posee) {}

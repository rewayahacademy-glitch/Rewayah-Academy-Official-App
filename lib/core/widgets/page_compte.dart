import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_spacing.dart';
import '../version/ligne_version.dart';
import 'bloc_asynchrone.dart';
import 'confirm_destructive.dart';
import 'empty_state.dart';
import 'entete_compte.dart';
import 'groupe_preferences.dart';
import 'groupe_reglages.dart';
import 'offline_banner.dart';
import 'page_shell.dart';
import 'skeleton.dart';

/// Les sections du Compte, dans leur ordre fixe (PROFILS P1, pilote du
/// 11/11/2026). « Se déconnecter » et la version viennent toujours apres.
enum SectionCompte {
  /// 1. Mon espace.
  monEspace,

  /// 2. Paiements.
  paiements,

  /// 3. Préférences.
  preferences,

  /// 4. Compte et sécurité.
  compteSecurite,

  /// 5. Aide et informations.
  aide;

  /// Le titre de la section, dans la langue de l'application.
  String get titre => switch (this) {
    SectionCompte.monEspace => t.compte.page.sections.monEspace,
    SectionCompte.paiements => t.compte.page.sections.paiements,
    SectionCompte.preferences => t.compte.page.sections.preferences,
    SectionCompte.compteSecurite => t.compte.page.sections.compteSecurite,
    SectionCompte.aide => t.compte.page.sections.aide,
  };
}

/// Le gabarit unique du Compte, pour tous les roles (PROFILS P1, pilote du
/// 11/11/2026). Une page Compte se compose ici et nulle part ailleurs (garde
/// `test/core/widgets/page_compte_garde_test.dart`).
///
/// Dans l'ordre : l'[EnteteCompte] (photo, nom, role, matricule, statut), les
/// sections titrees de [SectionCompte] (au style de [GroupeReglages]), avec
/// les [preferences] posees dans la section 3, puis la ligne rouge « Se
/// déconnecter » (confirmation avant tout) et la version.
///
/// Chaque role ne fournit que ses lignes ; une section sans ligne ne
/// s'affiche pas. L'ecran du role decide de chaque ligne selon une capacite,
/// jamais selon un role.
///
/// Etats, ceux de l'identite : chargement (squelette de l'en-tete), contenu,
/// vide (identite absente : une phrase), erreur (« Réessayer »). Hors ligne,
/// le bandeau de la page ([PageShell]) ; dans tous les etats, les sections,
/// les preferences et la deconnexion restent la : on peut toujours changer
/// le theme et se deconnecter.
class PageCompte extends StatelessWidget {
  /// Cree la page.
  const PageCompte({
    required this.identite,
    required this.onDeconnecter,
    super.key,
    this.sections = const <SectionCompte, List<LigneRubrique>>{},
    this.avantLignes = const <SectionCompte, List<Widget>>{},
    this.preferences,
    this.onReessayer,
    this.onChangerPhoto,
    this.photo,
    this.piedEntete,
    this.titre,
    this.bandeauHorsLigne,
    this.version = const LigneVersion(),
  });

  /// L'identite de la personne connectee. `null` dans les donnees : vide.
  final AsyncValue<IdentiteCompte?> identite;

  /// Les lignes de chaque section, fournies par le role.
  final Map<SectionCompte, List<LigneRubrique>> sections;

  /// Les preferences, posees en tete de la section 3.
  final GroupePreferences? preferences;

  /// Ce qu'une section pose sous son titre, avant ses lignes : un avis qui
  /// la concerne (coordonnees de versement incompletes), un selecteur qui
  /// n'est pas une ligne (les espaces). Une section qui n'a ni ligne ni
  /// bloc ne s'affiche pas.
  final Map<SectionCompte, List<Widget>> avantLignes;

  /// La ligne de version, en bas : par defaut la [LigneVersion] de
  /// l'application (lue dans `version.json`, en anglais dans toutes les
  /// langues, decision du directeur du 03/11 ; rien si elle est illisible).
  final Widget version;

  /// La photo de l'en-tete, quand l'ecran la lit lui-meme (photo signee de
  /// la personne). Nulle : l'initiale du nom.
  final Widget? photo;

  /// Ce que l'en-tete pose sous l'identite : le retour de l'envoi d'une
  /// photo.
  final Widget? piedEntete;

  /// La deconnexion, appelee apres confirmation seulement.
  final Future<void> Function() onDeconnecter;

  /// Relit l'identite apres un echec.
  final VoidCallback? onReessayer;

  /// Ouvre le changement de photo (geste de la photo de l'en-tete).
  final VoidCallback? onChangerPhoto;

  /// Le titre de la page. Nul : « Mon compte ».
  final String? titre;

  /// Le bandeau hors ligne de la page. Nul : celui de [PageShell].
  final Widget? bandeauHorsLigne;

  /// La ligne « Se déconnecter ».
  static const Key deconnecterKey = Key('pageCompte.deconnecter');

  /// La version.
  static const Key versionKey = Key('pageCompte.version');

  /// La clé de la section [section], pour les tests et les captures.
  static Key cleSection(SectionCompte section) =>
      ValueKey<String>('pageCompte.section.${section.name}');

  Future<void> _deconnecter(BuildContext context) async {
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: t.compte.tuteur.deconnexion.question,
      consequence: t.compte.tuteur.deconnexion.consequence,
      libelleConfirmer: t.compte.tuteur.deconnexion.confirmer,
    );
    if (oui) await onDeconnecter();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> corps = <Widget>[
      BlocAsynchrone<IdentiteCompte?>(
        valeur: identite,
        squelette: const Skeleton.texte(lignes: 3),
        titreEchec: t.compte.page.identiteEchec,
        onReessayer: onReessayer,
        estVide: (IdentiteCompte? i) => i == null,
        vide: EmptyState(
          message: t.compte.page.identiteVide,
          icone: AppIcons.profil,
          registre: RegistreVide.subi,
        ),
        construire: (IdentiteCompte? i) => EnteteCompte(
          identite: i!,
          onChangerPhoto: onChangerPhoto,
          photo: photo,
          pied: piedEntete,
        ),
      ),
      for (final SectionCompte section in SectionCompte.values)
        if (_section(section) case final Widget contenu) contenu,
      GroupeReglages(
        key: deconnecterKey,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.sortie,
            libelle: t.compte.deconnexion,
            destructive: true,
            onPress: () => _deconnecter(context),
          ),
        ],
      ),
      Center(
        child: KeyedSubtree(key: versionKey, child: version),
      ),
    ];

    return PageShell(
      titre: titre ?? t.compte.titre,
      bandeauHorsLigne: bandeauHorsLigne ?? const OfflineBanner(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xl,
        children: corps,
      ),
    );
  }

  Widget? _section(SectionCompte section) {
    final List<LigneRubrique> lignes =
        sections[section] ?? const <LigneRubrique>[];
    final List<Widget> blocs = avantLignes[section] ?? const <Widget>[];
    final GroupePreferences? prefs = section == SectionCompte.preferences
        ? preferences
        : null;
    if (lignes.isEmpty && prefs == null && blocs.isEmpty) return null;
    if (prefs == null && blocs.isEmpty) {
      return GroupeReglages(
        key: cleSection(section),
        titre: section.titre,
        lignes: lignes,
      );
    }
    final List<Widget> morceaux = <Widget>[...blocs, ?prefs];
    return Column(
      key: cleSection(section),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TitreGroupeReglages(section.titre),
        Ecart.vSm,
        for (int i = 0; i < morceaux.length; i++) ...<Widget>[
          if (i > 0) Ecart.vLg,
          morceaux[i],
        ],
        if (lignes.isNotEmpty) ...<Widget>[
          Ecart.vLg,
          GroupeReglages(lignes: lignes),
        ],
      ],
    );
  }
}

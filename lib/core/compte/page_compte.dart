// PROFILS P1 (directeur, 11/11/2026) : UN SEUL gabarit de page Compte pour
// tous les roles. Une page de role ne compose pas son Compte : elle donne a
// [PageCompte] son en-tete et les lignes de chaque section, et rien d'autre.
//
// Regles portees par le gabarit :
// - ordre fixe des sections ([SectionCompte]) ; une section vide ne
//   s'affiche pas ;
// - « 100 % operationnel » : aucun etat « Non disponible » pour une ligne.
//   Une ligne qui ne marche pas n'est pas fournie ;
// - une ligne s'affiche selon une capacite, jamais selon un role : c'est la
//   page de role qui decide de la fournir ;
// - la page defile (DECISION-DEFILEMENT), une seule barre ;
// - etats : chargement, contenu, vide, erreur, hors ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../session/deconnexion.dart';
import '../session/session_controleur.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/confirm_destructive.dart';
import '../widgets/etat_systeme.dart';
import '../widgets/groupe_reglages.dart';
import '../widgets/page_shell.dart';
import '../widgets/skeleton.dart';
import 'entete_compte.dart';

/// Les sections du Compte, dans leur ordre fixe d'affichage.
enum SectionCompte {
  /// 1. Mon espace.
  monEspace,

  /// 2. Paiements.
  paiements,

  /// 3. Preferences (voir `GroupePreferences`).
  preferences,

  /// 4. Compte et securite.
  compteSecurite,

  /// 5. Aide et informations.
  aideInformations;

  /// Le titre visible de la section.
  String get titre => switch (this) {
    SectionCompte.monEspace => t.compte.page.monEspace,
    SectionCompte.paiements => t.compte.page.paiements,
    SectionCompte.preferences => t.compte.page.preferences,
    SectionCompte.compteSecurite => t.compte.page.compteSecurite,
    SectionCompte.aideInformations => t.compte.page.aideInformations,
  };
}

/// L'etat de lecture de la page.
enum EtatPageCompte {
  /// La lecture est en cours : squelette.
  chargement,

  /// Le contenu est lu.
  contenu,

  /// La lecture a echoue : erreur avec « Reessayer ».
  erreur,

  /// Hors ligne, sans rien de lu a montrer.
  horsLigne,
}

/// Le gabarit unique de la page Compte.
class PageCompte extends StatelessWidget {
  /// Cree la page.
  const PageCompte({
    required this.titre,
    required this.entete,
    super.key,
    this.etat = EtatPageCompte.contenu,
    this.lignes = const <SectionCompte, List<LigneRubrique>>{},
    this.preferences,
    this.version,
    this.onReessayer,
    this.onRetour,
    this.deconnexion = true,
  });

  /// Le titre de la page (« Compte », « Profil »).
  final String titre;

  /// L'en-tete : photo, nom, role, matricule, statut.
  final EnteteCompte entete;

  /// L'etat de lecture.
  final EtatPageCompte etat;

  /// Les lignes de chaque section. Une section absente ou vide ne s'affiche
  /// pas.
  final Map<SectionCompte, List<LigneRubrique>> lignes;

  /// Le contenu de la section Preferences (`GroupePreferences`), pose a sa
  /// place dans l'ordre. Nul : la section suit [lignes].
  final Widget? preferences;

  /// La version de l'application, sous la deconnexion.
  final String? version;

  /// Relire apres une erreur.
  final VoidCallback? onReessayer;

  /// Le retour, quand la page n'est pas une destination.
  final VoidCallback? onRetour;

  /// Vrai : la ligne « Se deconnecter » ferme la page.
  final bool deconnexion;

  /// La cle de la ligne « Se deconnecter ».
  static const Key deconnexionKey = Key('compte.page.deconnexion');

  /// La cle de la version.
  static const Key versionKey = Key('compte.page.version');

  /// La cle d'une section.
  static Key sectionKey(SectionCompte section) =>
      Key('compte.page.section.${section.name}');

  @override
  Widget build(BuildContext context) => PageShell(
    titre: titre,
    onRetour: onRetour,
    child: switch (etat) {
      EtatPageCompte.chargement => const _Squelette(),
      EtatPageCompte.erreur => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: t.compte.page.erreurTitre,
        libelleAction: onReessayer == null ? null : t.compte.page.reessayer,
        onAction: onReessayer,
      ),
      EtatPageCompte.horsLigne => EtatSysteme.sansDonnees(
        quoi: t.compte.page.sansDonnees,
      ),
      EtatPageCompte.contenu => _Contenu(page: this),
    },
  );
}

class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Skeleton.texte(),
      SizedBox(height: AppSpacing.section),
      Skeleton.texte(),
    ],
  );
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.page});

  final PageCompte page;

  @override
  Widget build(BuildContext context) {
    final List<Widget> sections = <Widget>[];
    for (final SectionCompte section in SectionCompte.values) {
      final Widget? bloc = section == SectionCompte.preferences
          ? page.preferences ?? _groupe(section)
          : _groupe(section);
      if (bloc == null) continue;
      sections
        ..add(Ecart.vSection)
        ..add(KeyedSubtree(key: PageCompte.sectionKey(section), child: bloc));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        page.entete,
        ...sections,
        if (page.deconnexion) ...<Widget>[
          Ecart.vSection,
          const LigneDeconnexion(key: PageCompte.deconnexionKey),
        ],
        if (page.version != null) ...<Widget>[
          Ecart.vLg,
          Center(
            child: Text(
              page.version!,
              key: PageCompte.versionKey,
              style: AppPalette.of(context).inkMuted.applyTo(
                Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _groupe(SectionCompte section) {
    final List<LigneRubrique> lignes =
        page.lignes[section] ?? const <LigneRubrique>[];
    if (lignes.isEmpty) return null;
    return GroupeReglages(titre: section.titre, lignes: lignes);
  }
}

/// « Se deconnecter » : une ligne rouge, une confirmation, puis la sortie
/// commune (`seDeconnecter`). Un echec se dit sous la ligne.
class LigneDeconnexion extends ConsumerStatefulWidget {
  /// Cree la ligne.
  const LigneDeconnexion({super.key});

  @override
  ConsumerState<LigneDeconnexion> createState() => _LigneDeconnexionEtat();
}

class _LigneDeconnexionEtat extends ConsumerState<LigneDeconnexion> {
  bool _enCours = false;
  bool _echec = false;

  Future<void> _sortir() async {
    if (_enCours) return;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.compte.tuteur.deconnexion.question,
      consequence: t.compte.tuteur.deconnexion.consequence,
      libelleConfirmer: t.compte.tuteur.deconnexion.confirmer,
    );
    if (!confirme || !mounted) return;
    if (ref.read(sessionProvider.notifier).fermerDemo()) return;
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await seDeconnecter(context, ref);
    } on Object {
      if (mounted) setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: t.compte.deconnexion,
              alerte: true,
              onPress: _enCours ? null : () => unawaited(_sortir()),
            ),
          ],
        ),
        if (_echec) ...<Widget>[
          Ecart.vSm,
          Text(
            t.compte.tuteur.deconnexion.echec,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

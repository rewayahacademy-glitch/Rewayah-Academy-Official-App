import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_tile.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/skeleton.dart';

/// Fixtures locales de la surface Compte.
///
/// Cette enum et les donnees rendues ici appartiennent au banc de developpement
/// uniquement. Elles ne remplacent ni [SessionState] ni les projections du
/// serveur et ne sont jamais utilisees par une route de production.
enum CompteGalerieFixture {
  profilIncomplet,
  adminCapacites,
  tuteurPlusieursEnfants,
  vide,
  erreur,
  chargement,
  horsLigne,
}

extension on CompteGalerieFixture {
  String get nom => switch (this) {
    CompteGalerieFixture.profilIncomplet => 'Profil personnel incomplet',
    CompteGalerieFixture.adminCapacites => 'Administration et capacites',
    CompteGalerieFixture.tuteurPlusieursEnfants =>
      'Tuteur avec plusieurs enfants',
    CompteGalerieFixture.vide => 'Etat vide',
    CompteGalerieFixture.erreur => 'Etat erreur',
    CompteGalerieFixture.chargement => 'Etat chargement',
    CompteGalerieFixture.horsLigne => 'Etat hors ligne',
  };
}

/// Galerie de developpement dediee a Compte, Reglages et Profils.
///
/// Les six fixtures demandees par le lot R3 sont explicites et deterministes.
/// Le septieme cas montre le bandeau hors ligne attendu par les pages R3.
class CompteGaleriePage extends StatefulWidget {
  /// Cree la galerie Compte.
  const CompteGaleriePage({super.key});

  @override
  State<CompteGaleriePage> createState() => _CompteGaleriePageState();
}

class _CompteGaleriePageState extends State<CompteGaleriePage> {
  CompteGalerieFixture _selection = CompteGalerieFixture.profilIncomplet;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Galerie Compte indisponible en production')),
      );
    }

    return PageShell(
      titre: 'Galerie Compte',
      entete: const Text(
        'Fixtures locales de Compte, Reglages et Profils. Aucune donnee distante.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SelecteurFixture(
            selection: _selection,
            onSelection: (CompteGalerieFixture fixture) =>
                setState(() => _selection = fixture),
          ),
          Ecart.vSection,
          _contenu(_selection),
        ],
      ),
    );
  }

  Widget _contenu(CompteGalerieFixture fixture) => switch (fixture) {
    CompteGalerieFixture.profilIncomplet => const _ProfilIncomplet(),
    CompteGalerieFixture.adminCapacites => const _AdminCapacites(),
    CompteGalerieFixture.tuteurPlusieursEnfants => const _PlusieursEnfants(),
    CompteGalerieFixture.vide => const EmptyState(
      message: 'Aucun profil enfant dans ce foyer',
      invitation: 'Le tuteur peut ajouter un enfant depuis le foyer.',
      icone: AppIcons.foyer,
      registre: RegistreVide.subi,
    ),
    CompteGalerieFixture.erreur => const _EtatErreur(),
    CompteGalerieFixture.chargement => const _EtatChargement(),
    CompteGalerieFixture.horsLigne => const _EtatHorsLigne(),
  };
}

class _SelecteurFixture extends StatelessWidget {
  const _SelecteurFixture({required this.selection, required this.onSelection});

  final CompteGalerieFixture selection;
  final ValueChanged<CompteGalerieFixture> onSelection;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: <Widget>[
      for (final CompteGalerieFixture fixture in CompteGalerieFixture.values)
        ActionPrincipale(
          libelle: fixture.nom,
          niveau: fixture == selection
              ? NiveauAction.principale
              : NiveauAction.secondaire,
          pleineLargeur: false,
          onPress: () => onSelection(fixture),
        ),
    ],
  );
}

class _ProfilIncomplet extends StatelessWidget {
  const _ProfilIncomplet();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AppCard(
        dominante: true,
        entete: const Text('Profil personnel incomplet'),
        child: Row(
          children: <Widget>[
            const AvatarTile(prenom: 'Amina'),
            Ecart.hXl,
            Expanded(
              child: Text(
                'Amina',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
      Ecart.vSection,
      SectionHeader(titre: t.compte.informations),
      const SettingRow(
        title: 'Identifiant',
        value: 'STUD-AD-000001',
        icon: AppIcons.profil,
        enabled: false,
      ),
      const SettingRow(
        title: 'Contact de connexion',
        value: 'Non disponible',
        description: 'La methode de connexion actuelle ne le projette pas.',
        icon: AppIcons.profil,
        enabled: false,
      ),
      const SettingRow(
        title: 'Fuseau horaire',
        value: 'Non disponible',
        icon: AppIcons.reglages,
        enabled: false,
      ),
    ],
  );
}

class _AdminCapacites extends StatelessWidget {
  const _AdminCapacites();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AppCard(
        dominante: true,
        entete: Text('Administration'),
        child: Text(
          'Fixture de lecture seule. La session porte une autorisation admin; aucune ligne ne peut attribuer un role.',
        ),
      ),
      Ecart.vSection,
      SectionHeader(titre: 'Matrice de capacites'),
      SettingRow(
        title: 'Gerer les horaires',
        value: 'Selon habilitation serveur',
        icon: AppIcons.tableauDeBord,
        enabled: false,
      ),
      SettingRow(
        title: 'Projection enseignement',
        value: 'Lecture seule',
        icon: AppIcons.journee,
        enabled: false,
      ),
      SettingRow(
        title: 'Attribuer un role',
        value: 'Jamais depuis le client',
        icon: AppIcons.controleQualite,
        enabled: false,
      ),
    ],
  );
}

class _PlusieursEnfants extends StatelessWidget {
  const _PlusieursEnfants();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const AppCard(
        dominante: true,
        entete: Text('Tuteur avec plusieurs enfants'),
        child: Text(
          'Chaque profil reste dans le perimetre du foyer et conserve son identifiant.',
        ),
      ),
      Ecart.vSection,
      for (final ({String prenom, String id}) enfant
          in <({String prenom, String id})>[
            (prenom: 'Amina', id: 'STUD-CH-000001'),
            (prenom: 'Yusuf', id: 'STUD-CH-000002'),
            (prenom: 'Mariam', id: 'STUD-CH-000003'),
          ])
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            child: Row(
              children: <Widget>[
                AvatarTile(prenom: enfant.prenom),
                Ecart.hXl,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        enfant.prenom,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Ecart.vXs,
                      Text(enfant.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _EtatErreur extends StatelessWidget {
  const _EtatErreur();
  @override
  Widget build(BuildContext context) => AppCard(
    surface: AppPalette.of(context).washAlert,
    entete: const Text('Les profils du foyer n ont pas pu etre lus.'),
    child: ActionPrincipale(
      libelle: t.compte.reessayer,
      niveau: NiveauAction.secondaire,
      pleineLargeur: false,
      onPress: () {},
    ),
  );
}

class _EtatChargement extends StatelessWidget {
  const _EtatChargement();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Profils du foyer en chargement',
    child: const AppCard(child: Skeleton.liste(differe: false)),
  );
}

class _EtatHorsLigne extends StatelessWidget {
  const _EtatHorsLigne();

  @override
  Widget build(BuildContext context) => AppCard(
    surface: AppPalette.of(context).washWarning,
    entete: const Text('Hors ligne'),
    child: Text(
      t.reseau.horsLigne,
      style: AppPalette.of(context).washWarning
          .applyTo(Theme.of(context).textTheme.bodyLarge ?? const TextStyle()),
    ),
  );
}

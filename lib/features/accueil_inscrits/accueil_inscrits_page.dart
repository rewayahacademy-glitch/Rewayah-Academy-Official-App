// IMM-ACCUEIL-FRONT : l'accueil d'une famille deja inscrite
// (`DECISION-IMMATRICULATION-2026-10-12.md` §5, points 3 a 5).
//
// Une seule vue, posee a deux endroits :
// - `/tuteur/inscription-reprise`, quand le serveur a cree le profil du
//   tuteur : le mot de la direction, les profils eleves importes a ajouter
//   (prenom deja rempli), puis « Continuer » vers l'accueil habituel ;
// - `/inscription`, dans le cas rare ou la reprise n'a pas pu creer le
//   profil (aucun nom de tuteur dans l'import) : le mot, puis les questions
//   habituelles.
// Le contenu vient tout entier du serveur ; aucune personne ni aucun texte de
// famille n'est ecrit dans l'application.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/import_inscriptions/accueil_inscrits.dart';
import '../../core/import_inscriptions/port_reclamation_preinscription.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';

/// Ce que l'ajout d'un profil eleve recoit quand il part de l'accueil des
/// inscrits : le prenom importe, a ne pas ressaisir. Passe en `extra`, jamais
/// dans l'adresse (un prenom n'a rien a faire dans l'historique du
/// navigateur).
class AjoutDepuisAccueilInscrits {
  /// Cree la demande.
  const AjoutDepuisAccueilInscrits(this.prenom);

  /// Le prenom importe.
  final String prenom;
}

/// Compare deux prenoms sans tenir compte de la casse ni des espaces, comme
/// le serveur quand il reprend le matricule reserve.
String prenomCompare(String prenom) =>
    prenom.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// La page du tuteur (`/tuteur/inscription-reprise`).
class AccueilInscritsPage extends ConsumerWidget {
  /// Cree la page.
  const AccueilInscritsPage({super.key});

  /// L'action « Continuer ».
  static const Key continuerKey = Key('accueilInscrits.continuer');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatAccueilInscrits etat = ref.watch(accueilInscritsProvider);
    // Un widget lit une capacite : l'adulte eleve autonome rejoint son
    // propre accueil (C-24).
    final bool eleveAutonome = ref.watch(
      sessionProvider.select((s) => s.eleveAutonome),
    );
    void continuer() {
      GoRouter.of(context)
          .go(eleveAutonome ? Routes.eleveAdulte : Routes.tuteurAccueil);
      ref.read(accueilInscritsProvider.notifier).marquerVu();
    }

    if (etat is! AccueilConnu) {
      return PageShell(child: EtatReclamationVue(etat: etat));
    }

    final AsyncValue<List<EleveDuFoyer>> foyer = ref.watch(
      elevesDuFoyerProvider,
    );
    final Set<String> presents = <String>{
      for (final EleveDuFoyer e in foyer.value ?? const <EleveDuFoyer>[])
        prenomCompare(e.prenom),
    };
    return VueAccueilInscrits(
      reclamation: etat.reclamation,
      presents: presents,
      onAjouter: (PersonneImportee p) => GoRouter.of(context).go(
        Routes.tuteurAjouterEnfant,
        extra: AjoutDepuisAccueilInscrits(p.prenom),
      ),
      onContinuer: continuer,
    );
  }
}

/// L'accueil d'une famille deja inscrite : un titre qui rassure, le mot de
/// la direction s'il existe, les profils eleves importes, une seule action.
class VueAccueilInscrits extends StatelessWidget {
  /// Cree la vue.
  const VueAccueilInscrits({
    required this.reclamation,
    required this.onContinuer,
    super.key,
    this.presents = const <String>{},
    this.onAjouter,
  });

  /// Ce que le serveur a rendu.
  final ReclamationPreinscription reclamation;

  /// Les prenoms (compares) des profils eleves deja presents dans le foyer.
  final Set<String> presents;

  /// Ouvre l'ajout du profil eleve d'une personne importee ; `null` : le
  /// compte n'a pas encore de profil, la liste n'est pas montree.
  final void Function(PersonneImportee)? onAjouter;

  /// « Continuer ».
  final VoidCallback onContinuer;

  /// Le mot de la direction.
  static const Key motKey = Key('accueilInscrits.mot');

  /// La ligne d'un eleve importe.
  static Key eleveKey(String id) => Key('accueilInscrits.eleve.$id');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final void Function(PersonneImportee)? ajouter = onAjouter;
    final List<PersonneImportee> eleves = reclamation.eleves;
    final String? mot = reclamation.motAccueil;

    final List<Widget> cartes = <Widget>[
      if (mot != null)
        AppCard(
          key: motKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHeader(titre: t.accueilInscrits.motTitre),
              Ecart.vSm,
              Text(mot, style: textes.bodyLarge),
            ],
          ),
        ),
      if (ajouter != null && eleves.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(titre: t.accueilInscrits.elevesTitre),
            Ecart.vSm,
            Text(
              t.accueilInscrits.elevesPhrase,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vLg,
            CarteLignes(
              lignes: <Widget>[
                for (final PersonneImportee p in eleves)
                  _ligneEleve(p, ajouter),
              ],
            ),
            Ecart.vSm,
            Text(
              t.accueilInscrits.plusTard,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ),
      if (ajouter != null && eleves.isEmpty)
        Text(
          t.accueilInscrits.sansEleve,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      if (ajouter == null)
        Text(
          t.accueilInscrits.finirCompte,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
    ];

    return PageShell(
      titre: t.accueilInscrits.titre,
      sousTitre: t.accueilInscrits.phrase,
      actions: ActionPrincipale(
        key: AccueilInscritsPage.continuerKey,
        libelle: t.accueilInscrits.continuer,
        onPress: onContinuer,
      ),
      child: PileCartes(children: cartes),
    );
  }

  Widget _ligneEleve(
    PersonneImportee p,
    void Function(PersonneImportee) ajouter,
  ) {
    final bool aJour = presents.contains(prenomCompare(p.prenom));
    if (aJour) {
      return SettingRow(
        key: eleveKey(p.id),
        title: p.prenom,
        value: t.accueilInscrits.aJour,
      );
    }
    return SettingRow(
      key: eleveKey(p.id),
      title: t.accueilInscrits.ajouterProfil(prenom: p.prenom),
      value: t.accueilInscrits.aCompleter,
      lien: true,
      onPress: () => ajouter(p),
    );
  }
}

/// Les etats de la reclamation avant son resultat : verification en cours,
/// echec, aucune reponse. Le reste de la page n'ouvre rien tant qu'on ne
/// sait pas.
class EtatReclamationVue extends ConsumerWidget {
  /// Cree la vue.
  const EtatReclamationVue({required this.etat, super.key});

  /// L'etat a rendre.
  final EtatAccueilInscrits etat;

  /// L'etat d'echec.
  static const Key echecKey = Key('accueilInscrits.echec');

  /// L'etat sans reponse.
  static const Key horsLigneKey = Key('accueilInscrits.horsLigne');

  /// La verification en cours.
  static const Key chargementKey = Key('accueilInscrits.chargement');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void reessayer() => ref.read(accueilInscritsProvider.notifier).reessayer();
    return switch (etat) {
      AccueilEnEchec() => EtatSysteme(
        key: echecKey,
        nature: NatureEtat.echecServeur,
        titre: t.accueilInscrits.echecTitre,
        phrase: t.accueilInscrits.echecPhrase,
        onAction: reessayer,
        libelleSecondaire: t.inscription.seDeconnecter,
        onSecondaire: () => unawaited(seDeconnecter(context, ref)),
      ),
      AccueilHorsLigne() => EtatSysteme.sansDonnees(
        key: horsLigneKey,
        quoi: t.accueilInscrits.sansDonnees,
        onAction: reessayer,
      ),
      _ => const Skeleton.liste(key: chargementKey),
    };
  }
}

/// ECHELLE-FAM-ETATS-1 : l'ecran de resultat d'une fusion ou d'un transfert,
/// cote famille (R9, R10, R16, `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`).
///
/// La famille y lit, pour un seul eleve : sa **nouvelle classe**, le **titre
/// de son enseignant** et son **horaire**, dans le fuseau du foyer, avec la
/// date du changement. Rien d'autre : **jamais le nombre de classes
/// paralleles**, ni d'autres eleves, ni une phrase qui dise que des enfants
/// sont ensemble ou separes (R4 corrigee : chaque enfant a simplement son
/// suivi).
///
/// Etats : chargement (`Skeleton` dans `BlocAsynchrone`), contenu, vide (un
/// changement qui n'est plus a afficher : `EmptyState`), erreur
/// (`EtatSysteme`, « Reessayer »), hors ligne (le bandeau de `PageShell` ;
/// `EtatSansDonnees` seulement si rien n'a pu etre lu).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/port_suivi_demandes.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'libelles_suivi_demandes.dart';

/// Le suivi qui porte un changement de classe, ou `null`.
SuiviDemande? demandeAvecChangement(List<SuiviDemande> lues, String id) => lues
    .where((SuiviDemande d) => d.demandeId == id && d.changement != null)
    .firstOrNull;

/// L'ecran « Changement de classe » d'une demande.
class ChangementClassePage extends ConsumerWidget {
  /// Cree l'ecran.
  const ChangementClassePage({required this.demandeId, super.key});

  /// La demande dont la classe a change.
  final String demandeId;

  void _retour(BuildContext context) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) return;
    if (routeur.canPop()) {
      routeur.pop();
    } else {
      routeur.go(Routes.tuteurDemandes);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SuiviDemande>> demandes = ref.watch(
      suiviDemandesProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final c = t.suiviDemandes.changement;

    return PageShell(
      titre: c.titrePage,
      onRetour: () => _retour(context),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: BlocAsynchrone<List<SuiviDemande>>(
            key: const ValueKey<String>('changement-bloc'),
            valeur: demandes,
            squelette: const Skeleton.liste(lignes: 2),
            onReessayer: () => ref.invalidate(suiviDemandesProvider),
            estVide: (List<SuiviDemande> l) =>
                demandeAvecChangement(l, demandeId) == null,
            vide: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                EmptyState(
                  key: const ValueKey<String>('changement-introuvable'),
                  message: c.introuvable,
                  invitation: c.introuvableDetail,
                  icone: AppIcons.classes,
                  registre: RegistreVide.subi,
                ),
                Ecart.vLg,
                LienFleche(
                  libelle: c.retour,
                  alignerEnDebut: true,
                  onPress: () => _retour(context),
                ),
              ],
            ),
            erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('changement-sans-donnees'),
                    quoi: t.suiviDemandes.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('changement-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: t.suiviDemandes.erreur,
                    onAction: reessayer,
                  ),
            construire: (List<SuiviDemande> lues) => _Resultat(
              demande: demandeAvecChangement(lues, demandeId)!,
              onRetour: () => _retour(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _Resultat extends StatelessWidget {
  const _Resultat({required this.demande, required this.onRetour});

  final SuiviDemande demande;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final c = t.suiviDemandes.changement;
    final SuiviDemande d = demande;
    final ChangementClasse ch = d.changement!;
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String? enseignant = ch.enseignant;
    final CreneauDemande creneau = ch.creneau;
    final String? heure = _heureCommune(creneau, d.fuseauIana);

    return Column(
      key: const ValueKey<String>('changement-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          key: ValueKey<String>('changement-${d.demandeId}'),
          entete: Semantics(
            header: true,
            child: TexteSansCoupure(
              c.titre(
                dePrenom: deDevant(
                  d.prenom,
                  cle: 'suiviDemandes.changement.titre',
                ),
              ),
              style: textes.titleMedium ?? const TextStyle(),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                switch (ch.type) {
                  TypeChangementClasse.fusion => c.fusion(prenom: d.prenom),
                  TypeChangementClasse.transfert => c.transfert(
                    prenom: d.prenom,
                  ),
                },
                key: const ValueKey<String>('changement-phrase'),
                style: corps,
              ),
              Ecart.vLg,
              LigneCleValeur(
                key: const ValueKey<String>('changement-classe'),
                cle: c.classe,
                valeur: ch.classe,
              ),
              Ecart.vSm,
              if (enseignant != null && enseignant.isNotEmpty)
                LigneCleValeur(
                  key: const ValueKey<String>('changement-enseignant'),
                  cle: c.enseignant,
                  valeur: enseignant,
                )
              else
                Text(
                  c.sansEnseignant,
                  key: const ValueKey<String>('changement-sans-enseignant'),
                  style: corps,
                ),
              Ecart.vSm,
              // C-10 bis : une heure commune se dit une fois ; sinon chaque
              // jour avec la sienne, et le fuseau sur sa propre ligne.
              if (heure != null) ...<Widget>[
                LigneCleValeur(
                  key: const ValueKey<String>('changement-jours'),
                  cle: t.suiviDemandes.joursChoisis,
                  valeur: joursDemande(creneau.joursIso),
                ),
                Ecart.vSm,
                LigneCleValeur(
                  key: const ValueKey<String>('changement-heure'),
                  cle: t.suiviDemandes.heureChoisie,
                  valeur: heure,
                ),
              ] else ...<Widget>[
                LigneCleValeur(
                  key: const ValueKey<String>('changement-jours-heures'),
                  cle: t.suiviDemandes.creneauxChoisis,
                  valeur: joursEtHeuresDemande(creneau),
                ),
                Ecart.vSm,
                LigneCleValeur(
                  cle: t.suiviDemandes.fuseauChoisi,
                  valeur: t.suiviDemandes.fuseauValeur(
                    deVille: deFuseau(
                      d.fuseauIana,
                      cle: 'suiviDemandes.fuseauValeur',
                    ),
                  ),
                ),
              ],
              Ecart.vSm,
              LigneCleValeur(
                key: const ValueKey<String>('changement-date'),
                cle: c.date,
                valeur: libelleJalon(ch.quand) ?? '',
              ),
            ],
          ),
        ),
        Ecart.vLg,
        LienFleche(
          key: const ValueKey<String>('changement-retour'),
          libelle: c.retour,
          alignerEnDebut: true,
          onPress: onRetour,
        ),
      ],
    );
  }
}

/// « 18:00, heure de Paris » quand tous les jours ont la meme heure, sinon
/// `null` (la page dit alors chaque jour avec la sienne).
String? _heureCommune(CreneauDemande c, String fuseauIana) {
  if (c.occurrences.isEmpty || !c.heuresToutesEgales) return null;
  final OccurrenceCreneau o = c.occurrences.first;
  return t.suiviDemandes.heureFuseau(
    heure: hhmmDemande(o.heure, o.minute),
    deVille: deFuseau(fuseauIana, cle: 'suiviDemandes.heureFuseau'),
  );
}

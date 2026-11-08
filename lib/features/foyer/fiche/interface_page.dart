import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/appairage/service_appairage.dart';
import '../../../core/domain/enums.dart';
import '../../../core/fluidite/action_anticipee.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/elision.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../fiche_eleve_page.dart';

/// L'interface d'un profil eleve (`/tuteur/foyer/:eleveId/interface`).
///
/// Rendu des options de theme de l'Apparence haute fidelite (manifeste
/// visuel, section 2) : deux cartes a radio, « Interface guidee » et
/// « Interface standard », la retenue en bordure d'accent. **Politique
/// reelle** : la valeur est celle de `student_profiles.interface_mode`, fixee
/// a la creation selon l'age puis changee par le tuteur seul (ecriture
/// existante `majReglages`). Aucune bascule cote eleve n'est proposee : la
/// demande de l'eleve attend son contrat (DB-FOY-04), et l'ecran ne pretend
/// pas que l'eleve ne peut rien changer (risque serveur DB-TRV-01, a ne pas
/// masquer).
///
/// **Action instantanee** (DECISION-FLUIDITE, 07/11/2026, « un reglage
/// d'affichage ») : la carte touchee est retenue tout de suite, par l'outil
/// partage `ActionAnticipee` ; si le serveur ne confirme pas, la carte
/// d'avant revient et la phrase d'echec le dit. Le serveur reste seul juge :
/// la relecture du foyer apres l'ecriture fait foi.
class InterfaceElevePage extends StatelessWidget {
  /// Cree la page.
  const InterfaceElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  /// Le groupe des deux choix d'interface (`ChoiceCardGroup`).
  static const Key choixKey = Key('ficheEleve.interface.choix');

  /// La phrase hors ligne.
  static const Key horsLigneKey = Key('ficheEleve.interface.horsLigne');

  @override
  Widget build(BuildContext context) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.interface.titre,
      onRetour: retourVersFiche(context, eleveId),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _ChoixInterface(profil: profil),
    );
  }
}

class _ChoixInterface extends ConsumerStatefulWidget {
  const _ChoixInterface({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  ConsumerState<_ChoixInterface> createState() => _ChoixInterfaceState();
}

class _ChoixInterfaceState extends ConsumerState<_ChoixInterface> {
  /// Le choix affiche d'avance, tant que le serveur n'a pas ete relu ;
  /// `null` : la valeur relue du foyer.
  InterfaceMode? _affiche;
  ActionAnticipee? _action;
  bool _echec = false;

  /// Change a chaque geste : le groupe se reconstruit depuis le choix affiche.
  int _generation = 0;

  InterfaceMode get _mode => _affiche ?? widget.profil.mode;

  @override
  void didUpdateWidget(covariant _ChoixInterface ancien) {
    super.didUpdateWidget(ancien);
    // La relecture du foyer fait foi des qu'elle change.
    if (widget.profil.mode != ancien.profil.mode) _affiche = null;
  }

  @override
  void dispose() {
    _action?.dispose();
    super.dispose();
  }

  void _choisir(InterfaceMode mode) {
    final InterfaceMode avant = _mode;
    if (mode == avant) return;
    // Un envoi deja en vol : le geste ne part pas, la carte affichee reste.
    if (_action?.etat == EtatAnticipe.enCours) {
      setState(() => _generation++);
      return;
    }
    final ProviderContainer conteneur = ProviderScope.containerOf(
      context,
      listen: false,
    );
    final String eleveId = widget.profil.eleveId;
    _action?.dispose();
    final ActionAnticipee action = ActionAnticipee(
      nature: NatureAction.instantanee,
      cle: 'interface:$eleveId:${mode.name}',
      envoi: (String _) => conteneur
          .read(serviceAppairageProvider)
          .majReglages(eleveId: eleveId, mode: mode),
      annuler: () {
        if (!mounted) return;
        setState(() {
          _affiche = avant;
          _echec = true;
          _generation++;
        });
      },
    );
    _action = action;
    setState(() {
      _affiche = mode;
      _echec = false;
      _generation++;
    });
    unawaited(
      action.tenter(
        siConfirme: () => conteneur.invalidate(elevesDuFoyerProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ProfilEleveFoyer profil = widget.profil;
    // Hors ligne, l'ecriture ne peut pas aboutir : les cartes ne se pressent
    // plus et une phrase dit pourquoi (comme l'editeur de photo).
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return ColonnesFiche(
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NoteFiche(
            t.ficheEleve.interface.intro(dePrenom: deDevant(profil.prenom)),
          ),
          Ecart.vSm,
          KeyedSubtree(
            key: InterfaceElevePage.choixKey,
            child: ChoiceCardGroup(
              key: ValueKey<(InterfaceMode, int)>((_mode, _generation)),
              autoriserSaisieLibre: false,
              valeurInitiale: ReponseChoix(valeurs: <String>{_mode.name}),
              options: <OptionChoix>[
                OptionChoix(
                  valeur: InterfaceMode.enfant.name,
                  libelle: t.ficheEleve.interface.guidee,
                  icone: AppIcons.focus,
                  description: t.ficheEleve.interface.guideeDescription(
                    prenom: profil.prenom,
                  ),
                  disponible: !horsLigne,
                ),
                OptionChoix(
                  valeur: InterfaceMode.standard.name,
                  libelle: t.ficheEleve.interface.standard,
                  icone: AppIcons.tabletteOuOrdinateur,
                  description: t.ficheEleve.interface.standardDescription(
                    prenom: profil.prenom,
                  ),
                  disponible: !horsLigne,
                ),
              ],
              onChange: (ReponseChoix reponse) {
                for (final InterfaceMode mode in <InterfaceMode>[
                  InterfaceMode.enfant,
                  InterfaceMode.standard,
                ]) {
                  if (reponse.valeurs.contains(mode.name)) {
                    _choisir(mode);
                  }
                }
              },
            ),
          ),
          if (horsLigne) ...<Widget>[
            Ecart.vMd,
            Text(
              key: InterfaceElevePage.horsLigneKey,
              t.ficheEleve.interface.horsLigne,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ] else if (_echec) ...<Widget>[
            Ecart.vMd,
            Semantics(
              liveRegion: true,
              child: Text(
                t.ficheEleve.interface.echec(dePrenom: deDevant(profil.prenom)),
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ],
      ),
      annexe: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NoteFiche(t.ficheEleve.interface.politique),
          NoteFiche(
            t.ficheEleve.interface.application(
              dePrenom: deDevant(profil.prenom),
            ),
          ),
          NoteFiche(t.ficheEleve.interface.demandeEleve),
        ],
      ),
    );
  }
}

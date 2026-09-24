import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/appairage/service_appairage.dart';
import '../../../core/domain/enums.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../fiche_eleve_page.dart';
import '../formulaire_profil_eleve.dart';

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
/// **Aucun etat optimiste** : la carte retenue est celle que la relecture du
/// foyer rend apres l'ecriture.
class InterfaceElevePage extends StatelessWidget {
  /// Cree la page.
  const InterfaceElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  /// La carte « Interface guidee ».
  static const Key guideeKey = Key('ficheEleve.interface.guidee');

  /// La carte « Interface standard ».
  static const Key standardKey = Key('ficheEleve.interface.standard');

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
  bool _enCours = false;
  bool _echec = false;

  Future<void> _choisir(InterfaceMode mode) async {
    if (_enCours || mode == widget.profil.mode) {
      return;
    }
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await ref
          .read(serviceAppairageProvider)
          .majReglages(eleveId: widget.profil.eleveId, mode: mode);
      ref.invalidate(elevesDuFoyerProvider);
    } on Object {
      if (mounted) {
        setState(() => _echec = true);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
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
          NoteFiche(t.ficheEleve.interface.intro(prenom: profil.prenom)),
          Ecart.vSm,
          CarteChoixFoyer(
            key: InterfaceElevePage.guideeKey,
            icone: AppIcons.focus,
            titre: t.ficheEleve.interface.guidee,
            description: t.ficheEleve.interface.guideeDescription,
            retenue: profil.mode == InterfaceMode.enfant,
            disponible: !horsLigne,
            onPress: () => _choisir(InterfaceMode.enfant),
          ),
          Ecart.vMd,
          CarteChoixFoyer(
            key: InterfaceElevePage.standardKey,
            icone: AppIcons.tabletteOuOrdinateur,
            titre: t.ficheEleve.interface.standard,
            description: t.ficheEleve.interface.standardDescription,
            retenue: profil.mode == InterfaceMode.standard,
            disponible: !horsLigne,
            onPress: () => _choisir(InterfaceMode.standard),
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
          ] else if (_enCours || _echec) ...<Widget>[
            Ecart.vMd,
            Semantics(
              liveRegion: true,
              child: Text(
                _enCours
                    ? t.ficheEleve.interface.enCours
                    : t.ficheEleve.interface.echec,
                style: (_echec ? palette.inkAlert : palette.inkMuted).applyTo(
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
          NoteFiche(t.ficheEleve.interface.application(prenom: profil.prenom)),
          NoteFiche(t.ficheEleve.interface.demandeEleve),
        ],
      ),
    );
  }
}

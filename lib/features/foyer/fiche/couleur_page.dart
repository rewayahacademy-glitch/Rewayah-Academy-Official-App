import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/appairage/service_appairage.dart';
import '../../../core/capacites/port_accents_profils.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/accent_profil.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/identite_profil.dart';
import '../../../core/widgets/selecteur_couleur_profil.dart';
import '../../../core/widgets/skeleton.dart';
import '../fiche_eleve_page.dart';
import '../photo_eleve.dart';

/// La couleur d'un profil eleve (`/tuteur/foyer/:eleveId/couleur`), choisie
/// par le tuteur (decision du directeur du 04/10/2026, K-62 ; FI-2).
///
/// Une phrase de contexte (K-58), l'apercu du profil avec son bandeau colle
/// au bord haut de la carte (maquette 11), puis un **simple selecteur de
/// pastilles** (`SelecteurCouleurProfil`, revue du directeur du 04/10) : six
/// couleurs et « Sans couleur », la consequence dite dessous.
///
/// **Aucun etat optimiste** : la carte retenue est celle que la relecture des
/// accents rend apres l'ecriture. Frontend seulement : la source serveur
/// arrive en BR-1 (FI-BR-19) ; d'ici la, en production, la page dit que la
/// fonction n'est pas encore ouverte (`CapaciteIndisponible`).
class CouleurElevePage extends StatelessWidget {
  /// Cree la page.
  const CouleurElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  /// Le groupe des choix de couleur.
  static const Key choixKey = Key('ficheEleve.couleur.choix');

  /// L'apercu du profil.
  static const Key apercuKey = Key('ficheEleve.couleur.apercu');

  /// La phrase hors ligne.
  static const Key horsLigneKey = Key('ficheEleve.couleur.horsLigne');

  /// La phrase d'echec.
  static const Key echecKey = Key('ficheEleve.couleur.echec');

  @override
  Widget build(BuildContext context) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.couleur.titre,
      onRetour: retourVersFiche(context, eleveId),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _ChoixCouleur(profil: profil),
    );
  }
}

class _ChoixCouleur extends ConsumerStatefulWidget {
  const _ChoixCouleur({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  ConsumerState<_ChoixCouleur> createState() => _ChoixCouleurState();
}

class _ChoixCouleurState extends ConsumerState<_ChoixCouleur> {
  bool _enCours = false;
  bool _echec = false;

  Future<void> _choisir(AccentProfil? accent, AccentProfil? actuel) async {
    if (_enCours || accent == actuel) return;
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await ref
          .read(portAccentsProfilsProvider)
          .choisir(widget.profil.eleveId, accent);
      ref.invalidate(accentsProfilsProvider);
    } on Object {
      if (mounted) setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProfilEleveFoyer profil = widget.profil;
    return ColonnesFiche(
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NoteFiche(t.ficheEleve.couleur.contexte(prenom: profil.prenom)),
          Ecart.vSm,
          BlocAsynchrone<Map<String, AccentProfil>>(
            valeur: ref.watch(accentsProfilsProvider),
            onReessayer: () => ref.invalidate(accentsProfilsProvider),
            squelette: const Skeleton.liste(lignes: 4),
            construire: (Map<String, AccentProfil> accents) =>
                _contenu(context, accents),
          ),
        ],
      ),
    );
  }

  Widget _contenu(BuildContext context, Map<String, AccentProfil> accents) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ProfilEleveFoyer profil = widget.profil;
    final AccentProfil? actuel = accents[profil.eleveId];
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    // Les prenoms des autres profils, pour dire qu'une couleur est prise.
    final Map<String, String> prenoms = <String, String>{
      for (final EleveDuFoyer e
          in ref.watch(elevesDuFoyerProvider).value ?? const <EleveDuFoyer>[])
        e.id: e.prenom,
    };
    // Tous les autres profils qui l'ont, jamais le premier seul (revue
    // FI-2-R m2).
    String? priseePar(AccentProfil a) => prenomsJoints(<String>[
      for (final MapEntry<String, AccentProfil> e in accents.entries)
        if (e.key != profil.eleveId && e.value == a)
          if (prenoms[e.key] case final String p) p,
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SurfaceFiche(
          key: CouleurElevePage.apercuKey,
          child: IdentiteProfil(
            prenom: profil.prenom,
            accent: actuel,
            taille: TailleIdentite.entete,
            remontee: SurfaceFiche.marge,
            avatar: PhotoEleve(
              prenom: profil.prenom,
              cleAvatar: profil.cleAvatar,
              diametre: TailleIdentite.entete.diametre,
            ),
          ),
        ),
        Ecart.vLg,
        KeyedSubtree(
          key: CouleurElevePage.choixKey,
          child: SelecteurCouleurProfil(
            valeur: actuel,
            prenom: profil.prenom,
            prises: <AccentProfil, String>{
              for (final AccentProfil a in AccentProfil.values)
                if (priseePar(a) case final String autre) a: autre,
            },
            onChoix: horsLigne
                ? null
                : (AccentProfil? a) => unawaited(_choisir(a, actuel)),
          ),
        ),
        if (horsLigne) ...<Widget>[
          Ecart.vMd,
          Text(
            key: CouleurElevePage.horsLigneKey,
            t.ficheEleve.couleur.horsLigne,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ] else if (_echec) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              key: CouleurElevePage.echecKey,
              t.ficheEleve.couleur.echec,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Les prenoms d'une liste dits en clair : « Yusuf », « Yusuf et Aicha »,
/// « Yusuf, Aicha et Mariam » ; `null` pour une liste vide.
String? prenomsJoints(List<String> prenoms) => switch (prenoms) {
  <String>[] => null,
  <String>[final String seul] => seul,
  _ => t.ficheEleve.couleur.prenomsEt(
    premiers: prenoms.sublist(0, prenoms.length - 1).join(', '),
    dernier: prenoms.last,
  ),
};

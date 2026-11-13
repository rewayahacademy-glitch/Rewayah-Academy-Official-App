// HORLOGE-ET-LIEU, partie B (H5) : la page de la ville (`/ville`).
//
// Le tuteur et l'enseignant y sont menes tant qu'ils n'ont pas choisi leur
// ville (`villeAFournirProvider`, porte du routeur). Tant qu'il reste un
// report, « Plus tard » se montre ; sinon l'etape est dite necessaire, sans
// bouton grise. Le serveur recopie le nom, le pays, le fuseau et les
// coordonnees : le client n'envoie qu'un identifiant.
//
// Un enseignant qui change de fuseau voit ensuite « Relisez vos
// disponibilites » : elles gardent leurs instants (Q4, architecte), seule leur
// lecture change.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/lieu/choix_ville.dart';
import '../../core/lieu/lieu.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';

/// La page de la ville.
class VillePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const VillePage({super.key});

  @override
  ConsumerState<VillePage> createState() => _EtatVillePage();
}

class _EtatVillePage extends ConsumerState<VillePage> {
  Ville? _choisie;
  bool _envoi = false;
  bool _echec = false;
  bool _relire = false;

  AppRole? get _role => ref.read(sessionProvider).role;

  void _versLaRacine() {
    final AppRole? role = _role;
    GoRouter.of(context)
        .go(role == null ? Routes.racine : Routes.racinePour(role));
  }

  Future<void> _rafraichir() async {
    ref.invalidate(monHorlogeProvider);
    try {
      final EtatLieu? _ = await ref.refresh(etatLieuProvider.future);
    } on Object {
      // Lecture en echec : la porte ne bloque pas, la question se repose.
    }
  }

  Future<void> _enregistrer() async {
    final Ville? v = _choisie;
    if (v == null || _envoi) return;
    setState(() {
      _envoi = true;
      _echec = false;
    });
    try {
      final ResultatVille r = await ref
          .read(portLieuProvider)
          .enregistrer(v.id);
      await _rafraichir();
      if (!mounted) return;
      if (r.disponibilitesARelire && _role == AppRole.teacher) {
        setState(() {
          _envoi = false;
          _relire = true;
        });
        return;
      }
      _versLaRacine();
    } on Object {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = true;
      });
    }
  }

  Future<void> _plusTard() async {
    if (_envoi) return;
    setState(() {
      _envoi = true;
      _echec = false;
    });
    try {
      await ref.read(portLieuProvider).reporter();
      ref.read(villeReporteeProvider.notifier).reporter();
      await _rafraichir();
      if (!mounted) return;
      _versLaRacine();
    } on Object {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final h = t.lieu;
    if (_relire) {
      return PageShell(
        titre: h.disponibilitesTitre,
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActionPrincipale(
              libelle: h.disponibilitesLien,
              onPress: () => GoRouter.of(context).go(Routes.enseignantCreneaux),
            ),
            Ecart.vMd,
            LienFleche(
              libelle: t.commun.continuer,
              fleche: false,
              alignerEnDebut: true,
              onPress: _versLaRacine,
            ),
          ],
        ),
        child: Text(h.disponibilitesPhrase, style: textes.bodyMedium),
      );
    }
    final EtatLieu? etat = ref.watch(etatLieuProvider).value;
    final bool obligatoire = ref.watch(villeAFournirProvider);
    final bool peutReporter = obligatoire && (etat?.peutReporter ?? false);
    final bool enseignant = _role == AppRole.teacher;
    return PageShell(
      titre: h.titre,
      // Sans obligation (changer de ville), on peut revenir ; pendant l'etape
      // exigee, la page est la seule porte.
      onRetour: obligatoire ? null : _versLaRacine,
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_echec) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                h.echec,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          // Un bouton qui ne peut pas aboutir n'est pas rendu.
          if (_choisie != null)
            ActionPrincipale(
              libelle: h.enregistrer,
              onPress: () => unawaited(_enregistrer()),
              enCours: _envoi,
            ),
          if (peutReporter) ...<Widget>[
            Ecart.vMd,
            Text(
              h.plusTardPhrase,
              textAlign: TextAlign.center,
              style: textes.bodySmall,
            ),
            LienFleche(
              libelle: h.plusTard,
              fleche: false,
              onPress: () => unawaited(_plusTard()),
            ),
          ] else if (obligatoire) ...<Widget>[
            Ecart.vMd,
            Text(
              h.obligatoire,
              textAlign: TextAlign.center,
              style: textes.bodySmall,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            enseignant ? h.consigneEnseignant : h.consigneTuteur,
            style: textes.bodyMedium,
          ),
          Ecart.vXl,
          ChoixVille(
            initiale: _choisie,
            onChoisie: (Ville v) => setState(() {
              _choisie = v;
              _echec = false;
            }),
          ),
        ],
      ),
    );
  }
}

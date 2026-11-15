// Le fil des annonces de l'academie recues par la personne (ANNONCES-SIMPLES,
// directeur, 14/11/2026 : « l'annonce dans l'app d'abord »).
//
// Pose dans la page des notifications de chaque role adulte et dans le portail
// du candidat (`/attente`), dont le compte est encore en attente : un candidat
// ne lit pas la cloche, il lit ce fil. Un mineur n'a pas de fil : le serveur
// le refuse (`com_mes_annonces`), et le bloc ne rend alors rien.
//
// Une annonce montree est comptee « vue » (`com_annonce_vue`) : c'est la
// mesure que la direction lit sur la page des communications. La pastille
// « Nouvelle » suit ce que le serveur a dit a la lecture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'port_annonces_direction.dart';

/// Le fil des annonces recues ; rien quand il n'y en a aucune.
class AnnoncesRecues extends ConsumerStatefulWidget {
  /// Cree le fil. [ecartApres] separe le fil de ce qui le suit, quand il est
  /// rendu.
  const AnnoncesRecues({super.key, this.ecartApres = Ecart.vLg});

  /// L'ecart pose sous le fil quand il est rendu.
  final Widget ecartApres;

  /// Le plus d'annonces montrees d'un coup.
  static const int maximum = 5;

  /// La cle du fil, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('annonces-recues');

  /// La cle de la carte d'une annonce, pour les tests.
  static ValueKey<String> cleAnnonce(String id) =>
      ValueKey<String>('annonce-recue-$id');

  @override
  ConsumerState<AnnoncesRecues> createState() => _AnnoncesRecuesState();
}

class _AnnoncesRecuesState extends ConsumerState<AnnoncesRecues> {
  /// Les annonces deja comptees « vues » depuis cet ecran.
  final Set<String> _vues = <String>{};

  void _compterVues(List<AnnonceRecue> montrees) {
    final PortAnnoncesDirection port = ref.read(portAnnoncesDirectionProvider);
    for (final AnnonceRecue a in montrees) {
      if (a.vue || !_vues.add(a.id)) continue;
      // Un echec n'empeche pas la lecture : l'annonce sera recomptee a la
      // prochaine ouverture.
      unawaited(
        port.marquerVue(a.id).catchError((Object _) {
          _vues.remove(a.id);
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = t.com.annonces.fil;
    final AsyncValue<List<AnnonceRecue>> lues = ref.watch(mesAnnoncesProvider);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Pas de source, pas de fil (mineur, migration absente) : rien.
    if (lues.error is CapaciteIndisponible) return const SizedBox.shrink();
    if (lues.hasError) {
      return Column(
        key: AnnoncesRecues.cle,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            f.echec,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          LienFleche(
            libelle: t.commun.etats.actions.reessayer,
            alignerEnDebut: true,
            onPress: () => ref.invalidate(mesAnnoncesProvider),
          ),
          widget.ecartApres,
        ],
      );
    }
    if (!lues.hasValue || lues.requireValue.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<AnnonceRecue> montrees = lues.requireValue
        .take(AnnoncesRecues.maximum)
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _compterVues(montrees);
    });
    return Column(
      key: AnnoncesRecues.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            f.titre,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vMd,
        PileCartes(
          children: <Widget>[
            for (final AnnonceRecue a in montrees)
              AppCard(
                key: AnnoncesRecues.cleAnnonce(a.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!a.vue) ...<Widget>[
                      StatusPill(libelle: f.nouvelle, ton: TonEtat.accent),
                      Ecart.vSm,
                    ],
                    Text(
                      a.titre,
                      style: palette.inkStrong.applyTo(
                        textes.titleSmall ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vXs,
                    Text(
                      a.texte,
                      style: palette.inkStrong.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vSm,
                    Text(
                      // HEURES-PROFIL H2 : a l'heure du profil.
                      f.date(
                        date: dateCourte(chezMoi(a.publieeLe)),
                        heure: heureMinute(chezMoi(a.publieeLe)),
                      ),
                      style: palette.inkMuted.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        widget.ecartApres,
      ],
    );
  }
}

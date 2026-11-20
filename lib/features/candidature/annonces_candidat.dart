// ACCUEIL-CANDIDAT (directeur, 20/11/2026) : la rubrique « Annonces » de
// l'onglet Messages du candidat. Les annonces detaillees EN GRILLE, chacune
// avec sa pastille de priorite.
//
// Source : le fil d'ANNONCES-SIMPLES (`mesAnnoncesProvider`,
// `com_mes_annonces`), tel quel. Ce que le serveur rend pour une annonce :
// id, titre, texte, publiee_le, vue. AUCUNE priorite :
// - « Nouvelle » se lit sur `vue` (pas encore vue par ce candidat) ;
// - « Urgent » a sa place prete ([PrioriteAnnonce.urgente]) mais ne
//   s'affiche jamais tant que le serveur ne rend pas de priorite (champ
//   manquant : une colonne `priorite` sur `public.com_annonces`, rendue par
//   `com_mes_annonces`). Rien n'est devine ici.
//
// Etats : chargement (squelette), contenu, vide (une phrase), erreur et hors
// connexion (une phrase vraie et « Reessayer »), capacite indisponible (la
// phrase du vide). Toucher une carte ouvre l'annonce entiere dans une feuille
// et la compte « vue ».
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../com_annonces/port_annonces_direction.dart';
import '../suivi_foyer/filtres_historique.dart';

/// La priorite d'une annonce, telle qu'elle se montre.
enum PrioriteAnnonce {
  /// Urgente : jamais rendue tant que le serveur ne dit pas de priorite.
  urgente,

  /// Pas encore vue par la personne.
  nouvelle,

  /// Rien a signaler.
  aucune;

  /// La priorite de [a], d'apres ce que le serveur rend (`vue` seulement).
  static PrioriteAnnonce de(AnnonceRecue a) =>
      a.vue ? PrioriteAnnonce.aucune : PrioriteAnnonce.nouvelle;
}

/// La rubrique Annonces.
class AnnoncesCandidat extends ConsumerStatefulWidget {
  /// Cree la rubrique.
  const AnnoncesCandidat({super.key});

  /// La cle de la grille.
  static const Key cleGrille = ValueKey<String>('annonces-candidat-grille');

  /// La cle de la phrase du vide.
  static const Key cleVide = ValueKey<String>('annonces-candidat-vide');

  /// La cle de la carte de l'annonce [id].
  static Key cleCarte(String id) => ValueKey<String>('annonce-candidat-$id');

  /// La cle de la pastille de priorite de l'annonce [id].
  static Key clePastille(String id) =>
      ValueKey<String>('annonce-candidat-pastille-$id');

  @override
  ConsumerState<AnnoncesCandidat> createState() => _EtatAnnoncesCandidat();
}

class _EtatAnnoncesCandidat extends ConsumerState<AnnoncesCandidat> {
  void _ouvrir(AnnonceRecue a) {
    unawaited(
      AppBottomSheet.ouvrir<void>(
        context,
        titre: a.titre,
        constructeur: (BuildContext c) => _AnnonceEntiere(annonce: a),
      ),
    );
    if (a.vue) return;
    // Un echec n'empeche pas la lecture : l'annonce reste « nouvelle » et
    // sera recomptee a la prochaine ouverture.
    unawaited(
      ref
          .read(portAnnoncesDirectionProvider)
          .marquerVue(a.id)
          .then((_) => ref.invalidate(mesAnnoncesProvider))
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AnnonceRecue>> lues = ref.watch(mesAnnoncesProvider);
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final m = t.recrutement.accueil.messages.annonces;
    if (!lues.hasValue && !lues.hasError) {
      return const Skeleton.liste(lignes: 3);
    }
    if (lues.error is CapaciteIndisponible ||
        (lues.hasValue && lues.requireValue.isEmpty)) {
      return Text(m.vide, key: AnnoncesCandidat.cleVide, style: muet);
    }
    if (!lues.hasValue) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      return VueEtatCommunication(
        etat: horsLigne
            ? EtatCommunication.horsLigne
            : EtatCommunication.erreur,
        onReessayer: () => ref.invalidate(mesAnnoncesProvider),
      );
    }
    final List<AnnonceRecue> annonces = lues.requireValue;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool agrandi =
            MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
        // La grille : deux colonnes au telephone, trois a partir de 900 ;
        // une seule pour un texte tres agrandi. La plus recente prend toute
        // la largeur, en tete.
        final int colonnes = agrandi
            ? 1
            : c.maxWidth >= 900
            ? 3
            : 2;
        final List<List<AnnonceRecue>> rangees = <List<AnnonceRecue>>[
          <AnnonceRecue>[annonces.first],
          for (int i = 1; i < annonces.length; i += colonnes)
            annonces.sublist(i, math.min(i + colonnes, annonces.length)),
        ];
        return Column(
          key: AnnoncesCandidat.cleGrille,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: <Widget>[
            for (final (int r, List<AnnonceRecue> rangee) in rangees.indexed)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: <Widget>[
                    for (final AnnonceRecue a in rangee)
                      Expanded(
                        child: _CarteAnnonce(
                          annonce: a,
                          large: r == 0,
                          onPress: () => _ouvrir(a),
                        ),
                      ),
                    // Une rangee incomplete garde la largeur de ses colonnes.
                    if (r > 0)
                      for (int v = rangee.length; v < colonnes; v++)
                        const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

String _date(AnnonceRecue a) => t.com.annonces.fil.date(
  // HEURES-PROFIL H2 : a l'heure du profil.
  date: dateCourte(chezMoi(a.publieeLe)),
  heure: heureMinute(chezMoi(a.publieeLe)),
);

/// La pastille d'une priorite, ou rien.
class _PastillePriorite extends StatelessWidget {
  const _PastillePriorite({required this.priorite, super.key});

  final PrioriteAnnonce priorite;

  @override
  Widget build(BuildContext context) => switch (priorite) {
    PrioriteAnnonce.urgente => StatusPill(
      libelle: t.com.socle.composants.badge.urgent,
      ton: TonEtat.alerte,
    ),
    PrioriteAnnonce.nouvelle => StatusPill(
      libelle: t.com.annonces.fil.nouvelle,
      ton: TonEtat.accent,
    ),
    PrioriteAnnonce.aucune => const SizedBox.shrink(),
  };
}

/// Une carte de la grille : la pastille, le titre, le debut du texte, la
/// date. Toute la carte se touche.
class _CarteAnnonce extends StatelessWidget {
  const _CarteAnnonce({
    required this.annonce,
    required this.large,
    required this.onPress,
  });

  final AnnonceRecue annonce;
  final bool large;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final PrioriteAnnonce p = PrioriteAnnonce.de(annonce);
    return AppCard(
      key: AnnoncesCandidat.cleCarte(annonce.id),
      onPress: onPress,
      libelleSemantique: <String>[
        if (p == PrioriteAnnonce.nouvelle) t.com.annonces.fil.nouvelle,
        t.recrutement.accueil.messages.annonces.lire(titre: annonce.titre),
        _date(annonce),
      ].join('. '),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (p != PrioriteAnnonce.aucune) ...<Widget>[
              _PastillePriorite(
                key: AnnoncesCandidat.clePastille(annonce.id),
                priorite: p,
              ),
              Ecart.vSm,
            ],
            Text(
              annonce.titre,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: palette.inkStrong.applyTo(
                (large ? textes.titleMedium : textes.titleSmall) ??
                    const TextStyle(),
              ),
            ),
            Ecart.vXs,
            Text(
              annonce.texte,
              maxLines: large ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            const Spacer(),
            Ecart.vSm,
            Text(
              _date(annonce),
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'annonce entiere, dans la feuille.
class _AnnonceEntiere extends StatelessWidget {
  const _AnnonceEntiere({required this.annonce});

  final AnnonceRecue annonce;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _date(annonce),
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        Text(
          annonce.texte,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

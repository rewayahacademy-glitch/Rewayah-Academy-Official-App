import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/groupe_reglages.dart';

/// Ce que les deux listes d'appareils lisent : les profils eleves du foyer et
/// leurs appareils (`profils_du_foyer_v`, `mes_appareils_v`).
typedef DonneesAppareilsFoyer = ({
  List<EleveDuFoyer> eleves,
  List<AppareilAppaire> appareils,
});

/// Les deux lectures du foyer, reunies pour un seul etat de chargement.
///
/// Relire l'une ou l'autre (retrait d'un appareil, « Reessayer ») relit cette
/// vue ; la valeur deja la reste affichee pendant la relecture.
final FutureProvider<DonneesAppareilsFoyer> donneesAppareilsFoyerProvider =
    FutureProvider<DonneesAppareilsFoyer>((Ref ref) async {
      final List<EleveDuFoyer> eleves = await ref.watch(
        elevesDuFoyerProvider.future,
      );
      final List<AppareilAppaire> appareils = await ref.watch(
        appareilsDuFoyerProvider.future,
      );
      return (eleves: eleves, appareils: appareils);
    });

/// Relit les deux sources de [donneesAppareilsFoyerProvider].
void relireAppareilsFoyer(WidgetRef ref) {
  ref
    ..invalidate(elevesDuFoyerProvider)
    ..invalidate(appareilsDuFoyerProvider);
}

/// Les appareils **actifs** de [eleveId], du plus ancien au plus recent.
///
/// Le tri est fait ici, en sens explicite (date de connexion croissante, puis
/// identifiant) : la lecture `mes_appareils_v` appelle `.order('paired_at')`
/// sans preciser `ascending` (`service_appairage.dart:212`, fichier du
/// coordinateur, demande D-2), et l'ecran ne doit pas dependre du sens par
/// defaut du serveur. Un appareil retire ne compte plus et n'est pas liste.
List<AppareilAppaire> appareilsActifsDe(
  String eleveId,
  List<AppareilAppaire> appareils,
) {
  final List<AppareilAppaire> retenus = appareils
      .where((AppareilAppaire a) => a.profilId == eleveId && a.actif)
      .toList();
  retenus.sort((AppareilAppaire a, AppareilAppaire b) {
    final int parDate = a.appaireA.compareTo(b.appaireA);
    return parDate != 0 ? parDate : a.id.compareTo(b.id);
  });
  return retenus;
}

/// Les profils eleves dans l'ordre alphabetique des prenoms (sens croissant
/// explicite, la vue n'en garantit aucun).
List<EleveDuFoyer> elevesParPrenom(List<EleveDuFoyer> eleves) =>
    <EleveDuFoyer>[...eleves]..sort((EleveDuFoyer a, EleveDuFoyer b) {
      final int parPrenom = a.prenom.toLowerCase().compareTo(
        b.prenom.toLowerCase(),
      );
      return parPrenom != 0 ? parPrenom : a.id.compareTo(b.id);
    });

/// Le nom lisible d'un appareil, d'apres la plateforme que le serveur a
/// retenue (`android`, `ios`, `web`, `windows`). Jamais la valeur brute.
///
/// Le serveur ne rend pas de nom d'appareil que l'on puisse ecrire
/// (DB-APP-05) : « iPad de Mariam » n'est pas representable.
String libellePlateforme(String plateforme) {
  final p = t.appareils.plateforme;
  return switch (plateforme.toLowerCase()) {
    'android' => p.android,
    'ios' => p.ios,
    'web' => p.web,
    'windows' => p.windows,
    _ => p.inconnue,
  };
}

/// L'icone d'une plateforme.
AppIcon iconePlateforme(String plateforme) =>
    switch (plateforme.toLowerCase()) {
      'web' || 'windows' => AppIcons.tabletteOuOrdinateur,
      _ => AppIcons.appareil,
    };

/// Une date lisible, au fuseau de l'appareil : « 18 septembre 2026, 14:20 ».
String dateLisible(DateTime quand) {
  final DateTime local = quand.toLocal();
  final String mois = t.commun.dates.mois[local.month - 1];
  final String heure =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '${local.day} $mois ${local.year}, $heure';
}

/// Le resume des appareils d'un profil, pour sa ligne dans les appareils du
/// foyer : nombre et noms, sans aucun plafond fige (DB-APP-04).
String resumeAppareils(List<AppareilAppaire> actifs) {
  final f = t.appareils.foyer;
  if (actifs.isEmpty) {
    return f.aucunAppareil;
  }
  final List<String> noms = actifs
      .map((AppareilAppaire a) => libellePlateforme(a.plateforme))
      .toList();
  if (actifs.length == 1) {
    return f.unAppareil(nom: noms.single);
  }
  return f.plusieursAppareils(nombre: actifs.length, noms: noms.join(', '));
}

/// La liste des appareils d'un profil eleve : UN groupe a filets (carte
/// groupee, composant partage), une ligne par appareil avec son action de
/// retrait.
///
/// [onRetirer] a `null` : aucun bouton de retrait (hors ligne, un bouton qui
/// ne peut pas aboutir n'est pas rendu). [retraitEnCours] : l'appareil dont
/// le retrait est parti, son bouton montre l'attente et les autres se taisent.
class ListeAppareilsEleve extends StatelessWidget {
  /// Cree la liste.
  const ListeAppareilsEleve({
    required this.appareils,
    required this.onRetirer,
    super.key,
    this.retraitEnCours,
  });

  /// La cle du groupe, pour les tests et les captures.
  static const Key groupeKey = ValueKey<String>('appareils-eleve-groupe');

  /// La cle du bouton de retrait d'un appareil.
  static Key retirerKey(String appareilId) =>
      ValueKey<String>('appareils-eleve-retirer-$appareilId');

  /// Les appareils actifs, deja tries.
  final List<AppareilAppaire> appareils;

  /// Le retrait demande pour un appareil.
  final void Function(AppareilAppaire appareil)? onRetirer;

  /// L'appareil dont le retrait est en cours.
  final String? retraitEnCours;

  @override
  Widget build(BuildContext context) {
    final e = t.appareils.eleve;
    return GroupeReglages(
      key: groupeKey,
      titre: e.groupe,
      lignes: <LigneRubrique>[
        for (final AppareilAppaire appareil in appareils)
          LigneRubrique(
            icone: iconePlateforme(appareil.plateforme),
            libelle: libellePlateforme(appareil.plateforme),
            legende: <String>[
              e.connecteLe(date: dateLisible(appareil.appaireA)),
              if (appareil.derniereUtilisation case final DateTime d)
                e.utiliseLe(date: dateLisible(d))
              else
                e.jamaisUtilise,
            ].join('\n'),
            controle: onRetirer == null
                ? null
                : _BoutonRetirer(
                    appareil: appareil,
                    enCours: retraitEnCours == appareil.id,
                    // Un seul retrait a la fois : les autres boutons ne
                    // partent pas pendant l'attente.
                    onPress: retraitEnCours == null
                        ? () => onRetirer!(appareil)
                        : null,
                  ),
          ),
      ],
    );
  }
}

class _BoutonRetirer extends StatelessWidget {
  const _BoutonRetirer({
    required this.appareil,
    required this.enCours,
    required this.onPress,
  });

  final AppareilAppaire appareil;
  final bool enCours;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: t.appareils.eleve.retirerLibelle(
        appareil: libellePlateforme(appareil.plateforme),
      ),
      excludeSemantics: true,
      button: true,
      enabled: onPress != null,
      child: ActionPrincipale(
        key: ListeAppareilsEleve.retirerKey(appareil.id),
        libelle: t.appareils.revoquer,
        niveau: NiveauAction.secondaire,
        pleineLargeur: false,
        enCours: enCours,
        onPress: onPress,
      ),
    );
  }
}

/// Un encart d'explication : une icone, un titre, une phrase. Pas une action.
class EncartAppareils extends StatelessWidget {
  /// Cree l'encart.
  const EncartAppareils({
    required this.icone,
    required this.titre,
    required this.phrase,
    super.key,
  });

  /// L'icone.
  final AppIcon icone;

  /// Le titre.
  final String titre;

  /// La phrase.
  final String phrase;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
            child: Icon(icone.repos),
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titre,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
                Ecart.vXs,
                Text(
                  phrase,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

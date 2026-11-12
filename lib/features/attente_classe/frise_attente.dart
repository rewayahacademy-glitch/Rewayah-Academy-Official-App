/// SUIVI-ATTENTE (S1, S7) : la frise verticale a cinq etapes.
///
/// Etape en cours mise en avant (une seule carte, en lavis d'accent) ; etapes
/// franchies cochees avec leur date ; etapes a venir estompees. Au
/// franchissement d'une etape, son marqueur change par un fondu court (jeton
/// `AppMouvement.apparition`, courbe `entree`, supprime si l'appareil demande
/// de reduire les animations). **Aucune barre qui avance seule, aucun
/// pourcentage, aucune animation qui fait croire a un progres** : un
/// marqueur ne change que lorsque le serveur a change l'etat de l'etape.
///
/// Pas de confettis, de points, de badges ni de classement. Un etat n'est
/// jamais signale par la couleur seule : icone et mot d'etat l'accompagnent.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/attente_classe/modele_attente.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import 'libelles_attente.dart';

/// La frise d'un suivi. [apres] : ce qui se pose sous une etape donnee
/// (la carte de l'enseignant sous l'etape 4).
class FriseAttente extends StatelessWidget {
  /// Cree la frise.
  const FriseAttente({required this.suivi, this.apres, super.key});

  /// Le suivi montre.
  final SuiviAttente suivi;

  /// Un contenu pose sous l'etape [numero], ou `null`.
  final Widget? Function(int numero)? apres;

  /// La cle de la ligne de l'etape [numero].
  static Key cleEtape(int numero) => ValueKey<String>('attente-etape-$numero');

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('attente-frise'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final EtapeAttente e in suivi.etapes)
        _LigneEtape(
          key: cleEtape(e.numero),
          suivi: suivi,
          etape: e,
          derniere: e.numero == nombreEtapesAttente,
          dessous: apres?.call(e.numero),
        ),
    ],
  );
}

class _LigneEtape extends StatelessWidget {
  const _LigneEtape({
    required this.suivi,
    required this.etape,
    required this.derniere,
    this.dessous,
    super.key,
  });

  final SuiviAttente suivi;
  final EtapeAttente etape;
  final bool derniere;
  final Widget? dessous;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppInkColor secondaire = palette.encreSecondaireSur(
      palette.surfaceCanvas,
    );
    final bool enCours = etape.etat == EtatEtapeAttente.enCours;
    final bool aVenir = etape.etat == EtatEtapeAttente.aVenir;
    final AppInkColor encreMarqueur = switch (etape.etat) {
      EtatEtapeAttente.fait => palette.inkSuccess,
      EtatEtapeAttente.enCours => palette.inkAccent,
      EtatEtapeAttente.aVenir => secondaire,
    };
    final AppIcon icone = switch (etape.etat) {
      EtatEtapeAttente.fait => AppIcons.succes,
      EtatEtapeAttente.enCours => AppIcons.horloge,
      EtatEtapeAttente.aVenir => AppIcons.attente,
    };
    final String nom = nomEtape(etape.numero);
    final String? dit = phraseEtape(suivi, etape);
    final String? date = dateEtape(etape);
    final String? depuis = depuisEtape(suivi, etape);
    // L'etape 5 franchie dit le jour du premier cours, en gros.
    final String? premier = etape.numero == nombreEtapesAttente && !aVenir
        ? phrasePremierCours(suivi)
        : null;
    final List<String> delai = enCours && etape.numero == 2
        ? phrasesDelai(suivi)
        : const <String>[];
    final DateTime? change = suivi.creneauChangeLe;
    final String? changement = etape.numero == 3 && change != null
        ? t.suiviAttente.changement(date: jourDateCourt(change))
        : null;

    final TextStyle titre = (enCours ? palette.inkAccent : palette.inkStrong)
        .applyTo(
          (enCours ? textes.titleMedium : textes.titleSmall) ??
              const TextStyle(),
        )
        .copyWith(
          color: aVenir ? secondaire.applyTo(const TextStyle()).color : null,
        );
    final TextStyle detail = secondaire.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle corps = (aVenir ? secondaire : palette.inkStrong).applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    final Widget contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(nom, style: titre),
        Text(libelleEtatEtape(etape.etat), style: detail),
        if (date != null)
          Text(
            date,
            key: ValueKey<String>('attente-date-${etape.numero}'),
            style: detail,
          ),
        if (depuis != null)
          Text(
            depuis,
            key: ValueKey<String>('attente-depuis-${etape.numero}'),
            style: detail,
          ),
        if (dit != null) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(
            dit,
            key: ValueKey<String>('attente-dit-${etape.numero}'),
            style: corps,
          ),
        ],
        if (premier != null) ...<Widget>[
          Ecart.vSm,
          Text(
            premier,
            key: const ValueKey<String>('attente-premier-cours'),
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ],
        for (final (int i, String p) in delai.indexed) ...<Widget>[
          Ecart.vXs,
          Text(
            p,
            key: ValueKey<String>('attente-delai-$i'),
            style: i == delai.length - 1 && suivi.delai?.depasse == true
                ? palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  )
                : detail,
          ),
        ],
        if (changement != null) ...<Widget>[
          Ecart.vSm,
          Text(
            changement,
            key: const ValueKey<String>('attente-changement'),
            style: corps,
          ),
        ],
        if (dessous != null) ...<Widget>[Ecart.vMd, dessous!],
      ],
    );

    final Widget corpsLigne = enCours
        ? AppCard(
            key: ValueKey<String>('attente-en-cours-${etape.numero}'),
            surface: palette.washAccent,
            child: contenu,
          )
        : contenu;

    final String etiquette = <String>[
      t.suiviAttente.etapeSurTotal(
        n: etape.numero,
        total: nombreEtapesAttente,
        etape: nom,
      ),
      libelleEtatEtape(etape.etat),
      ?date,
      ?dit,
    ].join(', ');

    return Semantics(
      label: etiquette,
      container: true,
      explicitChildNodes: dessous != null,
      excludeSemantics: dessous == null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: AppSpacing.xxl,
              child: Column(
                children: <Widget>[
                  IconTheme(
                    data: encreMarqueur.asIconTheme(size: AppSpacing.xxl),
                    child: ExcludeSemantics(
                      child: AnimatedSwitcher(
                        duration: AppMouvement.duree(
                          context,
                          AppMouvement.apparition,
                        ),
                        switchInCurve: AppMouvement.entree,
                        switchOutCurve: AppMouvement.sortie,
                        child: Icon(
                          icone.resoudre(selectionne: !aVenir),
                          key: ValueKey<String>(
                            'attente-marqueur-${etape.numero}-${etape.etat.name}',
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!derniere)
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            start: palette.borderStrong.asBorderSide(),
                          ),
                        ),
                        child: const SizedBox(width: 0),
                      ),
                    ),
                ],
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: derniere ? 0 : AppSpacing.lg),
                child: corpsLigne,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';

/// L'explication de premiere utilisation de l'observation (maquette V8 M2,
/// « Un apercu de son apprentissage »), aussi ouverte par « Comment ca
/// marche ? » depuis la classe.
///
/// **Presentation seule, aucun provider, aucun appel.** Les chiffres arrivent
/// deja ecrits ([regle], [restantes]) a partir de la politique effective et du
/// budget du serveur ; le widget n'en suppose aucun. Le compteur de visite
/// n'existe pas ici : il ne demarre qu'une fois l'entree confirmee par le
/// serveur, dans la salle.
///
/// Composition de M2, dans son ordre : trois points a medaillon d'accent, un
/// filet, des conseils discrets, l'encart « informes », l'action dominante
/// « Observer maintenant » et « Pas maintenant ». Le titre et le disque retour
/// sont portes par la page. Un conseil de plus que M2 (visite ecourtee), exige
/// par le directeur (`03` section 1 bis-4).
class ExplicationPremiereVisite extends StatelessWidget {
  /// Cree l'explication.
  const ExplicationPremiereVisite({
    required this.regle,
    required this.onPasMaintenant,
    required this.libelleRetour,
    super.key,
    this.restantes,
    this.afficherRevenir = true,
    this.onObserver,
    this.indisponibilite,
    this.enCours = false,
    this.connexionProlongee,
  });

  /// La regle, ecrite depuis le serveur : « 2 visites de 2 minutes ».
  final String regle;

  /// Les visites restantes, ecrites depuis le serveur : « 1/2 visite restante
  /// pour cette seance ». `null` : non affichees (aucune visite consommee, la
  /// regle suffit, comme sur M2).
  final String? restantes;

  /// Vrai quand une visite restera apres celle-ci : le conseil « revenez plus
  /// tard » n'a de sens qu'avec une visite suivante.
  final bool afficherRevenir;

  /// L'entree. `null` : aucune entree possible, le bouton n'est pas rendu (un
  /// bouton qui ne peut pas aboutir n'est pas grise, il n'existe pas).
  final VoidCallback? onObserver;

  /// Le retour a la classe, sans rien consommer.
  final VoidCallback onPasMaintenant;

  /// Le libelle du retour quand aucune entree n'est possible : « Retour a la
  /// classe », ou « Retour a l'accueil » quand la classe n'est pas connue.
  final String libelleRetour;

  /// Le motif qui empeche l'entree, deja rendu (un bloc d'etat), a la place de
  /// l'action dominante.
  final Widget? indisponibilite;

  /// Vrai pendant que le serveur verifie l'entree : l'action attend, et le
  /// retour n'est plus propose (une demande en vol ne se laisse pas en plan :
  /// l'intervalle serait ouvert sans personne pour le fermer, DB-OBS-03).
  final bool enCours;

  /// Ce qui se dit quand la verification tarde. `null` : rien.
  final Widget? connexionProlongee;

  @override
  Widget build(BuildContext context) {
    final e = t.tc.observation.explication;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Point(icone: AppIcons.attente, titre: regle, phrase: e.regleDetail),
        Ecart.vXl,
        _Point(
          icone: AppIcons.libelleAudio,
          titre: e.ecoute,
          phrase: e.ecouteDetail,
        ),
        Ecart.vXl,
        _Point(
          icone: AppIcons.masquer,
          titre: e.sansMedia,
          phrase: e.sansMediaDetail,
        ),
        Ecart.vXl,
        const _Filet(),
        Ecart.vXl,
        if (afficherRevenir) ...<Widget>[
          _Conseil(icone: AppIcons.reconnexion, phrase: e.revenir),
          Ecart.vLg,
        ],
        _Conseil(icone: AppIcons.sortie, phrase: e.ecourtee),
        Ecart.vLg,
        _Conseil(icone: AppIcons.foyer, phrase: e.sansIntervenir),
        Ecart.vXl,
        _Encart(phrase: e.informes),
        Ecart.vXxl,
        if (indisponibilite != null) ...<Widget>[
          indisponibilite!,
          Ecart.vXl,
          ActionPrincipale(
            libelle: libelleRetour,
            onPress: onPasMaintenant,
            fleche: true,
          ),
        ] else ...<Widget>[
          if (restantes != null) ...<Widget>[
            Text(
              restantes!,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vMd,
          ],
          if (onObserver != null)
            ActionPrincipale(
              libelle: e.observer,
              onPress: onObserver,
              enCours: enCours,
              fleche: true,
            ),
          Ecart.vSm,
          if (enCours) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                t.tc.observation.connexion.enCours,
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            if (connexionProlongee != null) ...<Widget>[
              Ecart.vMd,
              connexionProlongee!,
            ],
          ] else
            ActionPrincipale(
              libelle: e.pasMaintenant,
              onPress: onPasMaintenant,
              niveau: NiveauAction.tertiaire,
            ),
        ],
      ],
    );
  }
}

/// Un point de l'explication : medaillon d'accent, titre, phrase (V8 M2).
class _Point extends StatelessWidget {
  const _Point({
    required this.icone,
    required this.titre,
    required this.phrase,
  });

  final AppIcon icone;
  final String titre;
  final String phrase;

  /// Diametre du medaillon : 48 (maquette 50 a 54 px, sur une planche environ
  /// 1,1 fois plus dense qu'un vrai 390).
  static const double diametre = AppSpacing.titreEcran;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: diametre,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.washAccent.background,
                ),
                child: Center(
                  child: IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                    child: Icon(icone.repos),
                  ),
                ),
              ),
            ),
          ),
          Ecart.hLg,
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

/// Un conseil discret : petit medaillon neutre, phrase attenuee (V8 M2).
class _Conseil extends StatelessWidget {
  const _Conseil({required this.icone, required this.phrase});

  final AppIcon icone;
  final String phrase;

  /// Diametre du petit medaillon : 32.
  static const double diametre = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Le petit medaillon s'aligne sous le grand : meme colonne d'icones.
        SizedBox(
          width: _Point.diametre,
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: diametre,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.surfaceSunken.background,
                  ),
                  child: Center(
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
                      child: Icon(icone.repos),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Ecart.hLg,
        Expanded(
          child: Text(
            phrase,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

/// L'encart doux « Votre enfant et son enseignant sont informes » (V8 M2).
class _Encart extends StatelessWidget {
  const _Encart({required this.phrase});

  final String phrase;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: palette.washAccent.decoration(
        borderRadius: AppRadius.arrondiSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ExcludeSemantics(
              child: IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.controleQualite.repos),
              ),
            ),
            Ecart.hMd,
            Flexible(
              child: Text(
                phrase,
                style: palette.washAccent.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le filet qui separe les points des conseils (V8 M2).
class _Filet extends StatelessWidget {
  const _Filet();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: AppPalette.of(context).borderHairline.asBorderSide()),
    ),
    child: const SizedBox(width: double.infinity),
  );
}

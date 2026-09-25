import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/libelles_observation.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';

/// Ce que la classe peut encore offrir apres la visite, relu aupres du
/// serveur : jamais deduit du compteur local.
sealed class RestantesApresVisite {
  const RestantesApresVisite();
}

/// La relecture est en cours.
final class RestantesEnLecture extends RestantesApresVisite {
  /// Cree l'etat.
  const RestantesEnLecture();
}

/// La relecture a echoue (reseau, serveur) : rien n'est suppose.
final class RestantesInconnues extends RestantesApresVisite {
  /// Cree l'etat.
  const RestantesInconnues();
}

/// Le serveur a repondu.
final class RestantesLues extends RestantesApresVisite {
  /// Cree l'etat.
  const RestantesLues({required this.nombre, this.dureeParVisite});

  /// Visites restantes pour la seance, jamais negatives.
  final int nombre;

  /// Duree de la prochaine visite, telle que le serveur la donne. `null` :
  /// non lue (la phrase se passe alors de duree).
  final Duration? dureeParVisite;
}

/// La fin d'une visite d'observation (maquette V8 M5, « Votre premiere visite
/// est terminee ») et ses variantes derivees (manifeste section 6.3 ; releve
/// V7, noeuds N2, N4, N5, N6) : sortie volontaire, duree atteinte, fin de
/// seance, visites epuisees, observation interrompue.
///
/// **Presentation seule, aucun provider, aucun appel.** La page lui passe la
/// fin publiee par le moteur de visite, le rang de la visite, et les visites
/// restantes RELUES aupres du serveur apres la fermeture de l'intervalle
/// (« Apres : afficher le nombre reel », mandat observation section 5).
///
/// Composition de M5, dans son ordre : cercle heros (oeil et pastille), titre,
/// phrase, encart a medaillon (visites restantes), action dominante « Retour a
/// la classe -> », lien « Voir mes observations ». Ni en-tete ni navigation :
/// la seule sortie est l'action, et le lien vers l'Historique.
class ResultatVisite extends StatelessWidget {
  /// Cree l'ecran de fin.
  const ResultatVisite({
    required this.fin,
    required this.restantes,
    required this.libelleRetour,
    required this.onRetour,
    required this.onObservations,
    super.key,
    this.rang,
    this.derniere = false,
    this.prenomEnfant,
    this.sortieConfirmee = true,
  });

  /// Pourquoi la visite s'est terminee.
  final FinDeVisite fin;

  /// Les visites restantes, relues aupres du serveur.
  final RestantesApresVisite restantes;

  /// Le rang de la visite qui vient de finir (1 = la premiere), selon le
  /// serveur. `null` : inconnu.
  final int? rang;

  /// Vrai quand le serveur avait annonce cette visite comme la derniere de la
  /// seance.
  final bool derniere;

  /// Le prenom de l'enfant observe, quand la salle l'a donne.
  final String? prenomEnfant;

  /// Faux quand le serveur n'a pas confirme la fermeture de l'intervalle.
  final bool sortieConfirmee;

  /// « Retour a la classe », ou « Retour a l'accueil » quand la classe n'est
  /// pas connue.
  final String libelleRetour;

  /// Le retour a la classe, avec le contexte de l'enfant.
  final VoidCallback onRetour;

  /// L'Historique, segment Observations (maquette D2).
  final VoidCallback onObservations;

  bool get _interrompue =>
      fin == FinDeVisite.deconnexion || fin == FinDeVisite.revocationServeur;

  bool get _seanceFinie => fin == FinDeVisite.seanceTerminee;

  String get _titre {
    final r = t.tc.observation.resultat;
    if (_interrompue) {
      return r.interrompue;
    }
    if (_seanceFinie) {
      return t.tc.observation.disponibilite.seanceTermineeTitre;
    }
    if (fin == FinDeVisite.quotaAtteint) {
      return r.dureeAtteinte;
    }
    if (derniere) {
      return r.derniereTerminee;
    }
    return rang == 1 ? r.premiereTerminee : r.terminee;
  }

  String get _phrase {
    final r = t.tc.observation.resultat;
    if (_interrompue) {
      return libelleFinVisite(fin);
    }
    if (_seanceFinie) {
      return r.prochaineSeance;
    }
    final String? prenom = prenomEnfant;
    return prenom == null || prenom.isEmpty
        ? r.continueSansPrenom
        : r.continuePour(prenom: prenom);
  }

  /// L'encart des visites restantes. `null` apres la fin de la seance : il ne
  /// reste rien a revenir voir, la phrase le dit deja.
  String? get _encart {
    if (_seanceFinie) {
      return null;
    }
    final r = t.tc.observation.resultat;
    return switch (restantes) {
      RestantesEnLecture() => r.verification,
      RestantesInconnues() => r.inconnues,
      RestantesLues(:final int nombre, :final Duration? dureeParVisite) =>
        _phraseRestantes(nombre, dureeParVisite),
    };
  }

  static String _phraseRestantes(int nombre, Duration? duree) {
    final r = t.tc.observation.resultat;
    if (nombre <= 0) {
      return r.aucune;
    }
    if (duree == null || duree <= Duration.zero) {
      return nombre == 1 ? r.resteUneSansDuree : r.restentSansDuree(n: nombre);
    }
    final String lisible = dureeVisiteLisible(duree);
    return nombre == 1
        ? r.resteUne(duree: lisible)
        : r.restent(n: nombre, duree: lisible);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? encart = _encart;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurEtatVide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(child: _Heros(avertissement: _interrompue)),
            Ecart.vLg,
            Semantics(
              header: true,
              child: Text(
                _titre,
                key: const ValueKey<String>('resultat-visite-titre'),
                textAlign: TextAlign.center,
                style: palette.inkStrong.applyTo(
                  textes.titleLarge ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            Text(
              _phrase,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodyLarge ?? const TextStyle(),
              ),
            ),
            if (encart != null) ...<Widget>[
              Ecart.vLg,
              _Encart(
                phrase: encart,
                enLecture: restantes is RestantesEnLecture,
              ),
            ],
            if (!sortieConfirmee) ...<Widget>[
              Ecart.vMd,
              Text(
                t.tc.observation.visite.sortieNonConfirmee,
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
            Ecart.vLg,
            ActionPrincipale(
              libelle: libelleRetour,
              onPress: onRetour,
              fleche: true,
            ),
            Ecart.vSm,
            ActionPrincipale(
              libelle: t.tc.observation.resultat.voirObservations,
              onPress: onObservations,
              niveau: NiveauAction.tertiaire,
            ),
          ],
        ),
      ),
    );
  }
}

/// Le cercle heros de M5 : l'oeil de l'observation et sa pastille (coche de
/// succes, ou avertissement quand la visite a ete interrompue).
class _Heros extends StatelessWidget {
  const _Heros({required this.avertissement});

  final bool avertissement;

  /// Diametre du cercle : 96 (maquette 92 a 97 dp, badge compris).
  static const double diametre = AppSpacing.titreEcran * 2;

  /// Diametre de la pastille : 32.
  static const double pastille = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair cercle = avertissement
        ? palette.washWarning
        : palette.washAccent;
    final AppColorPair badge = avertissement
        ? palette.surfaceWarning
        : palette.surfaceSuccess;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: diametre,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cercle.background,
                ),
                child: Center(
                  child: IconTheme(
                    data: avertissement
                        ? palette.inkWarning.asIconTheme(
                            size: AppSpacing.section,
                          )
                        : palette.inkAccent.asIconTheme(
                            size: AppSpacing.section,
                          ),
                    child: Icon(AppIcons.observationEnCours.actif),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 0,
              bottom: AppSpacing.xs,
              child: SizedBox.square(
                dimension: pastille,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.background,
                    border: Border.all(
                      color: palette.surfaceCanvas.background,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      avertissement
                          ? AppIcons.avertissement.actif
                          : AppIcons.succes.actif,
                      size: AppSpacing.lg,
                      color: badge.onBackground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'encart de M5 : medaillon d'horloge et phrase des visites restantes.
class _Encart extends StatelessWidget {
  const _Encart({required this.phrase, required this.enLecture});

  final String phrase;
  final bool enLecture;

  /// Diametre du medaillon : 40.
  static const double medaillon = AppSpacing.section;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        key: const ValueKey<String>('resultat-visite-encart'),
        decoration: palette.washAccent.decoration(
          borderRadius: AppRadius.arrondiSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: medaillon,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.surfaceRaised.background,
                    ),
                    child: Center(
                      child: enLecture
                          ? const SizedBox.square(
                              dimension: AppSpacing.lg,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconTheme(
                              data: palette.inkStrong.asIconTheme(
                                size: AppSpacing.xl,
                              ),
                              child: Icon(AppIcons.attente.repos),
                            ),
                    ),
                  ),
                ),
              ),
              Ecart.hLg,
              Expanded(
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
      ),
    );
  }
}

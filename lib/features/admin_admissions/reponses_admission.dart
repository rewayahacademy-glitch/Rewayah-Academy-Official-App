// ADMISSIONS-REPONSES (directeur, 22/11/2026 : « ouvrir une page pour lire le
// resultat d'onboarding pour l'admin, actuellement on ne peut rien voir,
// seulement un nom et une adresse mail »). Ce que la famille a repondu, lu en
// entier dans la feuille d'une demande : le titulaire, puis une carte par
// apprenant (age, genre, niveau, objectif, langue, et selon le niveau : lecture,
// memorise, juz, sourates ; la source et le lien de suivi chez le titulaire).
// ADMISSIONS-CHAMPS (22/11/2026) : le nouvel onboarding est lu en entier. Une
// reponse absente et pertinente se dit « Non renseigne » ; une ligne sans objet
// (la lecture d'un debutant) n'est pas montree.

import 'package:flutter/material.dart';

import '../../core/admission/port_admissions_direction.dart';
import '../../core/i18n/isolat_bidi.dart' show enTeteArabe, isolerSens;
import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../inscription/questionnaire/interludes_onboarding.dart'
    show libelleQuantite, nomLangue, nomSourate;
import '../inscription/questionnaire/onboarding_donnees.dart'
    show QuantiteMemorisee;
import '../parcours_offres/libelles_parcours.dart';

/// Le mot d'un genre (`male` ou `female`) : « Garcon », « Fille » pour un
/// enfant, « Homme », « Femme » pour le titulaire adulte. `null` si inconnu.
String? libelleGenreReponse(String? genre, {required bool adulte}) {
  final r = t.admissions.reponses;
  return switch (genre) {
    'male' => adulte ? r.homme : r.garcon,
    'female' => adulte ? r.femme : r.fille,
    _ => null,
  };
}

/// Le mot d'un moment de la journee (`matin`, `apres_midi`, `soir`).
String? libelleMomentReponse(String code) => switch (code) {
  'matin' => t.parcours.momentMatin,
  'apres_midi' => t.parcours.momentApresMidi,
  'soir' => t.parcours.momentSoir,
  _ => null,
};

/// Le mot de la source declaree (`mosquee`, `proche`, `reseaux`, `recherche`,
/// `autre`), `null` si absente ou inconnue : jamais le code.
String? libelleSourceReponse(String? code) {
  final s = t.onboarding.recap.sources;
  return switch (code) {
    'mosquee' => s.mosquee,
    'proche' => s.proche,
    'reseaux' => s.reseaux,
    'recherche' => s.recherche,
    'autre' => s.autre,
    _ => null,
  };
}

/// Le mot d'une langue demandee : un code du referentiel des classes (`fr`,
/// `ar`, `en`) ou une langue des enseignants (`ur`) ; « Autre langue » pour un
/// code que l'application ne connait pas, jamais le code lui-meme.
String? libelleLangueDemandee(String? code) {
  if (code == null || code.isEmpty) return null;
  final String nom = switch (code) {
    'fr' => nomLangue('francais'),
    'en' => nomLangue('english'),
    _ => nomLangue(code),
  };
  return enTeteArabe(nom == code ? t.admissions.reponses.langueHorsListe : nom);
}

/// Le mot de la lecture du Coran (`hafs`, `warsh`, `autre`), la lecture
/// ecrite par la famille pour `autre`. `null` si absente.
String? libelleLectureReponse(String? riwaya, String? autre) {
  final l = t.onboarding.lecture;
  return switch (riwaya) {
    'hafs' => l.hafs,
    'warsh' => l.warsh,
    'autre' =>
      autre == null || autre.isEmpty
          ? l.autre
          : t.admissions.reponses.autreLecture(nom: isolerSens(autre)),
    _ => null,
  };
}

/// Les reponses d'une demande : le titulaire, puis chaque apprenant.
class ReponsesAdmission extends StatelessWidget {
  /// Cree le bloc.
  const ReponsesAdmission({
    required this.demande,
    required this.date,
    this.ligneEtat,
    super.key,
  });

  /// La demande lue.
  final DemandeAdmission demande;

  /// La date de reception, deja mise en mots par l'ecran.
  final String date;

  /// La ligne d'etat, posee en tete de la carte du titulaire.
  final Widget? ligneEtat;

  /// La cle de la carte du titulaire, pour les tests.
  static const ValueKey<String> cleTitulaire = ValueKey<String>(
    'reponses-titulaire',
  );

  /// La cle de la carte du i-eme apprenant, pour les tests.
  static ValueKey<String> cleApprenant(int i) =>
      ValueKey<String>('reponses-apprenant-$i');

  static Widget _ligne(String cle, String? valeur) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: LigneCleValeur(
      cle: cle,
      valeur: valeur == null || valeur.isEmpty
          ? t.admissions.reponses.nonRenseigne
          : valeur,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = t.admissions.reponses;
    final a = t.admissions;
    final TextTheme textes = Theme.of(context).textTheme;
    final DemandeAdmission d = demande;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(r.titulaireTitre, style: textes.titleMedium),
        Ecart.vSm,
        KeyedSubtree(
          key: cleTitulaire,
          child: CarteLignes(
            lignes: <Widget>[
              _ligne(r.nom, d.nom),
              _ligne(a.courriel, d.courriel),
              if (ligneEtat case final Widget e)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: e,
                ),
              _ligne(a.recueLe, date),
              _ligne(a.reference, d.reference),
              _ligne(r.source, libelleSourceReponse(d.source)),
              if (d.suivi case final String lien when lien.isNotEmpty)
                _ligne(r.suivi, isolerSens(lien)),
            ],
          ),
        ),
        Ecart.vLg,
        Text(
          r.apprenantsTitre(n: d.apprenants.length),
          style: textes.titleMedium,
        ),
        Ecart.vSm,
        if (d.apprenants.isEmpty)
          Text(r.aucunApprenant, style: textes.bodyMedium)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.lg,
            children: <Widget>[
              for (int i = 0; i < d.apprenants.length; i++)
                KeyedSubtree(
                  key: cleApprenant(i),
                  child: _CarteApprenant(apprenant: d.apprenants[i]),
                ),
            ],
          ),
      ],
    );
  }
}

class _CarteApprenant extends StatelessWidget {
  const _CarteApprenant({required this.apprenant});

  final ApprenantAdmission apprenant;

  @override
  Widget build(BuildContext context) {
    final r = t.admissions.reponses;
    final ApprenantAdmission ap = apprenant;
    final bool adulte = ap.titulaire && ap.age == null;
    final NiveauDeclare? niveau = NiveauDeclare.depuisSql(ap.niveau);
    final bool priere = ap.objectif == 'priere_invocations';
    final ObjectifApprentissage? objectif = ObjectifApprentissage.depuisSql(
      ap.objectif,
    );
    final List<String> moments = <String>[
      for (final String m in ap.moments)
        if (libelleMomentReponse(m) case final String l) l,
    ];
    // Ce qui n'est demande qu'a certains niveaux ne s'affiche que pour eux.
    final bool lit =
        ap.niveau == 'lecture_courante' ||
        ap.niveau == 'memorisation_partielle';
    final bool memorise = ap.niveau == 'memorisation_partielle';
    final QuantiteMemorisee? quantite = QuantiteMemorisee.depuisSql(
      ap.memorise,
    );
    final bool detailJuz =
        quantite == QuantiteMemorisee.unACinqJuz ||
        quantite == QuantiteMemorisee.plusDeCinqJuz;
    final bool detailSourates = quantite == QuantiteMemorisee.quelquesSourates;
    final int? age = ap.age;
    return CarteLignes(
      lignes: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AvatarNom.enLigne(
            prenom: ap.prenom,
            role: ap.titulaire ? r.titulaireRole : r.enfantRole,
          ),
        ),
        ReponsesAdmission._ligne(
          r.age,
          age != null
              ? LibellesGroupe.insecable(r.ageValeur(age: age))
              : (adulte ? r.adulte : null),
        ),
        ReponsesAdmission._ligne(
          r.genre,
          libelleGenreReponse(ap.genre, adulte: adulte),
        ),
        ReponsesAdmission._ligne(
          r.niveau,
          niveau == null ? null : libelleNiveau(niveau),
        ),
        if (lit)
          ReponsesAdmission._ligne(
            r.lecture,
            libelleLectureReponse(ap.riwaya, ap.riwayaAutre),
          ),
        if (memorise)
          ReponsesAdmission._ligne(
            r.memorise,
            quantite == null ? null : libelleQuantite(quantite),
          ),
        if (memorise && (detailJuz || ap.juz.isNotEmpty))
          ReponsesAdmission._ligne(
            r.juz,
            ap.juz.isEmpty
                ? null
                : (<int>[...ap.juz]..sort())
                      .map((int n) => t.onboarding.detail.juz(n: n))
                      .join(', '),
          ),
        if (memorise && (detailSourates || ap.sourates.isNotEmpty))
          ReponsesAdmission._ligne(
            r.sourates,
            ap.sourates.isEmpty ? null : ap.sourates.map(nomSourate).join(', '),
          ),
        ReponsesAdmission._ligne(
          r.objectif,
          priere
              ? t.onboarding.recap.objectifs.priere
              : (objectif == null ? null : libelleObjectif(objectif)),
        ),
        if (moments.isNotEmpty)
          ReponsesAdmission._ligne(r.moments, moments.join(', ')),
        ReponsesAdmission._ligne(r.langue, libelleLangueDemandee(ap.langue)),
        if (ap.langueSecours case final String ls when ls.isNotEmpty)
          ReponsesAdmission._ligne(r.langueSecours, libelleLangueDemandee(ls)),
        if (ap.langueAutre case final String la when la.isNotEmpty)
          ReponsesAdmission._ligne(r.langueAutre, isolerSens(la)),
        ReponsesAdmission._ligne(
          r.titulaireLigne,
          ap.titulaire ? r.oui : r.non,
        ),
      ],
    );
  }
}

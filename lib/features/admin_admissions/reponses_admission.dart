// ADMISSIONS-REPONSES (directeur, 22/11/2026 : « ouvrir une page pour lire le
// resultat d'onboarding pour l'admin, actuellement on ne peut rien voir,
// seulement un nom et une adresse mail »). Ce que la famille a repondu, lu en
// entier dans la feuille d'une demande : le titulaire, puis une carte par
// apprenant (age, genre, niveau, objectif, moments, langue). Aucune donnee
// nouvelle : ce que `lister_demandes_admission` rend deja. Une reponse absente
// se dit « Non renseigne », jamais une ligne qui disparait.

import 'package:flutter/material.dart';

import '../../core/admission/port_admissions_direction.dart';
import '../../core/i18n/isolat_bidi.dart' show enTeteArabe;
import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../admin_pedagogie_bibliotheque/libelles_bibliotheque.dart'
    show libelleLangue;
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
    final ObjectifApprentissage? objectif = ObjectifApprentissage.depuisSql(
      ap.objectif,
    );
    final List<String> moments = <String>[
      for (final String m in ap.moments)
        if (libelleMomentReponse(m) case final String l) l,
    ];
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
        ReponsesAdmission._ligne(
          r.objectif,
          objectif == null ? null : libelleObjectif(objectif),
        ),
        ReponsesAdmission._ligne(
          r.moments,
          moments.isEmpty ? null : moments.join(', '),
        ),
        ReponsesAdmission._ligne(
          r.langue,
          ap.langue == null ? null : enTeteArabe(libelleLangue(ap.langue!)),
        ),
        ReponsesAdmission._ligne(r.titulaireLigne, ap.titulaire ? r.oui : r.non),
      ],
    );
  }
}

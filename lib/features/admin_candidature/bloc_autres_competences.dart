// La ligne « Autres competences » de la fiche d'une candidature (`ADM-21`,
// `CAND-07`) : ce que la personne a repondu a « Vos autres talents », pour que la
// direction pose une question de vive voix a l'entretien si un besoin existe.
//
// **Lecture seule, dans la portee du dossier** : le serveur rend la cle
// `autresCompetences` de `lire_candidature()` seulement dans la portee de genre de
// la candidature (jamais une autre). Aucune note, aucun classement, aucune
// decision : ces reponses ne servent ni a passer une etape ni a calculer un
// paiement. **Pas d'accord, pas de mission** : l'accord d'etre contacte se lit
// ici, et quand il manque la ligne dit de ne proposer aucune mission.
//
// Les competences se disent par le texte de l'application ; une competence que la
// direction a ajoutee depuis prend son libelle du catalogue, lu par la direction
// (`lire_catalogue_competences()`) ; sans catalogue lu, elle se dit par une phrase
// neutre, jamais par son code.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/section_header.dart';
import '../talents/lecture_talents.dart' show jourTalents;
import '../talents/libelles_talents.dart';

/// Le bloc « Autres competences ».
class BlocAutresCompetences extends ConsumerWidget {
  /// Cree le bloc.
  const BlocAutresCompetences({required this.detail, super.key});

  /// Le dossier lu.
  final DetailCandidature detail;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-autres-competences');

  /// La cle de la phrase « aucune reponse ».
  static const Key aucuneKey = ValueKey<String>('candidature-talents-aucune');

  /// La cle de la ligne de disponibilite.
  static const Key disponibiliteKey = ValueKey<String>(
    'candidature-talents-disponibilite',
  );

  /// La cle de la ligne de l'accord.
  static const Key accordKey = ValueKey<String>('candidature-talents-accord');

  /// La cle de la ligne d'une competence.
  static Key ligneKey(String code) =>
      ValueKey<String>('candidature-talents-$code');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.candidatures.detail.talents;
    final ReponsesAutresCompetences? reponses = detail.autresCompetences;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    // Le catalogue ne sert qu'a nommer les competences que l'application ne
    // connait pas : sa lecture ne bloque ni ne remplace rien.
    final CatalogueCompetences? catalogue = reponses == null
        ? null
        : ref.watch(catalogueCompetencesProvider).value;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(header: true, child: SectionHeader(titre: r.titre)),
        Ecart.vMd,
        if (reponses == null)
          AppCard(
            child: TexteSansCoupure(
              r.aucune,
              key: aucuneKey,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          )
        else
          CarteGroupee(
            sections: <Widget>[
              _lignesCompetences(reponses, catalogue),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LigneCleValeur(
                    key: disponibiliteKey,
                    cle: r.disponibilite,
                    valeur: libelleDisponibilite(reponses.disponibilite),
                  ),
                  LigneCleValeur(
                    key: accordKey,
                    cle: r.accord,
                    valeur: !reponses.accord
                        ? r.accordAbsent
                        : reponses.accordLe == null
                        ? t.admin.candidatures.filtres.talents.accordDonne
                        : r.accordDonne(date: jourTalents(reponses.accordLe!)),
                  ),
                  if (reponses.majLe != null) ...<Widget>[
                    Ecart.vSm,
                    TexteSansCoupure(
                      r.misesAJour(date: jourTalents(reponses.majLe!)),
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
      ],
    );
  }

  /// Une ligne par competence, dans l'ordre du catalogue quand il est lu, sinon
  /// dans l'ordre des codes : le niveau en valeur.
  Widget _lignesCompetences(
    ReponsesAutresCompetences reponses,
    CatalogueCompetences? catalogue,
  ) {
    final List<String> codes = reponses.domaines.keys.toList();
    if (catalogue != null) {
      int rang(String code) {
        final int i = catalogue.competences.indexWhere(
          (EntreeCatalogue e) => e.code == code,
        );
        return i < 0 ? catalogue.competences.length : i;
      }

      codes.sort((String a, String b) {
        final int c = rang(a).compareTo(rang(b));
        return c != 0 ? c : a.compareTo(b);
      });
    } else {
      codes.sort();
    }
    final r = t.admin.candidatures.detail.talents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String code in codes)
          LigneCleValeur(
            key: ligneKey(code),
            cle:
                code == EntreeCatalogue.codeAutre && reponses.autreTexte != null
                ? r.autre(texte: reponses.autreTexte!)
                : libelleCompetence(code, entree: catalogue?.entree(code)) ??
                      r.competenceInconnue,
            valeur: libelleNiveauDirection(reponses.domaines[code]!),
          ),
      ],
    );
  }
}

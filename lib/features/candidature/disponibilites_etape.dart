// Les disponibilites du candidat (CAND-01), heure par heure, dans l'heure de
// chez lui : cinq ecrans au plus, une decision chacun.
//
//   1. les jours (cartes, avec des raccourcis) ;
//   2. les heures de debut possibles du premier jour (puces groupees par moment
//      de la journee), avec ce que cela veut dire : « vous enseignez de 18 h a
//      19 h 30 » ;
//   3. « memes heures pour tous ces jours ? » (deux jours au moins) ;
//   4. les heures de chaque jour, si ce n'est pas pareil ;
//   5. le recapitulatif de la semaine.
//
// Une Classe se tient trois fois par semaine, aux memes jours, a une heure de
// debut entiere, pendant 60 minutes (enfants) ou 90 minutes (adultes) :
// l'academie veut donc des heures de debut. Ce que le serveur recoit (plages
// d'heures entieres) se calcule dans `DisponibilitesDeclarees`, pas ici.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/disponibilites_declarees.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/setting_row.dart';
import 'controleur_parcours.dart';
import 'libelles_parcours.dart';

/// Les raccourcis de jours : lundi, mercredi, vendredi ; mardi, jeudi, samedi ;
/// la fin de semaine (samedi et dimanche).
const List<({String code, Set<int> jours})> raccourcisJours =
    <({String code, Set<int> jours})>[
      (code: 'lmv', jours: <int>{1, 3, 5}),
      (code: 'mjs', jours: <int>{2, 4, 6}),
      (code: 'finDeSemaine', jours: <int>{6, 7}),
    ];

/// Le titre et l'explication d'un ecran des disponibilites.
({String titre, String? explication}) textesDisponibilites(
  EtapeDisponibilites etape,
  ParcoursControleur c,
) {
  final q = t.recrutement.parcours.q.disponibilitesDeclarees;
  final r = t.recrutement.parcours.creneaux;
  switch (etape.sous) {
    case SousEtapeDisponibilites.jours:
      return (titre: q.titre, explication: q.explication);
    case SousEtapeDisponibilites.heures:
      final int? jour = c.premierJour;
      final String duree = r.durees(
        enfants: libelleDuree(dureeSeanceEnfantMinutes),
        adultes: libelleDuree(dureeSeanceAdulteMinutes),
      );
      return (
        titre: q.heures.titre(jour: jour == null ? '' : _nomMinuscule(jour)),
        explication: <String>[
          q.heures.explication,
          duree,
          if (c.jours.length >= 2) q.heures.suite,
        ].join(' '),
      );
    case SousEtapeDisponibilites.memes:
      return (titre: q.memes.titre, explication: _expliquerMemes(c));
    case SousEtapeDisponibilites.parJour:
      return (titre: q.parJour.titre, explication: q.parJour.explication);
    case SousEtapeDisponibilites.semaine:
      return (titre: q.semaine.titre, explication: q.semaine.explication);
  }
}

String _nomMinuscule(int jour) => t.disponibilites.joursLongs[jour - 1];

/// « mercredi et vendredi », « mardi, jeudi et samedi ».
String listeDeJours(Iterable<int> jours) {
  final List<String> noms = <String>[
    for (final int j in jours) _nomMinuscule(j),
  ];
  if (noms.length <= 1) {
    return noms.join();
  }
  final r = t.recrutement.parcours.creneaux;
  return r.etListe(
    debut: noms.sublist(0, noms.length - 1).join(r.separateurListe),
    dernier: noms.last,
  );
}

String _expliquerMemes(ParcoursControleur c) {
  final int? premier = c.premierJour;
  if (premier == null) {
    return '';
  }
  final q = t.recrutement.parcours.q.disponibilitesDeclarees.memes;
  return q.explication(
    jours: listeDeJours(c.jours),
    premier: _nomMinuscule(premier),
    heures: libelleHeures(c.debutsDuJour(premier)),
  );
}

/// Le corps d'un ecran des disponibilites.
class DisponibilitesEtape extends StatelessWidget {
  /// Cree le corps de l'ecran [etape].
  const DisponibilitesEtape({
    required this.etape,
    required this.controleur,
    super.key,
  });

  /// L'ecran.
  final EtapeDisponibilites etape;

  /// Le parcours.
  final ParcoursControleur controleur;

  /// La cle de la zone « vous enseignez ... ».
  static const Key resumeKey = ValueKey<String>('dispo-resume');

  /// La cle d'une puce d'heure d'un jour.
  static Key puceKey(int jour, int heure) =>
      ValueKey<String>('heure-$jour-$heure');

  /// La cle de la carte d'un jour (jour par jour et recapitulatif).
  static Key jourKey(int jour) => ValueKey<String>('dispo-jour-$jour');

  /// La cle d'un raccourci de jours.
  static Key raccourciKey(String code) =>
      ValueKey<String>('dispo-raccourci-$code');

  /// La cle d'une carte de jour.
  static Key carteJourKey(int jour) => ValueKey<String>('option-jour-$jour');

  /// La cle de la note « moins de trois jours ».
  static const Key moinsDeTroisKey = ValueKey<String>('dispo-moins-de-trois');

  @override
  Widget build(BuildContext context) => switch (etape.sous) {
    SousEtapeDisponibilites.jours => _Jours(controleur: controleur),
    SousEtapeDisponibilites.heures => _Heures(controleur: controleur),
    SousEtapeDisponibilites.memes => _Memes(controleur: controleur),
    SousEtapeDisponibilites.parJour => _ParJour(controleur: controleur),
    SousEtapeDisponibilites.semaine => _Semaine(controleur: controleur),
  };
}

// ---------------------------------------------------------------------------
// 1. Les jours
// ---------------------------------------------------------------------------

class _Jours extends StatefulWidget {
  const _Jours({required this.controleur});

  final ParcoursControleur controleur;

  @override
  State<_Jours> createState() => _JoursEtat();
}

class _JoursEtat extends State<_Jours> {
  /// Change quand un raccourci remplace la selection : le groupe de cartes se
  /// reconstruit avec les jours choisis.
  int _revision = 0;

  ParcoursControleur get _c => widget.controleur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.recrutement.parcours.creneaux;
    final Set<int> choisis = _c.jours.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TexteSansCoupure(r.raccourcis, style: textes.labelLarge),
        Ecart.vSm,
        // Choix de formulaire, pas un filtre : les jours d'un raccourci.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final ({String code, Set<int> jours}) k in raccourcisJours)
              FilterPill(
                key: DisponibilitesEtape.raccourciKey(k.code),
                libelle: switch (k.code) {
                  'lmv' => r.raccourciLmv,
                  'mjs' => r.raccourciMjs,
                  _ => r.raccourciFinDeSemaine,
                },
                retenue:
                    choisis.length == k.jours.length &&
                    choisis.containsAll(k.jours),
                onPress: () {
                  _c.choisirJours(k.jours);
                  setState(() => _revision++);
                },
              ),
          ],
        ),
        Ecart.vSm,
        TexteSansCoupure(
          r.raccourcisAide,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        ChoiceCardGroup(
          key: ValueKey<String>('dispo-jours-$_revision'),
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          valeurInitiale: choisis.isEmpty
              ? null
              : ReponseChoix(
                  valeurs: <String>{for (final int j in choisis) '$j'},
                ),
          options: <OptionChoix>[
            for (int j = 1; j <= joursParSemaine; j++)
              OptionChoix(
                cle: DisponibilitesEtape.carteJourKey(j),
                valeur: '$j',
                libelle: nomDeJour(j),
                icone: AppIcons.disponibilites,
              ),
          ],
          onChange: (ReponseChoix reponse) => _c.choisirJours(<int>{
            for (final String v in reponse.valeurs) int.parse(v),
          }),
        ),
        if (choisis.isNotEmpty && choisis.length < seancesParClasse)
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(
              r.moinsDeTrois(n: choisis.length),
              key: DisponibilitesEtape.moinsDeTroisKey,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Les heures de debut
// ---------------------------------------------------------------------------

/// Les puces des heures de debut d'un jour, groupees par moment de la
/// journee : la nuit, le matin, l'apres-midi, le soir.
class PucesHeures extends StatelessWidget {
  /// Cree les puces du jour [jour].
  const PucesHeures({
    required this.jour,
    required this.choisies,
    required this.onBascule,
    super.key,
  });

  /// Le jour (1 a 7), pour les cles.
  final int jour;

  /// Les heures de debut retenues.
  final Set<int> choisies;

  /// Appele quand une puce est touchee.
  final ValueChanged<int> onBascule;

  Widget _moment(BuildContext context, ({String code, int de, int a}) m) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            titreMoment(m.code),
            style: textes.labelLarge,
          ),
        ),
        Ecart.vSm,
        // Choix de formulaire, pas un filtre : les heures de debut d'un jour.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (int h = m.de; h <= m.a; h++)
              FilterPill(
                key: DisponibilitesEtape.puceKey(jour, h),
                libelle: libelleHeure(h),
                retenue: choisies.contains(h),
                onPress: () => onBascule(h),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) {
      final List<Widget> moments = <Widget>[
        for (final ({String code, int de, int a}) m in momentsDeLaJournee)
          _moment(context, m),
      ];
      if (c.maxWidth < 560) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (int i, Widget m) in moments.indexed) ...<Widget>[
              if (i > 0) Ecart.vXl,
              m,
            ],
          ],
        );
      }
      // Tablette et bureau : deux colonnes, la nuit et le matin au debut, le
      // soir a la fin.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[moments[0], Ecart.vXl, moments[1]],
            ),
          ),
          Ecart.hXl,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[moments[2], Ecart.vXl, moments[3]],
            ),
          ),
        ],
      );
    },
  );
}

/// « Un cours d'enfants dure 1 h : vous enseignez de 18 h a 19 h. » et la meme
/// phrase pour les adultes, selon les publics que la personne enseigne.
class ResumeCours extends StatelessWidget {
  /// Cree le resume des heures de debut [debuts] d'un jour.
  const ResumeCours({
    required this.debuts,
    required this.controleur,
    super.key,
  });

  /// Les heures de debut retenues.
  final List<int> debuts;

  /// Le parcours (les publics enseignes).
  final ParcoursControleur controleur;

  /// Les lignes du resume, une par duree de cours : enfants, adultes.
  static List<String> lignes(List<int> debuts, ParcoursControleur c) {
    final r = t.recrutement.parcours.creneaux;
    return <String>[
      if (c.avecEnfants || !c.avecAdultes)
        r.enseigneEnfants(
          duree: libelleDuree(dureeSeanceEnfantMinutes),
          intervalles: libelleIntervalles(
            intervallesDesCours(debuts, dureeSeanceEnfantMinutes),
          ),
        ),
      if (c.avecAdultes)
        r.enseigneAdultes(
          duree: libelleDuree(dureeSeanceAdulteMinutes),
          intervalles: libelleIntervalles(
            intervallesDesCours(debuts, dureeSeanceAdulteMinutes),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.recrutement.parcours.creneaux;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        key: DisponibilitesEtape.resumeKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(r.heuresChoisies(n: debuts.length), style: textes.titleSmall),
            if (debuts.isNotEmpty) ...<Widget>[
              for (final String ligne in lignes(
                debuts,
                controleur,
              )) ...<Widget>[
                Ecart.vSm,
                TexteSansCoupure(ligne, style: textes.bodyMedium),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Heures extends StatelessWidget {
  const _Heures({required this.controleur});

  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final int? jour = controleur.premierJour;
    if (jour == null) {
      return const SizedBox.shrink();
    }
    final List<int> debuts = controleur.debutsDuJour(jour);
    final String? zone = controleur.fuseau;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (zone != null) ...<Widget>[
          TexteSansCoupure(
            t.recrutement.parcours.creneaux.fuseauRappel(lieu: nomDeLieu(zone)),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        PucesHeures(
          jour: jour,
          choisies: debuts.toSet(),
          onBascule: (int h) => controleur.basculerHeure(jour, h),
        ),
        Ecart.vXl,
        ResumeCours(debuts: debuts, controleur: controleur),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Memes heures ?
// ---------------------------------------------------------------------------

class _Memes extends StatelessWidget {
  const _Memes({required this.controleur});

  final ParcoursControleur controleur;

  /// La cle de la carte « Oui ».
  static const Key ouiKey = ValueKey<String>('option-memes-oui');

  /// La cle de la carte « Non ».
  static const Key nonKey = ValueKey<String>('option-memes-non');

  @override
  Widget build(BuildContext context) {
    final q = t.recrutement.parcours.q.disponibilitesDeclarees.memes;
    final int premier = controleur.premierJour ?? 1;
    final List<int> autres = <int>[
      for (final int j in controleur.jours)
        if (j != premier) j,
    ];
    final bool? memes = controleur.memesHeures;
    return ChoiceCardGroup(
      key: const ValueKey<String>('dispo-memes'),
      autoriserSaisieLibre: false,
      coteACote: true,
      valeurInitiale: memes == null
          ? null
          : ReponseChoix(valeurs: <String>{memes ? 'oui' : 'non'}),
      options: <OptionChoix>[
        OptionChoix(
          cle: ouiKey,
          valeur: 'oui',
          libelle: q.oui.libelle,
          description: q.oui.description(
            autres: listeDeJours(autres),
            premier: _nomMinuscule(premier),
          ),
          explication: q.oui.explication,
          exemple: q.oui.exemple,
          icone: AppIcons.succes,
        ),
        OptionChoix(
          cle: nonKey,
          valeur: 'non',
          libelle: q.non.libelle,
          description: q.non.description,
          explication: q.non.explication,
          exemple: q.non.exemple,
          icone: AppIcons.disponibilites,
        ),
      ],
      onChange: (ReponseChoix reponse) {
        if (reponse.valeurs.contains('oui')) {
          controleur.repondreMemes(oui: true);
        } else if (reponse.valeurs.contains('non')) {
          controleur.repondreMemes(oui: false);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Jour par jour
// ---------------------------------------------------------------------------

class _ParJour extends StatelessWidget {
  const _ParJour({required this.controleur});

  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? zone = controleur.fuseau;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (zone != null) ...<Widget>[
          TexteSansCoupure(
            t.recrutement.parcours.creneaux.fuseauRappel(lieu: nomDeLieu(zone)),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        PileCartes(
          children: <Widget>[
            for (final int jour in controleur.jours)
              Semantics(
                container: true,
                label: nomDeJour(jour),
                child: AppCard(
                  key: DisponibilitesEtape.jourKey(jour),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(nomDeJour(jour), style: textes.titleMedium),
                      ),
                      Ecart.vLg,
                      PucesHeures(
                        jour: jour,
                        choisies: controleur.debutsDuJour(jour).toSet(),
                        onBascule: (int h) => controleur.basculerHeure(jour, h),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. La semaine
// ---------------------------------------------------------------------------

class _Semaine extends StatelessWidget {
  const _Semaine({required this.controleur});

  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.recrutement.parcours.creneaux;
    final String? zone = controleur.fuseau;
    final List<int> jours = controleur.disponibilites.jours;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (zone != null) ...<Widget>[
          TexteSansCoupure(
            r.fuseauRappel(lieu: nomDeLieu(zone)),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        CarteLignes(
          lignes: <Widget>[
            for (final int jour in jours)
              SettingRow(
                key: DisponibilitesEtape.jourKey(jour),
                title: nomDeJour(jour),
                description: <String>[
                  r.debutsDuJour(
                    heures: libelleHeures(controleur.debutsDuJour(jour)),
                  ),
                  ...ResumeCours.lignes(
                    controleur.debutsDuJour(jour),
                    controleur,
                  ),
                ].join('\n'),
                icon: AppIcons.disponibilites,
              ),
          ],
        ),
        Ecart.vLg,
        TexteSansCoupure(
          jours.length < seancesParClasse
              ? r.moinsDeTrois(n: jours.length)
              : r.troisSeances,
          key: DisponibilitesEtape.moinsDeTroisKey,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

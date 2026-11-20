// Le corps d'une question du parcours (CAND-01) : tout se choisit en touchant
// des cartes. Chaque choix est decrit pour des personnes peu a l'aise avec la
// technologie : ce que c'est (description), ce que le choix entraine
// (explication), un cas concret (exemple). Les textes viennent de
// `assets/i18n`, par le code que le serveur rend ; un code sans texte ne
// s'affiche pas.
//
// Les listes longues (langues, pays, riwayat) ont la recherche en tete, puis
// leurs choix courants en lignes compactes (`ChoixAvecRecherche`). Les disponibilites ont leurs propres
// ecrans (`disponibilites_etape.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/disponibilites_declarees.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_etiquete.dart' show TitreChamp;
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/choix_nombre.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import 'choix_avec_recherche.dart';
import 'controleur_parcours.dart';
import 'libelles_parcours.dart';
import 'modele_questions.dart';
import 'ville_etape.dart';

/// Les pays proposes d'emblee : ceux des vraies candidatures, dans l'ordre de
/// leur nombre (relevé du 16/11/2026 : Arabie saoudite, Nigeria, Yémen, Égypte,
/// Algérie, Bénin, Ghana, Tchad), puis les pays que les enseignants de
/// l'academie habitent deja (FORM-L8) en Afrique de l'Ouest, au Maroc et en
/// Europe.
const List<String> paysCourants = <String>[
  'SA',
  'NG',
  'YE',
  'EG',
  'DZ',
  'BJ',
  'GH',
  'TD',
  'SN',
  'ML',
  'GN',
  'MA',
  'FR',
  'BE',
  'GB',
];

/// Ce que la recherche lit d'un pays en plus de son nom affiche : ses noms
/// francais, arabe et anglais, et son code. Un candidat dont l'application est en
/// arabe retrouve « Ghana » en lettres latines, et l'inverse (PAYS-RECHERCHE,
/// 16/11/2026). Jamais affiche.
String motsClesDuPays(PaysIso p) =>
    '${p.fr} ${p.ar} ${p.en} ${p.code} '
    // PE-B8 : les autres noms courants (« Angleterre », « USA »), comme la
    // recherche de l'indicatif.
    '${motsAlternatifsDuPays(p.code).join(' ')}';

/// Les riwayat proposees d'emblee, les plus connues d'abord (CANDIDATURE-UX,
/// directeur, 14/11/2026 : Hafs, Warsh, Qaloun, Shu'ba, Duri, Susi) ; les
/// autres se trouvent par « Une autre riwaya ».
const List<String> riwayatCourantes = <String>[
  'hafs',
  'warsh',
  'qalun',
  'shuba',
  'ad_duri_abi_amr',
  'as_susi',
];

/// Le corps de la question [etape].
class QuestionEtape extends ConsumerWidget {
  /// Cree le corps.
  const QuestionEtape({
    required this.etape,
    required this.controleur,
    super.key,
  });

  /// La question posee.
  final EtapeChamp etape;

  /// Le parcours.
  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChampQuestionnaire champ = etape.champ;
    switch (etape.forme) {
      case FormeQuestion.choix:
        // PE-B1 : la memorisation se dit en nombre exact de juz, des que le
        // serveur propose juz_1 a juz_29 (migration 20261130920000) ; sans
        // elle, les anciennes cartes, que le serveur accepte.
        if (champ.code == champMemorisation &&
            champ.options.any(
              (OptionQuestionnaire o) => o.code == codeJuz(1),
            )) {
          return _Juz(champ: champ, controleur: controleur);
        }
        final Widget cartes = _Cartes(
          champ: champ,
          controleur: controleur,
          multiple: false,
        );
        // PE-B8 (retours terrain R38 : « qu'entendez-vous par ijaza ? ») :
        // une aide courte, a cote de la question, qui se deplie.
        if (champ.code == 'ijazaPresentable') {
          final aides = t.recrutement.parcours.aides;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AideQuestion(
                cle: 'aide-ijaza',
                titre: aides.ijazaTitre,
                texte: aides.ijazaTexte,
              ),
              Ecart.vLg,
              cartes,
            ],
          );
        }
        return cartes;
      case FormeQuestion.choixMultiple:
        return _Cartes(champ: champ, controleur: controleur, multiple: true);
      case FormeQuestion.ouiNon:
        return _OuiNon(champ: champ, controleur: controleur);
      case FormeQuestion.langue || FormeQuestion.langues:
        return _Langues(
          champ: champ,
          controleur: controleur,
          multiple: etape.forme == FormeQuestion.langues,
        );
      case FormeQuestion.pays:
        return _Pays(champ: champ, controleur: controleur);
      case FormeQuestion.riwayat:
        return _Riwayat(champ: champ, controleur: controleur);
      case FormeQuestion.creneaux:
        // Les disponibilites ont leurs ecrans (`EtapeDisponibilites`) : le plan
        // du parcours ne pose jamais ce champ comme une simple question.
        return const SizedBox.shrink();
      case FormeQuestion.fuseau:
        return VilleEtape(
          options: <String>[for (final o in champ.options) o.code],
          choisi: controleur.fuseau,
          onChange: (String zone) => controleur.repondre(champ.code, zone),
        );
      case FormeQuestion.classes:
        return _Classes(champ: champ, controleur: controleur);
      case FormeQuestion.moyensAccessibles:
        return _MoyensAccessibles(champ: champ, controleur: controleur);
      case FormeQuestion.operateurs:
        return _Operateurs(champ: champ, controleur: controleur);
    }
  }
}

/// Les options d'un champ a peu de choix, avec leurs textes et leurs icones.
List<OptionChoix> optionsDuChamp(ChampQuestionnaire champ) {
  final ModeleQuestion? modele = modelesQuestions[champ.code];
  return <OptionChoix>[
    for (final OptionQuestionnaire o in champ.options)
      if (textesOption(champ.code, o.code) case final TextesOption x)
        OptionChoix(
          cle: ValueKey<String>('option-${champ.code}-${o.code}'),
          valeur: o.code,
          libelle: x.libelle,
          description: x.description,
          explication: x.explication,
          exemple: x.exemple,
          icone: modele?.icones[o.code],
          illustration: modele?.icones[o.code] == null
              ? null
              : IllustrationChoix(
                  modele!.icones[o.code]!,
                  autour: modele.autour,
                ),
        ),
  ];
}

class _Cartes extends StatelessWidget {
  const _Cartes({
    required this.champ,
    required this.controleur,
    required this.multiple,
  });

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final Set<String> valeurs = controleur.valeurs(champ.code);
    return ChoiceCardGroup(
      key: ValueKey<String>('q-${champ.code}'),
      autoriserSaisieLibre: false,
      selectionMultiple: multiple,
      valeurInitiale: valeurs.isEmpty ? null : ReponseChoix(valeurs: valeurs),
      options: optionsDuChamp(champ),
      onChange: (ReponseChoix r) {
        if (multiple) {
          // L'ordre du serveur, pas l'ordre des touches.
          controleur.repondre(champ.code, <String>[
            for (final OptionQuestionnaire o in champ.options)
              if (r.valeurs.contains(o.code)) o.code,
          ]);
        } else if (r.valeurs.isNotEmpty) {
          controleur.repondre(champ.code, r.valeurs.first);
        }
      },
    );
  }
}

class _OuiNon extends StatelessWidget {
  const _OuiNon({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final ModeleQuestion? modele = modelesQuestions[champ.code];
    final Object? reponse = controleur.reponse(champ.code);
    OptionChoix option(String code) {
      final TextesOption x = textesOption(champ.code, code)!;
      final AppIcon? icone = modele?.icones[code];
      return OptionChoix(
        cle: ValueKey<String>('option-${champ.code}-$code'),
        valeur: code,
        libelle: x.libelle,
        description: x.description,
        explication: x.explication,
        exemple: x.exemple,
        icone: icone,
        illustration: icone == null ? null : IllustrationChoix(icone),
      );
    }

    return ChoiceCardGroup(
      key: ValueKey<String>('q-${champ.code}'),
      autoriserSaisieLibre: false,
      coteACote: true,
      valeurInitiale: reponse is bool
          ? ReponseChoix(valeurs: <String>{reponse ? 'oui' : 'non'})
          : null,
      options: <OptionChoix>[option('oui'), option('non')],
      onChange: (ReponseChoix r) {
        if (r.valeurs.contains('oui')) {
          controleur.repondre(champ.code, true);
        } else if (r.valeurs.contains('non')) {
          controleur.repondre(champ.code, false);
        }
      },
    );
  }
}

class _Langues extends StatelessWidget {
  const _Langues({
    required this.champ,
    required this.controleur,
    required this.multiple,
  });

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.langues;
    final List<ElementChoix> tous = <ElementChoix>[
      for (final OptionQuestionnaire o in champ.options)
        if (!languesRetirees.contains(o.code))
          if (nomDeLangue(o.code) case final String nom)
            ElementChoix(
              code: o.code,
              libelle: nom,
              // Dire quelles langues Rewayah enseigne n'a de sens que pour les
              // langues d'explication ; la langue maternelle peut etre toute
              // autre langue, sans commentaire.
              description: o.code == 'autre'
                  ? r.autreDescription
                  : !multiple
                  ? null
                  : o.horsReferentiel
                  ? r.horsReferentiel
                  : r.dansReferentiel,
              cle: ValueKey<String>('option-${champ.code}-${o.code}'),
            ),
    ];
    final Map<String, ElementChoix> parCode = <String, ElementChoix>{
      for (final ElementChoix e in tous) e.code: e,
    };
    // Les langues du public de l'academie, en cartes, pour les deux
    // questions (l'arabe est une langue de cours depuis le 06/11/2026). Les
    // autres se trouvent par la recherche.
    const List<String> courants = languesDuPublic;
    return ChoixAvecRecherche(
      cle: 'langues-${champ.code}',
      multiple: multiple,
      courants: <ElementChoix>[
        for (final String c in courants)
          if (parCode[c] case final ElementChoix e) e,
      ],
      tous: tous,
      selection: controleur.valeurs(champ.code),
      textes: TextesRecherche(
        recherche: r.recherche,
        aide: r.rechercheAide,
        aucun: r.aucune,
        retour: r.retour,
      ),
      onChange: (Set<String> s) {
        // L'ordre du serveur, pas l'ordre des touches.
        final List<String> codes = <String>[
          for (final OptionQuestionnaire o in champ.options)
            if (s.contains(o.code)) o.code,
        ];
        controleur.repondre(
          champ.code,
          multiple ? codes : (codes.isEmpty ? null : codes.first),
        );
      },
    );
  }
}

/// Le nombre de Classes que la personne veut tenir : de 1 au maximum que la
/// direction fixe (les options viennent du serveur), avec ce que cela
/// represente en heures par semaine.
class _Classes extends StatelessWidget {
  const _Classes({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.classes;
    final bool enfants = controleur.avecEnfants || !controleur.avecAdultes;
    final bool adultes = controleur.avecAdultes;
    final Set<String> choisies = controleur.valeurs(champ.code);
    return ChoiceCardGroup(
      key: ValueKey<String>('q-${champ.code}'),
      autoriserSaisieLibre: false,
      valeurInitiale: choisies.isEmpty ? null : ReponseChoix(valeurs: choisies),
      options: <OptionChoix>[
        for (final OptionQuestionnaire o in champ.options)
          if (int.tryParse(o.code) case final int n when n >= 1)
            () {
              final int seances = n * seancesParClasse;
              final String heuresEnfants = libelleDuree(
                seances * dureeSeanceEnfantMinutes,
              );
              final String heuresAdultes = libelleDuree(
                seances * dureeSeanceAdulteMinutes,
              );
              return OptionChoix(
                cle: ValueKey<String>('option-${champ.code}-${o.code}'),
                valeur: o.code,
                libelle: r.libelle(n: n),
                description: <String>[
                  r.seances(n: seances),
                  if (enfants && adultes)
                    r.heuresLesDeux(
                      enfants: heuresEnfants,
                      adultes: heuresAdultes,
                    )
                  else if (adultes)
                    r.heuresAdultes(heures: heuresAdultes)
                  else
                    r.heuresEnfants(heures: heuresEnfants),
                ].join(' '),
                explication: r.explication,
                exemple: switch (n) {
                  1 => r.exemple1,
                  2 => r.exemple2,
                  _ => r.exemplePlusieurs(n: n),
                },
                icone: AppIcons.classes,
                illustration: const IllustrationChoix(
                  AppIcons.classes,
                  autour: <AppIcon>[AppIcons.horloge],
                ),
              );
            }(),
      ],
      onChange: (ReponseChoix reponse) {
        if (reponse.valeurs.isNotEmpty) {
          controleur.repondre(champ.code, reponse.valeurs.first);
        }
      },
    );
  }
}

/// Les moyens de paiement que l'academie connait, au choix : une question
/// facultative et informative, qui n'ecarte personne.
class _MoyensAccessibles extends StatelessWidget {
  const _MoyensAccessibles({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.moyens;
    final Set<String> choisis = controleur.valeurs(champ.code);
    final List<OptionQuestionnaire> moyens = <OptionQuestionnaire>[
      for (final OptionQuestionnaire o in champ.options)
        if (o.nom != null) o,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Info(texte: r.nonElimine, cle: const ValueKey<String>('moyens-info')),
        Ecart.vLg,
        ChoiceCardGroup(
          key: ValueKey<String>('q-${champ.code}'),
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          valeurInitiale: choisis.isEmpty
              ? null
              : ReponseChoix(valeurs: choisis),
          options: <OptionChoix>[
            for (final OptionQuestionnaire o in moyens)
              OptionChoix(
                cle: ValueKey<String>('option-${champ.code}-${o.code}'),
                valeur: o.code,
                libelle: o.nom!,
                description: o.methode == 'virement_bancaire'
                    ? r.virement
                    : r.mobile,
                explication: r.explication,
                icone: AppIcons.appareil,
              ),
          ],
          onChange: (ReponseChoix reponse) =>
              controleur.repondre(champ.code, <String>[
                for (final OptionQuestionnaire o in moyens)
                  if (reponse.valeurs.contains(o.code)) o.code,
              ]),
        ),
      ],
    );
  }
}

class _Pays extends StatelessWidget {
  const _Pays({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.pays;
    final Set<String> permis = <String>{
      for (final OptionQuestionnaire o in champ.options) o.code,
    };
    final List<ElementChoix> tous =
        <ElementChoix>[
          for (final PaysIso p in paysIso)
            if (permis.contains(p.code))
              ElementChoix(
                code: p.code,
                libelle: p.nom,
                motsCles: motsClesDuPays(p),
                cle: ValueKey<String>('option-${champ.code}-${p.code}'),
              ),
        ]..sort(
          (ElementChoix a, ElementChoix b) =>
              formeDeRecherche(a.libelle)
                  .compareTo(formeDeRecherche(b.libelle)),
        );
    final Map<String, ElementChoix> parCode = <String, ElementChoix>{
      for (final ElementChoix e in tous) e.code: e,
    };
    return ChoixAvecRecherche(
      cle: 'pays-${champ.code}',
      courants: <ElementChoix>[
        for (final String c in paysCourants)
          if (parCode[c] case final ElementChoix e) e,
      ],
      tous: tous,
      selection: controleur.valeurs(champ.code),
      textes: TextesRecherche(
        recherche: r.recherche,
        aide: r.rechercheAide,
        aucun: r.aucun,
        retour: r.retour,
      ),
      onChange: (Set<String> s) {
        if (s.isNotEmpty) {
          controleur.repondre(champ.code, s.first);
        }
      },
    );
  }
}

/// PE-B8 : une aide courte posee a cote d'une question au vocabulaire
/// specialise (l'ijaza, le juz). Repliee, une ligne qui dit la question que
/// la personne se pose ; touchee, la reponse en quelques phrases dessous.
class AideQuestion extends StatefulWidget {
  /// Cree l'aide.
  const AideQuestion({
    required this.cle,
    required this.titre,
    required this.texte,
    super.key,
  });

  /// Le prefixe des cles (tests) : `<cle>` sur le lien, `<cle>-texte` sur
  /// la reponse.
  final String cle;

  /// La question que la personne se pose (« Qu'est-ce qu'une ijaza ? »).
  final String titre;

  /// La reponse.
  final String texte;

  @override
  State<AideQuestion> createState() => _AideQuestionState();
}

class _AideQuestionState extends State<AideQuestion> {
  bool _ouverte = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          expanded: _ouverte,
          child: LienFleche(
            key: ValueKey<String>(widget.cle),
            libelle: widget.titre,
            icone: AppIcons.info,
            fleche: false,
            alignerEnDebut: true,
            onPress: () => setState(() => _ouverte = !_ouverte),
          ),
        ),
      ),
      if (_ouverte) ...<Widget>[
        Ecart.vSm,
        AppCard(
          key: ValueKey<String>('${widget.cle}-texte'),
          child: Text(
            widget.texte,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    ],
  );
}

/// PE-B1 : combien du Coran la personne a memorise. « Tout le Coran », « un
/// nombre precis de juz » (de 1 a 29, au compteur ou par un raccourci), ou
/// « rien pour l'instant ». Une ancienne reponse en tranche (« moins de
/// 10 juz ») reste choisie et valable tant que la personne ne donne pas de
/// nombre : elle se lit au-dessus du compteur.
class _Juz extends StatefulWidget {
  const _Juz({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  /// Les raccourcis du compteur.
  static const List<int> raccourcis = <int>[5, 10, 15, 20];

  /// La valeur interne de la carte « un nombre precis de juz ».
  static const String valeurNombre = r'$nombre';

  @override
  State<_Juz> createState() => _JuzState();
}

class _JuzState extends State<_Juz> {
  /// La carte « un nombre precis » touchee pendant cette visite, avant tout
  /// nombre choisi : le compteur s'ouvre, rien n'est retenu.
  bool _nombreTouche = false;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.juz;
    final aides = t.recrutement.parcours.aides;
    final ChampQuestionnaire champ = widget.champ;
    final Object? brute = widget.controleur.reponse(champ.code);
    final String? code = brute is String ? brute : null;
    final int? nombre = juzExact(code);
    final bool ancienne = memorisationAnciennes.contains(code);
    final String? carte = code == memorisationTout || code == memorisationRien
        ? code
        : (nombre != null || ancienne || _nombreTouche)
        ? _Juz.valeurNombre
        : null;
    final ModeleQuestion? modele = modelesQuestions[champ.code];
    OptionChoix? option(String valeur) {
      final TextesOption? x = textesOption(champ.code, valeur);
      return x == null
          ? null
          : OptionChoix(
              cle: ValueKey<String>('option-${champ.code}-$valeur'),
              valeur: valeur,
              libelle: x.libelle,
              description: x.description,
              explication: x.explication,
              exemple: x.exemple,
              icone: modele?.icones[valeur],
            );
    }

    void repondre(int n) => widget.controleur.repondre(champ.code, codeJuz(n));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AideQuestion(
          cle: 'aide-juz',
          titre: aides.juzTitre,
          texte: aides.juzTexte,
        ),
        Ecart.vLg,
        ChoiceCardGroup(
          key: ValueKey<String>('q-${champ.code}-$carte'),
          autoriserSaisieLibre: false,
          valeurInitiale: carte == null
              ? null
              : ReponseChoix(valeurs: <String>{carte}),
          options: <OptionChoix>[
            ?option(memorisationTout),
            OptionChoix(
              cle: ValueKey<String>('option-${champ.code}-nombre'),
              valeur: _Juz.valeurNombre,
              libelle: r.nombre,
              description: r.nombreDescription,
              explication: r.nombreExplication,
              exemple: r.nombreExemple,
              icone: AppIcons.livreOuvert,
            ),
            ?option(memorisationRien),
          ],
          onChange: (ReponseChoix reponse) {
            if (reponse.valeurs.isEmpty) return;
            final String v = reponse.valeurs.first;
            if (v == _Juz.valeurNombre) {
              // Rien n'est retenu tant que la personne ne choisit pas un
              // nombre : une ancienne tranche reste telle quelle ; « tout le
              // Coran » ou « rien » ne valent plus, et « Continuer » demande
              // le nombre.
              setState(() => _nombreTouche = true);
              if (code == memorisationTout || code == memorisationRien) {
                widget.controleur.repondre(champ.code, null);
              }
            } else {
              setState(() => _nombreTouche = false);
              widget.controleur.repondre(champ.code, v);
            }
          },
        ),
        if (carte == _Juz.valeurNombre) ...<Widget>[
          Ecart.vLg,
          if (ancienne && textesOption(champ.code, code!) != null) ...<Widget>[
            Text(
              r.ancienne(reponse: textesOption(champ.code, code)!.libelle),
              key: const ValueKey<String>('juz-ancienne'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Ecart.vMd,
          ],
          ChoixNombre(
            key: const ValueKey<String>('juz-compteur'),
            libelle: r.compteur,
            libelleMoins: r.moins,
            libellePlus: r.plus,
            // Sans nombre ni tranche, le compteur part de « choisissez » (0,
            // jamais retenu) : « plus » donne 1 juz. Une ancienne tranche se
            // lit telle quelle au centre, et le premier toucher donne un
            // nombre DANS la tranche (moins de 10 : 4 ou 6 ; de 10 a 29 :
            // 14 ou 16).
            min: nombre == null && !ancienne ? 0 : 1,
            max: juzMaximum,
            valeur: nombre ?? (ancienne ? _milieuTranche(code!) : 0),
            affichage: (int n) => nombre == null
                ? (ancienne ? _trancheCourte(code!) : r.choisir)
                : r.valeur(n: n),
            onChange: (int n) {
              if (n >= 1) repondre(n);
            },
          ),
          Ecart.vMd,
          // Choix de formulaire, pas un filtre : les raccourcis du compteur.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final int n in _Juz.raccourcis)
                FilterPill(
                  key: ValueKey<String>('juz-raccourci-$n'),
                  libelle: r.valeur(n: n),
                  retenue: nombre == n,
                  onPress: () => repondre(n),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// La valeur de depart du compteur pour une ancienne tranche : un nombre dans
/// la tranche, dont les deux voisins y restent aussi.
int _milieuTranche(String code) => code == 'de_10_a_29_juz' ? 15 : 5;

/// Une ancienne tranche, en mots courts (« Moins de 10 juz »).
String _trancheCourte(String code) {
  final v = t.recrutement.dossier3.synthese.memorisationValeurs;
  return code == 'de_10_a_29_juz' ? v.de_10_a_29_juz : v.moins_10_juz;
}

/// PE-B1 (directeur, 19/11/2026, Q3) : les riwayat. Quatre reponses : les dix
/// qiraat (les vingt riwayat), les sept (les quatorze riwayat des sept
/// lecteurs), une seule riwaya (choisie dans la liste), ou quelques-unes
/// (choisies lecteur par lecteur, avec une recherche). Le serveur recoit
/// toujours la liste des codes, comme avant. Une reponse deja enregistree se
/// relit telle que la personne l'a donnee ([modeDesRiwayat]) : un code, « une
/// seule » ; plusieurs, la grille avec exactement ces codes coches, jamais les
/// cartes « dix » ou « sept », qui annoncent une ijaza que rien de stocke ne
/// porte. Ces deux cartes ne s'affichent choisies que touchees a cette visite.
class _Riwayat extends StatefulWidget {
  const _Riwayat({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  @override
  State<_Riwayat> createState() => _RiwayatState();
}

class _RiwayatState extends State<_Riwayat> {
  /// Le mode choisi a cet ecran ; sans choix, celui de la reponse lue.
  ModeRiwayat? _mode;

  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  /// Les codes dans l'ordre du serveur, pas l'ordre des touches.
  void _repondre(Set<String> codes) =>
      widget.controleur.repondre(widget.champ.code, <String>[
        for (final OptionQuestionnaire o in widget.champ.options)
          if (codes.contains(o.code)) o.code,
      ]);

  void _choisirMode(ModeRiwayat mode, Set<String> selection) {
    setState(() => _mode = mode);
    switch (mode) {
      case ModeRiwayat.dix:
        _repondre(riwayatDix);
      case ModeRiwayat.sept:
        _repondre(riwayatSept);
      case ModeRiwayat.une:
        // Plusieurs codes retenus restent retenus tant qu'aucune riwaya n'est
        // choisie ici : revenir a « quelques-unes » les retrouve.
        break;
      case ModeRiwayat.quelques:
        // Ce qui etait retenu le reste : on retire ce qu'on ne recite pas.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.riwayat;
    final ChampQuestionnaire champ = widget.champ;
    final Set<String> selection = widget.controleur.valeurs(champ.code);
    final ModeRiwayat? mode = _mode ?? modeDesRiwayat(selection);
    final Map<String, TextesOption> textes = <String, TextesOption>{
      for (final OptionQuestionnaire o in champ.options)
        if (textesOption(champ.code, o.code) case final TextesOption x)
          o.code: x,
    };
    OptionChoix carte(ModeRiwayat m, String libelle, String description) =>
        OptionChoix(
          cle: ValueKey<String>('option-${champ.code}-${m.name}'),
          valeur: m.name,
          libelle: libelle,
          description: description,
          icone: switch (m) {
            ModeRiwayat.dix || ModeRiwayat.sept => AppIcons.etoile,
            ModeRiwayat.une => AppIcons.livreOuvert,
            ModeRiwayat.quelques => AppIcons.liste,
          },
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChoiceCardGroup(
          key: ValueKey<String>('q-${champ.code}-${mode?.name}'),
          autoriserSaisieLibre: false,
          valeurInitiale: mode == null
              ? null
              : ReponseChoix(valeurs: <String>{mode.name}),
          options: <OptionChoix>[
            carte(ModeRiwayat.dix, r.dix, r.dixDescription),
            carte(ModeRiwayat.sept, r.sept, r.septDescription),
            carte(ModeRiwayat.une, r.une, r.uneDescription),
            carte(ModeRiwayat.quelques, r.quelques, r.quelquesDescription),
          ],
          onChange: (ReponseChoix reponse) {
            if (reponse.valeurs.isEmpty) return;
            _choisirMode(
              ModeRiwayat.values.byName(reponse.valeurs.first),
              selection,
            );
          },
        ),
        if (mode == ModeRiwayat.une) ...<Widget>[
          Ecart.vXl,
          TitreChamp(r.titreUne, style: Theme.of(context).textTheme.titleSmall),
          Ecart.vSm,
          _une(textes, selection),
        ],
        if (mode == ModeRiwayat.quelques) ...<Widget>[
          Ecart.vXl,
          TitreChamp(
            r.titreQuelques,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Ecart.vMd,
          ..._grille(context, textes, selection),
        ],
      ],
    );
  }

  /// Une seule riwaya : les plus connues, puis la recherche.
  Widget _une(Map<String, TextesOption> textes, Set<String> selection) {
    final r = t.recrutement.parcours.riwayat;
    final ChampQuestionnaire champ = widget.champ;
    final List<ElementChoix> tous = <ElementChoix>[
      for (final MapEntry<String, TextesOption> e in textes.entries)
        ElementChoix(
          code: e.key,
          libelle: e.value.libelle,
          description: e.value.description,
          cle: ValueKey<String>('option-${champ.code}-${e.key}'),
        ),
    ];
    final Map<String, ElementChoix> parCode = <String, ElementChoix>{
      for (final ElementChoix e in tous) e.code: e,
    };
    return ChoixAvecRecherche(
      cle: 'riwayat-une',
      courants: <ElementChoix>[
        for (final String c in riwayatCourantes)
          if (parCode[c] case final ElementChoix e) e,
      ],
      tous: tous,
      // Plusieurs codes retenus (une reponse de « quelques-unes ») : rien n'est
      // coche dans la liste d'une seule riwaya, et rien n'est efface.
      selection: selection.length == 1 ? selection : const <String>{},
      textes: TextesRecherche(
        recherche: r.recherche,
        aide: r.rechercheAide,
        aucun: r.aucune,
        retour: r.retour,
      ),
      onChange: _repondre,
    );
  }

  /// Quelques riwayat : la recherche, puis chaque lecteur et ses deux
  /// riwayat, cote a cote.
  List<Widget> _grille(
    BuildContext context,
    Map<String, TextesOption> textes,
    Set<String> selection,
  ) {
    final r = t.recrutement.parcours.riwayat;
    final ChampQuestionnaire champ = widget.champ;
    final String q = formeDeRecherche(_recherche.text);
    final List<({String lecteur, List<String> riwayat})>
    lecteurs = <({String lecteur, List<String> riwayat})>[
      for (final l in lecteursRiwayat)
        if (l.riwayat.every(textes.containsKey) &&
            (q.isEmpty ||
                formeDeRecherche(
                  '${_nomLecteur(l.lecteur)} '
                  '${l.riwayat.map((String c) => textes[c]!.libelle).join(' ')}',
                ).contains(q)))
          l,
    ];
    return <Widget>[
      ChampRecherche(
        cleChamp: const ValueKey<String>('riwayat-grille-recherche'),
        controleur: _recherche,
        libelle: r.rechercheLecteur,
        aide: r.rechercheLecteurAide,
        onChange: (String _) => setState(() {}),
      ),
      Ecart.vLg,
      if (lecteurs.isEmpty)
        Text(r.aucune, style: Theme.of(context).textTheme.bodyMedium),
      for (final (int i, ({String lecteur, List<String> riwayat}) l)
          in lecteurs.indexed) ...<Widget>[
        if (i > 0) Ecart.vLg,
        TitreChamp(
          _nomLecteur(l.lecteur),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Ecart.vSm,
        ChoiceCardGroup(
          key: ValueKey<String>(
            'riwayat-lecteur-${l.lecteur}-'
            '${l.riwayat.where(selection.contains).join('+')}',
          ),
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          indicationMultiple: false,
          enLigne: true,
          valeurInitiale: ReponseChoix(
            valeurs: <String>{...l.riwayat.where(selection.contains)},
          ),
          options: <OptionChoix>[
            for (final String c in l.riwayat)
              OptionChoix(
                cle: ValueKey<String>('option-${champ.code}-$c'),
                valeur: c,
                libelle: textes[c]!.libelle,
              ),
          ],
          onChange: (ReponseChoix reponse) => _repondre(<String>{
            ...selection.difference(l.riwayat.toSet()),
            ...reponse.valeurs.where(l.riwayat.contains),
          }),
        ),
      ],
    ];
  }
}

/// Le nom d'un lecteur, par son code de [lecteursRiwayat].
String _nomLecteur(String code) {
  final l = t.recrutement.parcours.riwayat.lecteurs;
  return switch (code) {
    'nafi' => l.nafi,
    'ibnKathir' => l.ibnKathir,
    'abuAmr' => l.abuAmr,
    'ibnAmir' => l.ibnAmir,
    'asim' => l.asim,
    'hamza' => l.hamza,
    'kisai' => l.kisai,
    'abuJafar' => l.abuJafar,
    'yaqub' => l.yaqub,
    _ => l.khalaf,
  };
}

class _Operateurs extends ConsumerWidget {
  const _Operateurs({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.recrutement.parcours.versement;
    final Object? pays = controleur.reponse('paysVersement');
    if (pays is! String) {
      return const SizedBox.shrink();
    }
    final AsyncValue<MoyensConfirmes> valeur = ref.watch(
      moyensConfirmesProvider(pays),
    );
    return BlocAsynchrone<MoyensConfirmes>(
      key: ValueKey<String>('operateurs-$pays'),
      valeur: valeur,
      squelette: const Skeleton.liste(lignes: 2),
      titreEchec: r.nonCharge,
      onReessayer: () => ref.invalidate(moyensConfirmesProvider(pays)),
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
          erreur is HorsLigneCandidature
          ? EtatSansDonnees(quoi: r.nonCharge, onAction: reessayer)
          : null,
      construire: (MoyensConfirmes moyens) {
        if (moyens.operateurs.isEmpty) {
          if (moyens.virementBancaire) {
            return _Info(texte: r.virementSeul);
          }
          // PAYS-VERSEMENT : pays pas encore pris en charge. La phrase dit
          // quoi faire (le pays d'un proche) et le lien ramene au choix ; la
          // candidature n'est jamais refusee pour ce seul motif.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Info(
                texte: r.aucunMoyen,
                cle: const ValueKey<String>('versement-pays-non-pris'),
              ),
              Ecart.vSm,
              LienFleche(
                key: const ValueKey<String>('versement-changer-pays'),
                libelle: r.changerPays,
                alignerEnDebut: true,
                onPress: () => controleur.allerAuChamp('paysVersement'),
              ),
            ],
          );
        }
        final Set<String> choisis = controleur.valeurs(champ.code);
        return ChoiceCardGroup(
          key: ValueKey<String>('q-${champ.code}-$pays'),
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          valeurInitiale: choisis.isEmpty
              ? null
              : ReponseChoix(valeurs: choisis),
          options: <OptionChoix>[
            for (final OperateurPaiement o in moyens.operateurs)
              OptionChoix(
                cle: ValueKey<String>('option-${champ.code}-${o.code}'),
                valeur: o.code,
                libelle: o.nom,
                description: r.operateurDescription,
                explication: r.operateurExplication,
                icone: AppIcons.appareil,
              ),
          ],
          onChange: (ReponseChoix reponse) =>
              controleur.repondre(champ.code, <String>[
                for (final OperateurPaiement o in moyens.operateurs)
                  if (reponse.valeurs.contains(o.code)) o.code,
              ]),
        );
      },
    );
  }
}

/// Une phrase d'information dans une carte, sans choix a faire.
class _Info extends StatelessWidget {
  const _Info({
    required this.texte,
    this.cle = const ValueKey<String>('versement-info'),
  });

  final String texte;
  final Key cle;

  @override
  Widget build(BuildContext context) => AppCard(
    key: cle,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: IconTheme(
            data: AppPalette.of(context).inkAccent
                .asIconTheme(size: AppSpacing.xxl),
            child: Icon(AppIcons.info.repos),
          ),
        ),
        Ecart.hMd,
        Expanded(
          child: Text(texte, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

// Le corps d'une question du parcours (CAND-01) : tout se choisit en touchant
// des cartes. Chaque choix est decrit pour des personnes peu a l'aise avec la
// technologie : ce que c'est (description), ce que le choix entraine
// (explication), un cas concret (exemple). Les textes viennent de
// `assets/i18n`, par le code que le serveur rend ; un code sans texte ne
// s'affiche pas.
//
// Les listes longues (langues, pays, riwayat) montrent d'abord leurs choix
// courants en cartes ; « Autre ... » ouvre une recherche (`ChoixAvecRecherche`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/creneaux_declares.dart';
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
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/skeleton.dart';
import 'choix_avec_recherche.dart';
import 'controleur_parcours.dart';
import 'fuseau_etape.dart';
import 'grille_creneaux.dart';
import 'libelles_parcours.dart';
import 'modele_questions.dart';

/// Les pays proposes d'emblee : les pays des enseignants de l'academie
/// (FORM-L8, `codesIsoDesPays`) et l'Arabie saoudite, nommee par la decision
/// du directeur sur le versement (CAND-Q05).
const List<String> paysCourants = <String>[
  'FR',
  'BE',
  'ES',
  'GB',
  'IE',
  'GN',
  'SN',
  'ML',
  'MR',
  'MA',
  'CI',
  'BF',
  'TG',
  'NE',
  'NG',
  'TD',
  'CM',
  'CA',
  'US',
  'SA',
];

/// Les riwayat proposees d'emblee ; les autres se trouvent par la recherche.
const List<String> riwayatCourantes = <String>[
  'hafs',
  'warsh',
  'qalun',
  'shuba',
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
        return _Cartes(champ: champ, controleur: controleur, multiple: false);
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
        return _Plages(controleur: controleur);
      case FormeQuestion.fuseau:
        return FuseauEtape(
          options: <String>[for (final o in champ.options) o.code],
          choisi: controleur.fuseau,
          onChange: (String zone) => controleur.repondre(champ.code, zone),
        );
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
        if (nomDeLangue(o.code) case final String nom)
          ElementChoix(
            code: o.code,
            libelle: nom,
            // Dire quelles langues Rewayah enseigne n'a de sens que pour les
            // langues d'explication ; la langue maternelle peut etre toute
            // autre langue, sans commentaire.
            description: !multiple
                ? null
                : o.horsReferentiel
                ? r.horsReferentiel
                : r.dansReferentiel,
            cle: ValueKey<String>('option-${champ.code}-${o.code}'),
          ),
    ];
    final Set<String> referentiel = <String>{
      for (final OptionQuestionnaire o in champ.options)
        if (!o.horsReferentiel) o.code,
    };
    return ChoixAvecRecherche(
      cle: 'langues-${champ.code}',
      multiple: multiple,
      courants: <ElementChoix>[
        for (final ElementChoix e in tous)
          if (referentiel.contains(e.code)) e,
      ],
      tous: tous,
      selection: controleur.valeurs(champ.code),
      textes: TextesRecherche(
        autre: r.autre,
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
        autre: r.autre,
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

class _Riwayat extends StatelessWidget {
  const _Riwayat({required this.champ, required this.controleur});

  final ChampQuestionnaire champ;
  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.parcours.riwayat;
    final List<ElementChoix> tous = <ElementChoix>[
      for (final OptionQuestionnaire o in champ.options)
        if (textesOption(champ.code, o.code) case final TextesOption x)
          ElementChoix(
            code: o.code,
            libelle: x.libelle,
            description: x.description,
            cle: ValueKey<String>('option-${champ.code}-${o.code}'),
          ),
    ];
    final Map<String, ElementChoix> parCode = <String, ElementChoix>{
      for (final ElementChoix e in tous) e.code: e,
    };
    return ChoixAvecRecherche(
      cle: 'riwayat',
      multiple: true,
      courants: <ElementChoix>[
        for (final String c in riwayatCourantes)
          if (parCode[c] case final ElementChoix e) e,
      ],
      tous: tous,
      selection: controleur.valeurs(champ.code),
      textes: TextesRecherche(
        autre: r.autre,
        recherche: r.recherche,
        aide: r.rechercheAide,
        aucun: r.aucune,
        retour: r.retour,
      ),
      onChange: (Set<String> s) => controleur.repondre(champ.code, <String>[
        for (final OptionQuestionnaire o in champ.options)
          if (s.contains(o.code)) o.code,
      ]),
    );
  }
}

class _Plages extends StatelessWidget {
  const _Plages({required this.controleur});

  final ParcoursControleur controleur;

  @override
  Widget build(BuildContext context) {
    final CreneauxDeclares creneaux = controleur.creneaux;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.recrutement.parcours.creneaux;
    final String? zone = controleur.fuseau;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (zone != null) ...<Widget>[
          Text(
            r.fuseauRappel(lieu: nomDeLieu(zone)),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        GrilleCreneaux(
          creneaux: creneaux,
          onBascule: (int jour, int plage) => controleur.declarerPlages(
            creneaux.bascule(jour: jour, plage: plage),
          ),
        ),
        Ecart.vLg,
        Semantics(
          liveRegion: true,
          child: Text(
            r.choisies(n: creneaux.nombrePleines),
            key: const ValueKey<String>('plages-resume'),
            style: textes.titleSmall,
          ),
        ),
      ],
    );
  }
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
          return _Info(
            texte: moyens.virementBancaire ? r.virementSeul : r.aucunMoyen,
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
  const _Info({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) => AppCard(
    key: const ValueKey<String>('versement-info'),
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

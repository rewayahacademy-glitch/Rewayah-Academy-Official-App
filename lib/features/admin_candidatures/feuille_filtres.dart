// BE-LISTE-2 : la feuille « Filtres » et la feuille « Trier » de la liste des
// candidatures.
//
// Un seul bouton pour filtrer, un seul pour trier. « Filtres » contient tous
// les filtres de la liste : la salle, l'etat, l'issue, la pause, le versement,
// le pays, le genre, la piece, le responsable, les reponses (ijaza, langue,
// riwaya, public, jours, heures) et les autres competences. Au telephone c'est
// une feuille, a l'ordinateur une boite (`AppBottomSheet`). Chaque choix
// s'applique tout de suite a la liste derriere la feuille ; la feuille n'a ni
// « Appliquer » ni faux bouton.
//
// Les phrases d'explication des files (« la plus ancienne depuis 1 jour »)
// sont dites ici, en petit, sous le nom de chaque file : la rangee des files
// garde la place pour les noms.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../candidature/libelles_parcours.dart';
import '../talents/libelles_talents.dart';
import 'files_candidatures.dart';
import 'libelles_candidatures.dart';

/// Les codes de langue d'explication que la direction peut filtrer.
const List<String> _langues = <String>['ar', 'fr', 'en'];

/// Les riwayat proposees (les plus connues).
const List<String> _riwayat = <String>[
  'hafs',
  'warsh',
  'qalun',
  'shuba',
  'ad_duri_abi_amr',
  'as_susi',
];

/// Les publics vises, dans l'ordre.
const List<String> _publics = <String>['6_9', '10_13', '14_17', 'adultes'];

/// Les trois valeurs de l'ijaza declaree.
const List<String> _ijazas = <String>['oui', 'pret_test', 'non'];

/// Le libelle d'une option du questionnaire, ou son code a defaut.
String _option(String champ, String code) =>
    textesOption(champ, code)?.libelle ?? code;

/// Ouvre la feuille « Filtres ».
///
/// [lire] rend le filtre courant de la page (la feuille se reconstruit apres
/// chaque choix) ; [poser] le change.
Future<void> ouvrirFeuilleFiltres(
  BuildContext context, {
  required FiltreCandidatures Function() lire,
  required void Function(FiltreCandidatures) poser,
  required List<FileCandidatures> Function() files,
  bool garderPourSuivi = false,
}) => AppBottomSheet.ouvrir<void>(
  context,
  titre: t.recrutement.file.filtres,
  constructeur: (BuildContext contexte) => FeuilleFiltres(
    lire: lire,
    poser: poser,
    files: files,
    garderPourSuivi: garderPourSuivi,
    onFermer: () => Navigator.of(contexte).pop(),
  ),
);

/// Le corps de la feuille « Filtres ».
class FeuilleFiltres extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleFiltres({
    required this.lire,
    required this.poser,
    required this.files,
    required this.onFermer,
    this.garderPourSuivi = false,
    super.key,
  });

  /// Le serveur ouvre « Garder pour suivi » : la salle « Gardees » est
  /// proposee (jamais sans lui).
  final bool garderPourSuivi;

  /// Le filtre courant de la page.
  final FiltreCandidatures Function() lire;

  /// Change le filtre de la page.
  final void Function(FiltreCandidatures) poser;

  /// Les files, avec leurs phrases.
  final List<FileCandidatures> Function() files;

  /// La feuille se ferme.
  final VoidCallback onFermer;

  /// La cle de la phrase d'explication de la file [cle].
  static Key cleExplication(String cle) =>
      ValueKey<String>('feuille-filtres-file-$cle');

  /// La cle du lien « Effacer les filtres ».
  static const Key cleEffacer = ValueKey<String>('feuille-filtres-effacer');

  @override
  ConsumerState<FeuilleFiltres> createState() => _FeuilleFiltresEtat();
}

class _FeuilleFiltresEtat extends ConsumerState<FeuilleFiltres> {
  late FiltreCandidatures _f = widget.lire();

  void _poser(FiltreCandidatures f) {
    widget.poser(f);
    setState(() => _f = f);
  }

  EntreeFiltre<T> _tous<T>() =>
      EntreeFiltre<T>(valeur: null, libelle: t.admin.candidatures.filtres.tous);

  /// Un menu de filtre : [libelle] dit l'axe, [valeurs] les choix.
  Widget _menu<T>(
    String cle,
    String libelle,
    T? valeur,
    List<EntreeFiltre<T>> entrees,
    FiltreCandidatures Function(T?) pose,
  ) => MenuFiltre<T>(
    key: ValueKey<String>('feuille-filtre-$cle'),
    libelle: libelle,
    valeur: valeur,
    entrees: <EntreeFiltre<T>>[_tous<T>(), ...entrees],
    onChoix: (T? v) => _poser(pose(v)),
  );

  @override
  Widget build(BuildContext context) {
    final f = t.admin.candidatures.filtres;
    final r = t.recrutement.file;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final CatalogueCompetences? catalogue = ref
        .watch(catalogueCompetencesProvider)
        .value;

    final List<PaysIso> pays = <PaysIso>[...paysIso]
      ..sort(
        (PaysIso a, PaysIso b) =>
            formeDeRecherche(a.nom).compareTo(formeDeRecherche(b.nom)),
      );

    // Les files qui ont une phrase a dire.
    final List<FileCandidatures> expliquees = widget.files().where((
      FileCandidatures x,
    ) {
      final String? e = x.explication;
      return e != null && e.isNotEmpty;
    }).toList();

    final List<EntreeFiltre<String>> entreesDomaine = <EntreeFiltre<String>>[
      for (final FamilleCompetence famille in FamilleCompetence.values) ...[
        if (famille != FamilleCompetence.autre)
          EntreeFiltre<String>(
            valeur: famille.valeurSql,
            libelle: f.talents.familleToutes(famille: titreFamille(famille)),
          ),
        for (final EntreeCatalogue e
            in catalogue?.competences ?? const <EntreeCatalogue>[])
          if (e.familleCode == famille.valeurSql)
            EntreeFiltre<String>(
              valeur: e.code,
              libelle: nomDomaineFiltre(e.code, catalogue: catalogue),
            ),
      ],
    ];

    final List<Widget> menus = <Widget>[
      _menu<EtapeCandidature>(
        'salle',
        r.salle,
        _f.etape,
        <EntreeFiltre<EtapeCandidature>>[
          for (final EtapeCandidature e in EtapeCandidature.values)
            if (e != EtapeCandidature.recue || widget.garderPourSuivi)
              EntreeFiltre<EtapeCandidature>(
                valeur: e,
                libelle: switch (e) {
                  EtapeCandidature.invitee => f.invitees,
                  EtapeCandidature.recue => f.gardees,
                  _ => libelleSalle(e) ?? '',
                },
              ),
        ],
        (EtapeCandidature? v) => _f.avec(etape: () => v),
      ),
      _menu<EtatCandidature>(
        'etat',
        f.etat,
        _f.etat,
        <EntreeFiltre<EtatCandidature>>[
          for (final EtatCandidature e in EtatCandidature.values)
            EntreeFiltre<EtatCandidature>(valeur: e, libelle: libelleEtat(e)),
        ],
        (EtatCandidature? v) => _f.avec(etat: () => v),
      ),
      _menu<IssueCandidature>(
        'issue',
        f.issue,
        _f.issue,
        <EntreeFiltre<IssueCandidature>>[
          for (final IssueCandidature i in IssueCandidature.values)
            EntreeFiltre<IssueCandidature>(valeur: i, libelle: libelleIssue(i)),
        ],
        (IssueCandidature? v) => _f.avec(issue: () => v),
      ),
      _menu<bool>('pause', f.pause, _f.enPause, <EntreeFiltre<bool>>[
        EntreeFiltre<bool>(
          valeur: true,
          libelle: t.admin.candidatures.etats.enPause,
        ),
        EntreeFiltre<bool>(valeur: false, libelle: f.sansPause),
      ], (bool? v) => _f.avec(enPause: () => v)),
      _menu<EtatVersement>(
        'versement',
        f.versement,
        _f.paiement,
        <EntreeFiltre<EtatVersement>>[
          for (final EtatVersement v in EtatVersement.values)
            EntreeFiltre<EtatVersement>(
              valeur: v,
              libelle: libelleVersement(v),
            ),
        ],
        (EtatVersement? v) => _f.avec(paiement: () => v),
      ),
      _menu<bool>('piece', r.piece, _f.pieceEnAttente, <EntreeFiltre<bool>>[
        EntreeFiltre<bool>(
          valeur: true,
          libelle: t.admin.candidatures.attentes.pieceAValider,
        ),
        EntreeFiltre<bool>(valeur: false, libelle: r.pieceSansAttente),
      ], (bool? v) => _f.avec(pieceEnAttente: () => v)),
      _menu<String>(
        'responsable',
        r.responsable,
        _f.responsable,
        <EntreeFiltre<String>>[
          EntreeFiltre<String>(valeur: 'moi', libelle: r.responsableMoi),
          EntreeFiltre<String>(valeur: 'aucun', libelle: r.responsableAucun),
        ],
        (String? v) => _f.avec(responsable: () => v),
      ),
      _menu<String>('genre', f.genre, _f.genre, <EntreeFiltre<String>>[
        EntreeFiltre<String>(
          valeur: 'male',
          libelle: t.admin.candidatures.genres.male,
        ),
        EntreeFiltre<String>(
          valeur: 'female',
          libelle: t.admin.candidatures.genres.female,
        ),
      ], (String? v) => _f.avec(genre: () => v)),
      _menu<String>('pays', f.pays, _f.paysResidence, <EntreeFiltre<String>>[
        for (final PaysIso p in pays)
          EntreeFiltre<String>(valeur: p.code, libelle: p.nom),
      ], (String? v) => _f.avec(paysResidence: () => v)),
      _menu<String>('ijaza', r.ijaza, _f.ijaza, <EntreeFiltre<String>>[
        for (final String c in _ijazas)
          EntreeFiltre<String>(valeur: c, libelle: _option('ijaza', c)),
      ], (String? v) => _f.avec(ijaza: () => v)),
      _menu<String>(
        'langue',
        r.langue,
        _f.langueExplication,
        <EntreeFiltre<String>>[
          for (final String c in _langues)
            EntreeFiltre<String>(valeur: c, libelle: nomDeLangue(c) ?? c),
        ],
        (String? v) => _f.avec(langueExplication: () => v),
      ),
      _menu<String>('riwaya', r.riwaya, _f.riwaya, <EntreeFiltre<String>>[
        for (final String c in _riwayat)
          EntreeFiltre<String>(valeur: c, libelle: _option('riwayat', c)),
      ], (String? v) => _f.avec(riwaya: () => v)),
      _menu<String>('public', r.public, _f.publicVise, <EntreeFiltre<String>>[
        for (final String c in _publics)
          EntreeFiltre<String>(valeur: c, libelle: _option('public', c)),
      ], (String? v) => _f.avec(publicVise: () => v)),
      _menu<int>('heure-de', r.heureDe, _f.heureMin, <EntreeFiltre<int>>[
        for (int h = 0; h < 24; h++)
          EntreeFiltre<int>(valeur: h, libelle: libelleHeure(h)),
      ], (int? v) => _f.avec(heureMin: () => v)),
      _menu<int>('heure-a', r.heureA, _f.heureMax, <EntreeFiltre<int>>[
        for (int h = 1; h <= 24; h++)
          EntreeFiltre<int>(valeur: h, libelle: libelleHeure(h)),
      ], (int? v) => _f.avec(heureMax: () => v)),
      _menu<int>('jours-min', r.joursMin, _f.joursMin, <EntreeFiltre<int>>[
        for (int n = 1; n <= 7; n++)
          EntreeFiltre<int>(
            valeur: n,
            libelle: LibellesGroupe.insecable(r.joursMinN(n: n)),
          ),
      ], (int? v) => _f.avec(joursMin: () => v)),
      _menu<String>(
        'competence',
        f.talents.domaine,
        _f.competenceDomaine,
        entreesDomaine,
        (String? v) => _f.avec(competenceDomaine: () => v),
      ),
      _menu<NiveauCompetence>(
        'competence-niveau',
        f.talents.niveau,
        _f.competenceNiveauMin,
        <EntreeFiltre<NiveauCompetence>>[
          EntreeFiltre<NiveauCompetence>(
            valeur: NiveauCompetence.experience,
            libelle: f.talents.niveauExperience,
          ),
          EntreeFiltre<NiveauCompetence>(
            valeur: NiveauCompetence.metier,
            libelle: f.talents.niveauMetier,
          ),
        ],
        (NiveauCompetence? v) => _f.avec(competenceNiveauMin: () => v),
      ),
      _menu<DisponibiliteMission>(
        'competence-disponibilite',
        f.talents.disponibilite,
        _f.competenceDisponibilite,
        <EntreeFiltre<DisponibiliteMission>>[
          for (final DisponibiliteMission d in DisponibiliteMission.values)
            EntreeFiltre<DisponibiliteMission>(
              valeur: d,
              libelle: libelleDisponibilite(d),
            ),
        ],
        (DisponibiliteMission? v) => _f.avec(competenceDisponibilite: () => v),
      ),
      _menu<bool>(
        'competence-accord',
        f.talents.accord,
        _f.competenceAccord,
        <EntreeFiltre<bool>>[
          EntreeFiltre<bool>(valeur: true, libelle: f.talents.accordDonne),
          EntreeFiltre<bool>(valeur: false, libelle: f.talents.accordAbsent),
        ],
        (bool? v) => _f.avec(competenceAccord: () => v),
      ),
    ];

    final Set<int> jours = <int>{...?_f.jours};
    final bool aucunFiltre = _f.estVide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (expliquees.isNotEmpty) ...<Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              r.files,
              style: palette.inkStrong.applyTo(
                textes.titleSmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
          for (final FileCandidatures x in expliquees) ...<Widget>[
            Column(
              key: FeuilleFiltres.cleExplication(x.cle),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TexteSansCoupure(
                  x.libelle,
                  style: palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                TexteSansCoupure(
                  x.explication!,
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
            Ecart.vSm,
          ],
          Ecart.vMd,
        ],
        // Tous les menus, toutes les puces visibles, qui passent a la ligne
        // (`enPanneau`) : jamais un defilement de cote.
        RangeeFiltres(enPanneau: true, filtres: menus),
        Ecart.vLg,
        Semantics(
          header: true,
          child: TexteSansCoupure(
            r.jours,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        RangeeFiltres(
          enPanneau: true,
          filtres: <Widget>[
            for (int j = 1; j <= 7; j++)
              FilterPill(
                key: ValueKey<String>('feuille-jour-$j'),
                libelle: nomDeJour(j),
                retenue: jours.contains(j),
                onPress: () {
                  final Set<int> suivants = <int>{...jours};
                  if (!suivants.remove(j)) suivants.add(j);
                  final List<int> liste = suivants.toList()..sort();
                  _poser(_f.avec(jours: () => liste.isEmpty ? null : liste));
                },
              ),
          ],
        ),
        if (!aucunFiltre) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: FeuilleFiltres.cleEffacer,
              libelle: t.admin.journal.effacerFiltres,
              fleche: false,
              legende: true,
              onPress: () => _poser(
                // La recherche n'est pas un filtre de cette feuille : elle reste.
                const FiltreCandidatures().avec(recherche: _f.recherche),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ouvre la feuille « Trier ».
Future<void> ouvrirFeuilleTri(
  BuildContext context, {
  required TriCandidatures Function() lire,
  required void Function(TriCandidatures) poser,
}) => AppBottomSheet.ouvrir<void>(
  context,
  titre: t.admin.candidatures.tri.titre,
  constructeur: (BuildContext contexte) => FeuilleTri(
    lire: lire,
    onChoix: (TriCandidatures tri) {
      poser(tri);
      Navigator.of(contexte).pop();
    },
  ),
);

/// Le corps de la feuille « Trier ».
class FeuilleTri extends StatelessWidget {
  /// Cree la feuille.
  const FeuilleTri({required this.lire, required this.onChoix, super.key});

  /// Le tri courant.
  final TriCandidatures Function() lire;

  /// Un tri est choisi.
  final ValueChanged<TriCandidatures> onChoix;

  /// La cle du tri [tri].
  static Key cle(TriCandidatures tri) =>
      ValueKey<String>('feuille-tri-${tri.name}');

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.tri;
    final TriCandidatures courant = lire();
    Widget choix(TriCandidatures tri, String libelle) => FilterPill(
      key: cle(tri),
      libelle: libelle,
      retenue: courant == tri,
      onPress: () => onChoix(tri),
    );
    return RangeeFiltres(
      enPanneau: true,
      filtres: <Widget>[
        choix(TriCandidatures.activite, r.activite),
        choix(TriCandidatures.recente, r.reception),
      ],
    );
  }
}

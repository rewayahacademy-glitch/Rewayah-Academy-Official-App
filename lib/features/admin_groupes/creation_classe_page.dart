import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_programme.dart' show NiveauProgramme;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_niveau_programme.dart';
import '../../core/widgets/skeleton.dart';
import '../classes/carte_classe.dart';
import '../classes/domaine/classe_vm.dart';
import '../classes/domaine/erreur_domaine.dart';
import '../classes/domaine/providers.dart';
import '../classes/grille_classes.dart';
import '../classes/libelles_classes.dart';
import '../disponibilites/grille_semaine.dart';

/// La creation d'une Classe, ou de plusieurs d'un coup.
///
/// **Le systeme preremplit le maximum ; l'administration choisit.** Trois
/// pas, jamais un formulaire generique : le programme et le public, puis les
/// creneaux sur une grille de semaine (une case, une Classe), puis un aperçu
/// de ce qui sera publie. La duree, la capacite et le seuil viennent des
/// regles de l'academie et ne se saisissent que pour faire exception.
///
/// Ce qui n'existe pas ici, par construction : un champ d'identifiant
/// d'enseignant, un « jour = 1 », une « heure = 16 », un calcul de fuseau, une
/// duplication manuelle des occurrences. L'enseignant se choisit dans une
/// liste filtree par le serveur, ou reste « a affecter ».
///
/// **Une page, sur toutes les largeurs.** Sur telephone, le pas courant
/// occupe l'ecran ; des la tablette, l'aperçu vivant se pose a cote. Jamais une
/// feuille geante avec une poignee pour un workflow long, jamais un bouton
/// primaire etire sur 1400 points : la zone d'action est bornee a la largeur
/// d'un formulaire.
///
/// La page se ferme en rendant le nombre de Classes publiees, `null` sur
/// abandon.
class CreationClassePage extends ConsumerStatefulWidget {
  /// Cree la page. [lot] ouvre la generation de plusieurs Classes.
  const CreationClassePage({super.key, this.lot = false});

  /// Vrai pour choisir plusieurs creneaux, une Classe par case.
  final bool lot;

  /// La cle de la grille de creneaux, pour les tests.
  static const Key cleGrille = Key('creation-classe-grille');

  /// La cle du champ de nom, pour les tests.
  static const Key cleNom = Key('creation-classe-nom');

  @override
  ConsumerState<CreationClassePage> createState() => _CreationClassePageEtat();
}

class _CreationClassePageEtat extends ConsumerState<CreationClassePage> {
  int _etape = 0;

  PublicClasse _public = PublicClasse.enfants;
  ProgrammeChoix? _programme;
  final TextEditingController _nom = TextEditingController();
  bool _nomModifie = false;

  final List<CreneauClasse> _creneaux = <CreneauClasse>[];
  String? _enseignantId;
  String? _enseignantNom;
  AsyncValue<List<EnseignantEligible>> _eligibles =
      const AsyncValue<List<EnseignantEligible>>.loading();

  bool _reglesEditees = false;
  final TextEditingController _duree = TextEditingController();
  final TextEditingController _capacite = TextEditingController();
  final TextEditingController _seuil = TextEditingController();

  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _preremplirNom();
  }

  @override
  void dispose() {
    _nom.dispose();
    _duree.dispose();
    _capacite.dispose();
    _seuil.dispose();
    super.dispose();
  }

  /// Le nom propose : le programme et le public, tant que l'administration
  /// ne l'a pas repris a la main.
  void _preremplirNom() {
    if (_nomModifie) {
      return;
    }
    final String publicLisible = LibellesClasses.publicClasse(_public);
    _nom.text = _programme == null
        ? publicLisible
        : '${_programme!.nomHumain} · $publicLisible';
  }

  int? _entier(TextEditingController controleur) =>
      int.tryParse(controleur.text.trim());

  /// Le brouillon commun a tous les creneaux.
  BrouillonClasse _brouillon(CreneauClasse creneau) => BrouillonClasse(
    libelle: _nom.text.trim(),
    publicClasse: _public,
    creneau: creneau,
    dureeMinutes: _reglesEditees ? _entier(_duree) : null,
    capacite: _reglesEditees ? _entier(_capacite) : null,
    seuilMinimal: _reglesEditees ? _entier(_seuil) : null,
    enseignantId: _enseignantId,
    enseignantNom: _enseignantNom,
    niveauId: _programme?.niveauId,
    programme: _programme?.nomHumain,
    niveauHumain: _programme?.cycle,
  );

  List<BrouillonClasse> get _brouillons => <BrouillonClasse>[
    for (final CreneauClasse c in _creneaux) _brouillon(c),
  ];

  Future<void> _chargerEligibles() async {
    if (_creneaux.isEmpty) {
      return;
    }
    setState(
      () => _eligibles = const AsyncValue<List<EnseignantEligible>>.loading(),
    );
    try {
      final List<EnseignantEligible> liste = await ref
          .read(portClassesAdminProvider)
          .enseignantsEligibles(_brouillon(_creneaux.first));
      if (mounted) {
        setState(
          () => _eligibles = AsyncValue<List<EnseignantEligible>>.data(liste),
        );
      }
    } on Object catch (erreur, pile) {
      if (mounted) {
        setState(
          () => _eligibles = AsyncValue<List<EnseignantEligible>>.error(
            erreur,
            pile,
          ),
        );
      }
    }
  }

  void _basculerCreneau(Creneau creneau, {required bool posee}) {
    final CreneauClasse cible = CreneauClasse(
      jourIso: creneau.jour,
      heure: creneau.heure,
      fuseauIana: creneau.fuseau,
    );
    setState(() {
      if (posee) {
        _creneaux.remove(cible);
      } else if (widget.lot) {
        _creneaux.add(cible);
      } else {
        // Une seule Classe : une seule case. La nouvelle remplace l'ancienne,
        // sans demander de la retirer d'abord.
        _creneaux
          ..clear()
          ..add(cible);
      }
    });
    unawaited(_chargerEligibles());
  }

  Future<void> _publier() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final List<String> ids = await ref
          .read(portClassesAdminProvider)
          .publier(_brouillons);
      ref.invalidate(classesAdminProvider);
      if (mounted) {
        Navigator.of(context).pop(ids.length);
      }
    } on EchecPublicationPartielle catch (echec) {
      ref.invalidate(classesAdminProvider);
      if (mounted) {
        setState(
          () => _erreur = t.classes.admin.creation.echecPartiel(
            faites: echec.faites,
            total: echec.total,
            message: messageHumain(echec),
          ),
        );
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(
          () => _erreur = t.classes.admin.creation.echec(
            message: messageHumain(erreur),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  bool get _peutContinuer => switch (_etape) {
    0 => _nom.text.trim().isNotEmpty,
    1 => _creneaux.isNotEmpty,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ReglesClasse> regles = ref.watch(reglesClasseProvider);
    final String titre = widget.lot
        ? t.classes.admin.creation.titreLot
        : t.classes.admin.creation.titre;

    return PageShell(
      titre: titre,
      entete: _Etapes(courante: _etape),
      actions: regles.hasValue ? _actions(regles.requireValue) : null,
      child: switch (regles) {
        AsyncValue<ReglesClasse>(hasValue: true) => _corps(regles.requireValue),
        AsyncValue<ReglesClasse>(hasError: true) => EmptyState(
          message: t.classes.commun.erreurLecture,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => ref.invalidate(reglesClasseProvider),
        ),
        _ => const Skeleton.liste(lignes: 3),
      },
    );
  }

  Widget _corps(ReglesClasse regles) {
    final Widget etape = switch (_etape) {
      0 => _EtapeProgramme(
        publicClasse: _public,
        programme: _programme,
        nom: _nom,
        onPublic: (PublicClasse p) => setState(() {
          _public = p;
          _preremplirNom();
        }),
        onProgramme: (ProgrammeChoix? p) => setState(() {
          _programme = p;
          _preremplirNom();
        }),
        onNomModifie: () => setState(() => _nomModifie = true),
      ),
      1 => _EtapeCreneaux(
        lot: widget.lot,
        regles: regles,
        creneaux: _creneaux,
        publicClasse: _public,
        onBasculer: _basculerCreneau,
        eligibles: _eligibles,
        enseignantId: _enseignantId,
        onEnseignant: (EnseignantEligible? e) => setState(() {
          _enseignantId = e?.id;
          _enseignantNom = e?.nomAffichage;
        }),
        reglesEditees: _reglesEditees,
        onEditerRegles: () => setState(() {
          _reglesEditees = true;
          _duree.text = regles.dureeMinutes?.toString() ?? '';
          _capacite.text = regles.capacitePour(_public)?.toString() ?? '';
          _seuil.text = regles.seuilMinimal?.toString() ?? '';
        }),
        duree: _duree,
        capacite: _capacite,
        seuil: _seuil,
      ),
      _ => _EtapeApercu(
        brouillons: _brouillons,
        regles: regles,
        erreur: _erreur,
      ),
    };

    // [RESPONSIVE]
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final bool large = AppGabarit.pour(contraintes.maxWidth).estLarge;
        if (!large || _etape == 2) {
          return etape;
        }
        // Des la tablette : le pas courant a gauche, l'aperçu vivant a droite.
        // Le meme etat, deux compositions, jamais deux ecrans.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 3, child: etape),
            Ecart.hXxl,
            Expanded(
              flex: 2,
              child: _Resume(
                brouillons: _brouillons,
                regles: regles,
                publicClasse: _public,
                nom: _nom.text,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actions(ReglesClasse regles) {
    final bool derniere = _etape == 2;
    final int nombre = _creneaux.length;
    final String libellePublier = nombre > 1
        ? t.classes.admin.creation.publierLot(nombre: nombre)
        : t.classes.admin.creation.publier;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        // Jamais un bouton primaire etire sur 1400 points : la zone d'action
        // garde la largeur d'un formulaire, alignee a la fin.
        constraints: const BoxConstraints(maxWidth: AppPage.largeurFormulaire),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ActionPrincipale(
                libelle: _etape == 0
                    ? t.classes.admin.creation.annuler
                    : t.classes.admin.creation.precedent,
                niveau: NiveauAction.secondaire,
                onPress: _envoi
                    ? null
                    : () {
                        if (_etape == 0) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _etape -= 1);
                        }
                      },
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: ActionPrincipale(
                libelle: derniere
                    ? libellePublier
                    : t.classes.admin.creation.suivant,
                enCours: _envoi,
                onPress: !_peutContinuer
                    ? null
                    : derniere
                    ? () => unawaited(_publier())
                    : () => setState(() => _etape += 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les trois pas, nommes, et celui ou l'on est.
class _Etapes extends StatelessWidget {
  const _Etapes({required this.courante});

  final int courante;

  @override
  Widget build(BuildContext context) {
    final List<String> noms = <String>[
      t.classes.admin.creation.etapeProgramme,
      t.classes.admin.creation.etapeCreneau,
      t.classes.admin.creation.etapeApercu,
    ];
    return Semantics(
      label: t.inscription.etapeSur(n: courante + 1, total: noms.length),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: <Widget>[
          for (int i = 0; i < noms.length; i++)
            FilterPill(libelle: noms[i], retenue: i == courante, onPress: null),
        ],
      ),
    );
  }
}

/// Pas 1 : le public, le programme, le nom.
class _EtapeProgramme extends ConsumerWidget {
  const _EtapeProgramme({
    required this.publicClasse,
    required this.programme,
    required this.nom,
    required this.onPublic,
    required this.onProgramme,
    required this.onNomModifie,
  });

  final PublicClasse publicClasse;
  final ProgrammeChoix? programme;
  final TextEditingController nom;
  final void Function(PublicClasse publicClasse) onPublic;
  final void Function(ProgrammeChoix? programme) onProgramme;
  final VoidCallback onNomModifie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProgrammeChoix>> programmes = ref.watch(
      programmesClasseProvider,
    );
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.classes.admin.creation.publicQuestion,
          style: textes.titleMedium,
        ),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final PublicClasse p in PublicClasse.values)
              FilterPill(
                libelle: LibellesClasses.publicClasse(p),
                retenue: p == publicClasse,
                onPress: () => onPublic(p),
              ),
          ],
        ),
        Ecart.vXl,
        Text(
          t.classes.admin.creation.programmeQuestion,
          style: textes.titleMedium,
        ),
        Ecart.vSm,
        switch (programmes) {
          AsyncValue<List<ProgrammeChoix>>(hasValue: true) =>
            programmes.requireValue.isEmpty
                ? Text(
                    t.classes.admin.creation.programmeAucun,
                    style: textes.bodySmall,
                  )
                // Le meme selecteur que Diagnostics, Progression et
                // Evaluations : le nom humain seul, jamais le code.
                : SelecteurNiveauProgramme(
                    niveaux: <NiveauProgramme>[
                      for (final ProgrammeChoix p in programmes.requireValue)
                        NiveauProgramme(
                          id: p.niveauId,
                          codeTechnique: '',
                          nomHumain: p.nomHumain,
                          cycle: p.cycle,
                          ordre: 0,
                          description: null,
                        ),
                    ],
                    selectionne: programme?.niveauId,
                    onSelectionner: (String id) {
                      for (final ProgrammeChoix p in programmes.requireValue) {
                        if (p.niveauId == id) {
                          onProgramme(programme?.niveauId == id ? null : p);
                          return;
                        }
                      }
                    },
                  ),
          AsyncValue<List<ProgrammeChoix>>(hasError: true) => Text(
            t.classes.admin.creation.programmeAucun,
            style: textes.bodySmall,
          ),
          _ => const Skeleton.texte(lignes: 2),
        },
        Ecart.vXl,
        Text(t.classes.admin.creation.nomQuestion, style: textes.titleMedium),
        Ecart.vSm,
        TextField(
          key: CreationClassePage.cleNom,
          controller: nom,
          onChanged: (String _) => onNomModifie(),
          decoration: InputDecoration(
            labelText: t.admin.groupes.champLibelle,
            helperText: t.classes.admin.creation.nomAide,
          ),
        ),
      ],
    );
  }
}

/// Pas 2 : les creneaux, l'enseignant facultatif, les regles.
class _EtapeCreneaux extends StatelessWidget {
  const _EtapeCreneaux({
    required this.lot,
    required this.regles,
    required this.creneaux,
    required this.publicClasse,
    required this.onBasculer,
    required this.eligibles,
    required this.enseignantId,
    required this.onEnseignant,
    required this.reglesEditees,
    required this.onEditerRegles,
    required this.duree,
    required this.capacite,
    required this.seuil,
  });

  final bool lot;
  final ReglesClasse regles;
  final List<CreneauClasse> creneaux;
  final PublicClasse publicClasse;
  final void Function(Creneau creneau, {required bool posee}) onBasculer;
  final AsyncValue<List<EnseignantEligible>> eligibles;
  final String? enseignantId;
  final void Function(EnseignantEligible? enseignant) onEnseignant;
  final bool reglesEditees;
  final VoidCallback onEditerRegles;
  final TextEditingController duree;
  final TextEditingController capacite;
  final TextEditingController seuil;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.classes.admin.creation.creneauQuestion,
          style: textes.titleMedium,
        ),
        Ecart.vXs,
        Text(
          lot
              ? t.classes.admin.creation.creneauAideLot
              : t.classes.admin.creation.creneauAide,
          style: textes.bodySmall,
        ),
        Ecart.vMd,
        // La meme grille que `TUT-04` et `ENS-06` : une case, un jour et une
        // heure. Aucun chiffre de jour, aucune heure a taper.
        KeyedSubtree(
          key: CreationClassePage.cleGrille,
          child: GrilleSemaine(
            creneaux: <Creneau>[
              for (final CreneauClasse c in creneaux)
                Creneau(jour: c.jourIso, heure: c.heure, fuseau: c.fuseauIana),
            ],
            fuseau: regles.fuseauIana,
            onBasculer: (Creneau creneau, bool posee) =>
                onBasculer(creneau, posee: posee),
          ),
        ),
        Ecart.vSm,
        Text(
          creneaux.isEmpty
              ? t.classes.admin.creation.aucunCreneau
              : creneaux.length == 1
              ? t.classes.admin.creation.creneauChoisi
              : t.classes.admin.creation.creneauxChoisis(
                  nombre: creneaux.length,
                ),
          style: textes.bodySmall,
        ),
        Ecart.vXl,
        Text(
          t.classes.admin.creation.enseignantQuestion,
          style: textes.titleMedium,
        ),
        Ecart.vXs,
        Text(t.classes.admin.creation.enseignantAide, style: textes.bodySmall),
        Ecart.vMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            FilterPill(
              libelle: t.classes.admin.creation.enseignantAucun,
              retenue: enseignantId == null,
              onPress: () => onEnseignant(null),
            ),
            if (eligibles.hasValue)
              for (final EnseignantEligible e in eligibles.requireValue)
                FilterPill(
                  libelle: e.nomAffichage,
                  retenue: e.id == enseignantId,
                  onPress: () => onEnseignant(e),
                ),
          ],
        ),
        if (eligibles.hasValue && eligibles.requireValue.isEmpty) ...<Widget>[
          Ecart.vSm,
          Text(
            t.classes.admin.creation.enseignantAucunEligible,
            style: textes.bodySmall,
          ),
        ],
        Ecart.vXl,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                t.classes.admin.creation.reglesTitre,
                style: textes.titleMedium,
              ),
              Ecart.vXs,
              Text(
                t.classes.admin.creation.reglesAide,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              Ecart.vMd,
              if (!reglesEditees) ...<Widget>[
                _Regle(
                  libelle: t.classes.admin.creation.duree,
                  valeur: regles.dureeMinutes == null
                      ? t.classes.commun.defautAcademie
                      : LibellesClasses.duree(
                          Duration(minutes: regles.dureeMinutes!),
                        ),
                ),
                _Regle(
                  libelle: t.classes.admin.creation.capacite,
                  valeur:
                      regles.capacitePour(publicClasse)?.toString() ??
                      t.classes.commun.defautAcademie,
                ),
                _Regle(
                  libelle: t.classes.admin.creation.seuilMinimal,
                  valeur:
                      regles.seuilMinimal?.toString() ??
                      t.classes.commun.defautAcademie,
                ),
                Ecart.vSm,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionPrincipale(
                    libelle: t.classes.commun.modifier,
                    niveau: NiveauAction.tertiaire,
                    pleineLargeur: false,
                    onPress: onEditerRegles,
                  ),
                ),
              ] else ...<Widget>[
                _Champ(
                  controleur: duree,
                  libelle: t.classes.admin.creation.duree,
                ),
                Ecart.vMd,
                _Champ(
                  controleur: capacite,
                  libelle: t.classes.admin.creation.capacite,
                ),
                Ecart.vMd,
                _Champ(
                  controleur: seuil,
                  libelle: t.classes.admin.creation.seuilMinimal,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une regle preremplie, en lecture.
class _Regle extends StatelessWidget {
  const _Regle({required this.libelle, required this.valeur});

  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              libelle,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          Text(valeur, style: textes.bodyMedium),
        ],
      ),
    );
  }
}

/// Un champ numerique, quand la Classe fait exception a la regle.
class _Champ extends StatelessWidget {
  const _Champ({required this.controleur, required this.libelle});

  final TextEditingController controleur;
  final String libelle;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controleur,
    keyboardType: TextInputType.number,
    inputFormatters: <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
    ],
    decoration: InputDecoration(
      labelText: libelle,
      helperText: t.classes.commun.defautAcademie,
    ),
  );
}

/// Pas 3 : ce qui sera publie, carte par carte.
class _EtapeApercu extends StatelessWidget {
  const _EtapeApercu({
    required this.brouillons,
    required this.regles,
    required this.erreur,
  });

  final List<BrouillonClasse> brouillons;
  final ReglesClasse regles;
  final String? erreur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.classes.admin.creation.apercuTitre, style: textes.titleMedium),
        Ecart.vXs,
        Text(
          brouillons.length == 1
              ? t.classes.admin.creation.apercuUne
              : t.classes.admin.creation.apercuNombre(
                  nombre: brouillons.length,
                ),
          style: textes.bodySmall,
        ),
        if (erreur != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              erreur!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vLg,
        GrilleClasses(
          cartes: <Widget>[
            for (final BrouillonClasse b in brouillons)
              CarteClasse(
                classe: b.apercu(
                  capaciteAcademie: regles.capacitePour(b.publicClasse),
                ),
                detailOuvert: true,
              ),
          ],
        ),
      ],
    );
  }
}

/// L'aperçu vivant, a cote du pas courant sur les grandes largeurs.
class _Resume extends StatelessWidget {
  const _Resume({
    required this.brouillons,
    required this.regles,
    required this.publicClasse,
    required this.nom,
  });

  final List<BrouillonClasse> brouillons;
  final ReglesClasse regles;
  final PublicClasse publicClasse;
  final String nom;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    if (brouillons.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              nom.trim().isEmpty
                  ? LibellesClasses.publicClasse(publicClasse)
                  : nom,
              style: textes.titleMedium,
            ),
            Ecart.vSm,
            Text(
              t.classes.admin.creation.aucunCreneau,
              style: textes.bodySmall,
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.classes.admin.creation.apercuTitre, style: textes.titleMedium),
        Ecart.vMd,
        for (final BrouillonClasse b in brouillons.take(3)) ...<Widget>[
          CarteClasse(
            classe: b.apercu(
              capaciteAcademie: regles.capacitePour(b.publicClasse),
            ),
          ),
          Ecart.vMd,
        ],
        if (brouillons.length > 3)
          Text(
            t.classes.admin.creation.apercuNombre(nombre: brouillons.length),
            style: textes.bodySmall,
          ),
      ],
    );
  }
}

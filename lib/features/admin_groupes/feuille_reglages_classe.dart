// Classe a plusieurs creneaux et mixite (decisions D1 et D2 du directeur,
// 29/10/2026 ; fiche docs/current/FICHE-CRENEAUX-2026-10-29.md, arbitree par
// le pilote) : « Creneaux et genre » d'une Classe.
//
// La direction voit les creneaux de la semaine, en modifie ou en retire un
// (les seances a venir de ce creneau sont annulees avec le motif, jamais
// supprimees ; familles et enseignant prevenus par le serveur), en ajoute un
// (la feuille existante), et regle le genre : hommes, femmes ou mixte. Le
// serveur decide de tout ; l'ecran dit ses refus en une phrase.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/creneaux_classe.dart';
import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/affectation_refusee.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/skeleton.dart';
import '../creneaux/plages.dart' show jourCapitalise;
import 'bas_de_feuille.dart';
import 'duree_creneau.dart';
import 'feuille_creneau.dart';
import 'genre_classe_libelles.dart';
import 'refus_deplacement_libelles.dart';

/// La plage d'heures proposee, celle de la creation d'une Classe (6 h - 21 h).
const int _heureDebut = 6;
const int _heureFin = 21;

/// Ouvre « Creneaux et genre » pour [groupe] ; [genre] est celui que la
/// liste des classes a lu.
void ouvrirReglagesClasse(
  BuildContext context,
  WidgetRef ref,
  GroupeAdmin groupe, {
  String? nom,
  GenreClasse? genre,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.reglagesClasse.titre(
      deLibelle: deDevant(nom ?? groupe.libelle),
    ),
    constructeur: (BuildContext contexte) => FeuilleReglagesClasse(
      groupe: groupe,
      genre: genre,
      onAjouterCreneau: () {
        Navigator.of(contexte).pop();
        ouvrirAjoutCreneau(context, ref, groupe, nom: nom);
      },
      onChange: () => ref
        ..invalidate(creneauxClasseProvider(groupe.id))
        ..invalidate(groupesProvider)
        ..invalidate(pageClassesAdminProvider),
    ),
  );
}

/// Le libelle d'un creneau : « Mardi 18 h », insecable, suivi de sa duree
/// quand elle n'est pas celle de la classe (« Mardi 18 h, 45 min »).
String libelleCreneauClasse(CreneauClasse c) {
  final String jourHeure = LibellesGroupe.insecable(
    '${jourCapitalise(c.jour)} '
    '${t.admin.groupes.formulaire.heureValeur(heure: '${c.heure}')}',
  );
  final int? duree = c.duree;
  return duree == null
      ? jourHeure
      : '$jourHeure, ${libelleDureeCreneau(duree)}';
}

enum _Vue { liste, modifier, retirer, genre }

/// La feuille « Creneaux et genre ».
class FeuilleReglagesClasse extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleReglagesClasse({
    required this.groupe,
    required this.onAjouterCreneau,
    required this.onChange,
    super.key,
    this.genre,
  });

  /// La Classe.
  final GroupeAdmin groupe;

  /// Le genre lu par la liste des classes.
  final GenreClasse? genre;

  /// Ouvre la feuille « Ajouter un creneau ».
  final VoidCallback onAjouterCreneau;

  /// Appele apres un changement accepte par le serveur.
  final VoidCallback onChange;

  @override
  ConsumerState<FeuilleReglagesClasse> createState() =>
      _FeuilleReglagesClasseEtat();
}

class _FeuilleReglagesClasseEtat extends ConsumerState<FeuilleReglagesClasse> {
  _Vue _vue = _Vue.liste;
  CreneauClasse? _cible;
  int? _jour;
  int? _heure;

  /// La duree du creneau modifie, en minutes ; nulle pour celle de la classe.
  int? _duree;
  GenreClasse? _genreChoisi;
  late GenreClasse? _genreActuel = widget.genre;
  final TextEditingController _motif = TextEditingController();
  bool _envoi = false;
  String? _erreur;
  String? _fait;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _ouvrir(_Vue vue, {CreneauClasse? cible}) => setState(() {
    _vue = vue;
    _cible = cible;
    _jour = cible?.jour;
    _heure = cible?.heure;
    _duree = cible?.duree;
    _genreChoisi = null;
    _motif.clear();
    _erreur = null;
    _fait = null;
  });

  String _phraseRefus(MotifRefusCreneau motif) {
    final r = t.admin.groupes.reglagesClasse;
    return switch (motif) {
      MotifRefusCreneau.dernier => r.refusDernier,
      MotifRefusCreneau.existant => r.refusExistant,
      MotifRefusCreneau.introuvable => r.refusIntrouvable,
      MotifRefusCreneau.classeFermee => r.refusClasseFermee,
    };
  }

  Future<void> _envoyer() async {
    final r = t.admin.groupes.reglagesClasse;
    final String motif = _motif.text.trim();
    final CreneauClasse? cible = _cible;
    final int? jour = _jour;
    final int? heure = _heure;
    final GenreClasse? genre = _genreChoisi;
    final String? manque = switch (_vue) {
      _Vue.modifier when jour == null || heure == null =>
        t.admin.groupes.formulaire.manqueCreneau,
      _Vue.genre when genre == null => r.manqueGenre,
      _ when motif.isEmpty => r.manqueMotif,
      _ => null,
    };
    if (manque != null) {
      setState(() => _erreur = manque);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final ServiceCreneauxClasse service = ref.read(
      serviceCreneauxClasseProvider,
    );
    try {
      final String fait;
      switch (_vue) {
        case _Vue.modifier:
          final int n = await service.modifier(
            groupeId: widget.groupe.id,
            ancien: cible!,
            nouveau: (jour: jour!, heure: heure!, duree: _duree),
            motif: motif,
          );
          // La duree seule : les seances a venir sont realignees, aucune
          // n'est annulee ni creee.
          fait = jour == cible.jour && heure == cible.heure
              ? r.faitDuree(n: n)
              : r.faitModifie(n: n);
        case _Vue.retirer:
          final int n = await service.retirer(
            groupeId: widget.groupe.id,
            creneau: cible!,
            motif: motif,
          );
          fait = r.faitRetire(n: n);
        case _Vue.genre:
          await service.reglerGenre(
            groupeId: widget.groupe.id,
            genre: genre!,
            motif: motif,
          );
          _genreActuel = genre;
          fait = r.faitGenre;
        case _Vue.liste:
          return;
      }
      widget.onChange();
      if (mounted) {
        _ouvrir(_Vue.liste);
        setState(() => _fait = fait);
      }
    } on CreneauRefuse catch (refus) {
      if (mounted) setState(() => _erreur = _phraseRefus(refus.motif));
    } on AffectationRefusee catch (refus) {
      if (mounted) {
        setState(
          () => _erreur = phraseRefusDeplacement(
            refus.motif,
            actives: refus.actives,
            maximum: refus.maximum,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _erreur = r.erreur);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) => switch (_vue) {
    _Vue.liste => _liste(context),
    _Vue.modifier || _Vue.retirer || _Vue.genre => _geste(context),
  };

  Widget _liste(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.groupes.reglagesClasse;
    final AsyncValue<List<CreneauClasse>> lecture = ref.watch(
      creneauxClasseProvider(widget.groupe.id),
    );
    final GenreClasse? genre = _genreActuel;
    final bool nonRegle = genre == null || genre == GenreClasse.indetermine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_fait case final String fait) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(fait, style: textes.bodyMedium),
          ),
          Ecart.vLg,
        ],
        TexteSansCoupure(r.creneauxContexte, style: textes.bodyMedium),
        Ecart.vLg,
        if (lecture.hasValue)
          GroupeReglages(
            titre: r.creneauxTitre,
            lignes: <LigneRubrique>[
              for (final CreneauClasse c in lecture.requireValue)
                LigneRubrique(
                  libelle: libelleCreneauClasse(c),
                  controle: MenuActions(
                    objet: libelleCreneauClasse(c),
                    actions: <EntreeAction>[
                      EntreeAction(
                        libelle: r.modifierCreneau,
                        onChoix: () => _ouvrir(_Vue.modifier, cible: c),
                      ),
                      EntreeAction(
                        libelle: r.retirerCreneau,
                        destructif: true,
                        onChoix: () => _ouvrir(_Vue.retirer, cible: c),
                      ),
                    ],
                  ),
                ),
            ],
          )
        else if (lecture.hasError)
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            phrase: r.lectureErreur,
            libelleAction: t.commun.etats.actions.reessayer,
            onAction: () =>
                ref.invalidate(creneauxClasseProvider(widget.groupe.id)),
          )
        else
          const Skeleton.liste(lignes: 3),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: const ValueKey<String>('reglages-ajouter-creneau'),
            libelle: r.ajouterCreneau,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: widget.onAjouterCreneau,
          ),
        ),
        Ecart.vXl,
        GroupeReglages(
          titre: r.genreTitre,
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: nonRegle
                  ? r.genreNonRegle
                  : libelleGenreClasse(genre, widget.groupe.type),
              legende: nonRegle ? r.genreNonRegleDetail : null,
              controle: ActionPrincipale(
                key: const ValueKey<String>('reglages-modifier-genre'),
                libelle: r.modifierGenre,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () => _ouvrir(_Vue.genre),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _geste(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.groupes.reglagesClasse;
    final f = t.admin.groupes.formulaire;
    final CreneauClasse? cible = _cible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (cible != null) ...<Widget>[
          TexteSansCoupure(
            libelleCreneauClasse(cible),
            style: textes.titleMedium,
          ),
          Ecart.vSm,
        ],
        if (_vue != _Vue.genre) ...<Widget>[
          TexteSansCoupure(r.consequence, style: textes.bodyMedium),
          Ecart.vLg,
        ],
        if (_vue == _Vue.modifier) ...<Widget>[
          TexteSansCoupure(f.jour, style: textes.labelLarge),
          Ecart.vSm,
          // Choix de formulaire, pas un filtre : le nouveau jour du creneau.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (int j = 1; j <= 7; j++)
                FilterPill(
                  key: ValueKey<String>('reglages-jour-$j'),
                  libelle: jourCapitalise(j),
                  retenue: _jour == j,
                  onPress: () => setState(() {
                    _jour = j;
                    _erreur = null;
                  }),
                ),
            ],
          ),
          Ecart.vLg,
          TexteSansCoupure(f.heure, style: textes.labelLarge),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MenuFiltre<int>(
              key: const ValueKey<String>('reglages-heure'),
              libelle: f.heure,
              valeur: _heure,
              entrees: <EntreeFiltre<int>>[
                for (int h = _heureDebut; h <= _heureFin; h++)
                  EntreeFiltre<int>(
                    valeur: h,
                    libelle: LibellesGroupe.insecable(
                      f.heureValeur(heure: '$h'),
                    ),
                  ),
              ],
              onChoix: (int? h) {
                if (h != null) {
                  setState(() {
                    _heure = h;
                    _erreur = null;
                  });
                }
              },
            ),
          ),
          Ecart.vLg,
          TexteSansCoupure(f.duree, style: textes.labelLarge),
          Ecart.vXs,
          TexteSansCoupure(r.dureeContexte, style: textes.bodySmall),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MenuDureeCreneau(
              key: const ValueKey<String>('reglages-duree'),
              duree: _duree,
              onChoix: (int? d) => setState(() {
                _duree = d;
                _erreur = null;
              }),
            ),
          ),
          Ecart.vLg,
        ],
        if (_vue == _Vue.genre) ...<Widget>[
          TexteSansCoupure(r.genreContexte, style: textes.bodyMedium),
          Ecart.vLg,
          ChoiceCardGroup(
            key: const ValueKey<String>('reglages-genre'),
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final GenreClasse g in <GenreClasse>[
                GenreClasse.hommes,
                GenreClasse.femmes,
                GenreClasse.mixte,
              ])
                OptionChoix(
                  cle: ValueKey<String>('reglages-genre-${g.name}'),
                  valeur: g.name,
                  libelle: libelleGenreClasse(g, widget.groupe.type),
                  description: detailGenreClasse(
                    g,
                    widget.groupe.type,
                    genreConnu: true,
                  ),
                ),
            ],
            onChange: (ReponseChoix reponse) => setState(() {
              _genreChoisi = GenreClasse.values
                  .where((GenreClasse g) => reponse.valeurs.contains(g.name))
                  .firstOrNull;
              _erreur = null;
            }),
          ),
          Ecart.vLg,
        ],
        TextField(
          key: const ValueKey<String>('reglages-motif'),
          controller: _motif,
          onChanged: (String _) => setState(() => _erreur = null),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: r.motif,
            helperText: r.motifAide,
          ),
        ),
        if (_erreur case final String erreur) ...<Widget>[
          Ecart.vMd,
          MessageAlerte(erreur),
        ],
        Ecart.vXxl,
        BasDeFeuille(
          libelle: switch (_vue) {
            _Vue.modifier => r.envoyerModifier,
            _Vue.retirer => r.envoyerRetirer,
            _Vue.genre || _Vue.liste => r.envoyerGenre,
          },
          enCours: _envoi,
          horsLigne: r.horsLigne,
          onPress: _envoyer,
        ),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: const ValueKey<String>('reglages-retour'),
            libelle: r.retour,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () {
              if (!_envoi) _ouvrir(_Vue.liste);
            },
          ),
        ),
      ],
    );
  }
}

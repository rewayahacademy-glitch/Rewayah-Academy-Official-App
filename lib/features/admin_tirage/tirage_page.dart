/// ECHELLE-CTRL-DIRECT-1 : « Tirage des contrôles », cote direction.
///
/// R18 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`, conforme a BR-CT-03) :
/// **le controleur ne choisit jamais sa classe**. Le serveur tire au sort une
/// mission parmi les seances en direct, selon les regles de la direction :
/// ponderation, classes ou enseignants a cibler, frequence. Cet ecran est
/// celui de la direction : les regles du tirage (qu'elle peut modifier si le
/// serveur lui en donne la capacite) et l'historique audite des tirages et
/// des missions non controlees (BR-CT-15), pagine et filtrable.
///
/// Il est **reserve a la direction** : la capacite `peutLire` du port decide,
/// jamais un role. Sans elle, une phrase dit pourquoi et quoi faire (K-59).
/// Le controleur ne voit jamais cet ecran : il ne voit que sa propre mission.
///
/// Etats : chargement (`Skeleton`), contenu, vide (`EmptyState`), erreur
/// (`EtatSysteme`, « Reessayer »), hors ligne (le bandeau de `PageShell` ;
/// `EtatSansDonnees` seulement si rien n'a pu etre lu), port absent
/// (« disponible au branchement serveur »), acces refuse.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart' show ongletsSecurite;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/controle/port_tirage_controle.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_groupes/bas_de_feuille.dart';
import '../admin_regroupements/feuille_classe_regroupement.dart'
    show nouvelleCleEnvoi;
import 'tirage_libelles.dart';

/// L'ecran « Tirage des controles ».
class TiragePage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const TiragePage({super.key});

  @override
  ConsumerState<TiragePage> createState() => _TiragePageEtat();
}

class _TiragePageEtat extends ConsumerState<TiragePage> {
  FiltreTirages _filtre = const FiltreTirages();
  int _page = 1;

  /// La derniere page lue : ses compteurs restent affiches pendant qu'une
  /// autre page se charge.
  PageTirages? _derniere;

  final TextEditingController _recherche = TextEditingController();

  /// L'attente qui suit la derniere frappe (anti-rebond). Ce n'est pas un
  /// mouvement (aucune animation), donc pas un jeton d'`AppMouvement`.
  Timer? _attenteSaisie;

  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  void _chercher(String texte) {
    _attenteSaisie?.cancel();
    _attenteSaisie = Timer(_delaiSaisie, () {
      if (mounted) _filtrer(_filtre.avec(texte: texte));
    });
  }

  void _filtrer(FiltreTirages filtre) => setState(() {
    _filtre = filtre;
    _page = 1;
  });

  void _relire() => ref
    ..invalidate(accesTirageProvider)
    ..invalidate(reglesTirageProvider)
    ..invalidate(pageTiragesProvider);

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  Widget _echec(Object erreur, VoidCallback? reessayer, bool horsLigne) {
    final r = t.admin.tirage;
    // Port absent : ni un echec, ni un vide. Rien ne se reessaie.
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        key: const ValueKey<String>('tirage-indisponible'),
        nature: NatureEtat.indisponible,
        titre: r.indisponibleTitre,
        phrase: r.indisponiblePhrase,
        dependance: erreur.dependance,
      );
    }
    return horsLigne
        ? EtatSansDonnees(
            key: const ValueKey<String>('tirage-sans-donnees'),
            quoi: r.sansDonnees,
            onAction: reessayer,
          )
        : EtatSysteme(
            key: const ValueKey<String>('tirage-erreur'),
            nature: NatureEtat.echecServeur,
            phrase: r.erreur,
            onAction: reessayer,
          );
  }

  @override
  Widget build(BuildContext context) {
    final r = t.admin.tirage;
    final AsyncValue<AccesTirage> acces = ref.watch(accesTirageProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return PageShell(
      titre: r.titre,
      sousTitre: r.sousTitre,
      // Securite et audit : onglet pair du Journal et des observations.
      entete: SousNavigationDomaine(onglets: ongletsSecurite(), indexActif: 2),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: BlocAsynchrone<AccesTirage>(
            key: const ValueKey<String>('tirage-acces'),
            valeur: acces,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: _relire,
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                _echec(erreur, reessayer, horsLigne),
            construire: (AccesTirage a) {
              // La capacite decide, jamais un role : sans elle, ni les
              // regles ni l'historique ne sont lus.
              if (!a.peutLire) {
                return EtatSysteme(
                  key: const ValueKey<String>('tirage-reserve'),
                  nature: NatureEtat.accesRefuse,
                  titre: r.reserveTitre,
                  phrase: r.reservePhrase,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Regles(peutModifier: a.peutModifier),
                  Ecart.vXxl,
                  _Historique(
                    filtre: _filtre,
                    page: _page,
                    derniere: _derniere,
                    recherche: _recherche,
                    onChercher: _chercher,
                    onFiltre: _filtrer,
                    onPage: (int n) => setState(() => _page = n),
                    onLue: (PageTirages p) => _derniere = p,
                    echec: (Object e, VoidCallback? re) =>
                        _echec(e, re, horsLigne),
                    onRelire: _relire,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Les regles du tirage : frequence, ponderation, cibles, et leur
/// enregistrement.
class _Regles extends ConsumerStatefulWidget {
  const _Regles({required this.peutModifier});

  final bool peutModifier;

  @override
  ConsumerState<_Regles> createState() => _ReglesEtat();
}

class _ReglesEtat extends ConsumerState<_Regles> {
  /// Les regles en cours d'edition ; nul tant que la lecture n'a pas abouti.
  ReglesTirage? _brouillon;

  /// Change a chaque (re)lecture des regles : remet les cartes de choix a
  /// zero sur les valeurs lues.
  int _version = 0;

  /// Une seule cle par serie de modifications : une pression apres une
  /// reponse perdue reprend le meme enregistrement cote serveur.
  String _cle = nouvelleCleEnvoi();

  bool _envoi = false;
  String? _message;
  bool _enregistre = false;

  /// La version creee par le dernier enregistrement (0 : non rendue).
  int _versionEnregistree = 0;

  /// Vrai quand la carte « Autre » porte un texte qui n'est pas un entier de
  /// 0 a 50 : rien ne part, l'ecran le dit (jamais un bouton grise).
  bool _nombreInvalide = false;

  /// Vrai quand l'utilisateur a ouvert « Autre ». La case reste ouverte tant
  /// qu'il ne touche pas une frequence proposee.
  bool _autreOuvert = false;

  /// Compte les ouvertures de « Autre » : le champ repart de la valeur en
  /// vigueur a chaque ouverture (sa cle en depend).
  int _ouvertureAutre = 0;

  /// « Autre » est retenu : ouvert par l'utilisateur, ou valeur lue qui n'est
  /// pas une des frequences proposees (elle s'affiche alors dans le champ).
  bool _autreRetenu(ReglesTirage regles) =>
      _autreOuvert || !frequencesProposees.contains(regles.missionsParSemaine);

  void _ouvrirAutre() {
    if (_autreOuvert) return;
    setState(() {
      _autreOuvert = true;
      _ouvertureAutre++;
    });
  }

  void _choisirNombre(ReglesTirage regles, int n) {
    setState(() => _autreOuvert = false);
    _choisirFrequence(regles, ReponseChoix(valeurs: <String>{'$n'}));
  }

  void _modifier(ReglesTirage regles) => setState(() {
    _brouillon = regles;
    _message = null;
    _enregistre = false;
    _nombreInvalide = false;
  });

  /// Les cartes de frequence : un nombre propose, ou « Autre » (0 a 50).
  void _choisirFrequence(ReglesTirage regles, ReponseChoix reponse) {
    if (reponse.valeurs.contains(ChoiceCardGroup.valeurAutre)) {
      final int? n = lireMissions(reponse.saisieLibre);
      if (n == null) {
        setState(() {
          _nombreInvalide = true;
          _message = null;
          _enregistre = false;
        });
      } else {
        _modifier(regles.avec(missionsParSemaine: n));
      }
      return;
    }
    final int? n = int.tryParse(reponse.valeurs.firstOrNull ?? '');
    if (n != null) _modifier(regles.avec(missionsParSemaine: n));
  }

  Future<void> _enregistrer() async {
    final ReglesTirage? regles = _brouillon;
    if (_envoi || regles == null) return;
    if (_nombreInvalide) {
      setState(() => _message = t.admin.tirage.nombreInvalide);
      return;
    }
    final PortTirageControle? port = ref.read(portTirageControleProvider);
    if (port == null) return;
    setState(() {
      _envoi = true;
      _message = null;
    });
    ResultatRegles? resultat;
    try {
      resultat = await port.enregistrer(regles, cleEnvoi: _cle);
    } on Object {
      // Sans reponse, rien n'est suppose (D5) : « non confirme ».
      resultat = null;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case null:
          _message = t.admin.tirage.nonConfirmees;
        case ReglesRefusees(:final String motif):
          _message = t.admin.tirage.refusees(motif: motif);
        case ReglesEnregistrees(:final int version):
          _enregistre = true;
          _versionEnregistree = version;
          // La serie est close : la prochaine modification repart d'une cle
          // neuve.
          _cle = nouvelleCleEnvoi();
      }
    });
    if (resultat is ReglesEnregistrees) ref.invalidate(reglesTirageProvider);
  }

  Future<void> _ajouterCible() async {
    final ReglesTirage? regles = _brouillon;
    if (regles == null) return;
    final CibleTirage? choisie = await AppBottomSheet.ouvrir<CibleTirage>(
      context,
      titre: t.admin.tirage.ajouterTitre,
      constructeur: (BuildContext _) => _FeuilleCible(deja: regles.cibles),
    );
    if (choisie == null || !mounted) return;
    _modifier(regles.avec(cibles: <CibleTirage>[...regles.cibles, choisie]));
  }

  @override
  Widget build(BuildContext context) {
    final r = t.admin.tirage;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<ReglesTirage> lecture = ref.watch(reglesTirageProvider);
    // Les regles lues deviennent le brouillon, une fois par lecture.
    ref.listen<AsyncValue<ReglesTirage>>(reglesTirageProvider, (
      AsyncValue<ReglesTirage>? _,
      AsyncValue<ReglesTirage> suivante,
    ) {
      if (suivante.hasValue && !_envoi) {
        setState(() {
          _brouillon = suivante.requireValue;
          _version++;
          _autreOuvert = false;
        });
      }
    });
    if (lecture.hasValue && _brouillon == null) {
      _brouillon = lecture.requireValue;
    }
    final ReglesTirage? regles = _brouillon;

    return Column(
      key: const ValueKey<String>('tirage-regles'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: r.reglesTitre),
        Ecart.vXs,
        TexteSansCoupure(r.reglesIntro, style: textes.bodySmall),
        Ecart.vMd,
        if (regles != null) ...<Widget>[
          TexteSansCoupure(
            regles.version == 0
                ? r.aucuneVersion
                : r.versionEnVigueur(n: regles.version),
            key: const ValueKey<String>('tirage-version'),
            style: textes.titleSmall,
          ),
          Ecart.vMd,
        ],
        if (regles == null)
          BlocAsynchrone<ReglesTirage>(
            valeur: lecture,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: () => ref.invalidate(reglesTirageProvider),
            erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('tirage-regles-sans-donnees'),
                    quoi: r.sansDonnees,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('tirage-regles-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: r.erreur,
                    onAction: reessayer,
                  ),
            construire: (ReglesTirage _) => const SizedBox.shrink(),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(r.frequenceTitre, style: textes.titleMedium),
                Ecart.vXs,
                TexteSansCoupure(r.frequenceDetail, style: textes.bodySmall),
                Ecart.vMd,
                RangeeFiltres(
                  // Choix ferme de formulaire : chaque valeur reste visible.
                  replier: false,
                  key: ValueKey<String>('tirage-frequence-$_version'),
                  filtres: <Widget>[
                    for (final int n in frequencesProposees)
                      _PuceFrequence(
                        key: ValueKey<String>('tirage-frequence-$n'),
                        libelle: '$n',
                        phrase: r.missionsParSemaine(n: n),
                        retenue:
                            !_autreRetenu(regles) &&
                            regles.missionsParSemaine == n,
                        onPress: () => _choisirNombre(regles, n),
                      ),
                    _PuceFrequence(
                      key: const ValueKey<String>('tirage-frequence-autre'),
                      libelle: t.choix.autre,
                      phrase: t.choix.autre,
                      retenue: _autreRetenu(regles),
                      onPress: _ouvrirAutre,
                    ),
                  ],
                ),
                if (_autreRetenu(regles)) ...<Widget>[
                  Ecart.vSm,
                  TextFormField(
                    key: ValueKey<String>(
                      'tirage-autre-$_version-$_ouvertureAutre',
                    ),
                    initialValue: '${regles.missionsParSemaine}',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]'),
                      ),
                    ],
                    onChanged: (String texte) => _choisirFrequence(
                      regles,
                      ReponseChoix(
                        valeurs: const <String>{ChoiceCardGroup.valeurAutre},
                        saisieLibre: texte,
                      ),
                    ),
                    decoration: InputDecoration(
                      labelText: r.frequenceAutreChamp,
                    ),
                  ),
                ],
                if (_nombreInvalide) ...<Widget>[
                  Ecart.vSm,
                  TexteSansCoupure(
                    r.nombreInvalide,
                    key: const ValueKey<String>('tirage-nombre-invalide'),
                    style: textes.bodyMedium,
                  ),
                ] else if (regles.missionsParSemaine == 0) ...<Widget>[
                  Ecart.vSm,
                  TexteSansCoupure(
                    r.zeroPhrase,
                    key: const ValueKey<String>('tirage-zero'),
                    style: textes.bodyMedium,
                  ),
                ],
                Ecart.vXl,
                Text(r.ponderationTitre, style: textes.titleMedium),
                Ecart.vXs,
                TexteSansCoupure(r.ponderationDetail, style: textes.bodySmall),
                for (final CriterePonderation c
                    in CriterePonderation.values) ...<Widget>[
                  Ecart.vLg,
                  Text(libelleCritere(c), style: textes.titleSmall),
                  Ecart.vSm,
                  ChoiceCardGroup(
                    key: ValueKey<String>('tirage-poids-${c.name}-$_version'),
                    autoriserSaisieLibre: false,
                    valeurInitiale: ReponseChoix(
                      valeurs: <String>{regles.poids(c).name},
                    ),
                    options: <OptionChoix>[
                      for (final NiveauPonderation n
                          in NiveauPonderation.values)
                        OptionChoix(
                          cle: ValueKey<String>(
                            'tirage-poids-${c.name}-${n.name}',
                          ),
                          valeur: n.name,
                          libelle: libelleNiveau(n),
                        ),
                    ],
                    onChange: (ReponseChoix reponse) {
                      final NiveauPonderation? n = NiveauPonderation.values
                          .where(
                            (NiveauPonderation x) =>
                                reponse.valeurs.contains(x.name),
                          )
                          .firstOrNull;
                      if (n != null) {
                        _modifier(
                          regles.avec(
                            ponderations:
                                <CriterePonderation, NiveauPonderation>{
                                  ...regles.ponderations,
                                  c: n,
                                },
                          ),
                        );
                      }
                    },
                  ),
                ],
                Ecart.vXl,
                Text(r.ciblesTitre, style: textes.titleMedium),
                Ecart.vXs,
                TexteSansCoupure(r.ciblesDetail, style: textes.bodySmall),
                Ecart.vMd,
                if (regles.cibles.isEmpty)
                  TexteSansCoupure(
                    r.aucuneCible,
                    key: const ValueKey<String>('tirage-aucune-cible'),
                    style: textes.bodyMedium,
                  )
                else
                  for (final CibleTirage c in regles.cibles) ...<Widget>[
                    _LigneCible(
                      cible: c,
                      onRetirer: widget.peutModifier
                          ? () => _modifier(
                              regles.avec(
                                cibles: <CibleTirage>[
                                  for (final CibleTirage x in regles.cibles)
                                    if (x != c) x,
                                ],
                              ),
                            )
                          : null,
                    ),
                    Ecart.vSm,
                  ],
                if (widget.peutModifier) ...<Widget>[
                  Ecart.vSm,
                  LienFleche(
                    key: const ValueKey<String>('tirage-ajouter-cible'),
                    libelle: r.ajouterCible,
                    alignerEnDebut: true,
                    onPress: () => unawaited(_ajouterCible()),
                  ),
                ],
                if (_message case final String message) ...<Widget>[
                  Ecart.vMd,
                  MessageAlerte(
                    message,
                    key: const ValueKey<String>('tirage-message'),
                  ),
                ],
                if (_enregistre) ...<Widget>[
                  Ecart.vMd,
                  Semantics(
                    liveRegion: true,
                    child: TexteSansCoupure(
                      _versionEnregistree > 0
                          ? r.enregistreesVersion(n: _versionEnregistree)
                          : r.enregistrees,
                      key: const ValueKey<String>('tirage-enregistrees'),
                      style: textes.titleSmall,
                    ),
                  ),
                ],
                Ecart.vXl,
                // Capacite lue du port : sans elle, une phrase explique la
                // limite, et aucun bouton n'est rendu (jamais grise).
                if (widget.peutModifier)
                  BasDeFeuille(
                    key: const ValueKey<String>('tirage-enregistrer'),
                    libelle: r.enregistrer,
                    enCours: _envoi,
                    horsLigne: r.horsLigne,
                    onPress: () => unawaited(_enregistrer()),
                  )
                else
                  TexteSansCoupure(
                    r.lectureSeule,
                    key: const ValueKey<String>('tirage-lecture-seule'),
                    style: textes.bodyMedium,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Une cible, avec son type et, si la direction peut modifier, de quoi la
/// retirer.
/// Une puce de frequence : une [FilterPill] dont la phrase complete (« 2
/// missions par semaine ») est lue par le lecteur d'ecran (K-58). Elle dit si
/// elle est retenue, pour que [RangeeFiltres] la voie.
class _PuceFrequence extends StatelessWidget implements PuceFiltre {
  const _PuceFrequence({
    required this.libelle,
    required this.phrase,
    required this.retenue,
    required this.onPress,
    super.key,
  });

  final String libelle;
  final String phrase;

  @override
  final bool retenue;

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) => Semantics(
    label: phrase,
    child: FilterPill(libelle: libelle, retenue: retenue, onPress: onPress),
  );
}

class _LigneCible extends StatelessWidget {
  const _LigneCible({required this.cible, required this.onRetirer});

  final CibleTirage cible;
  final VoidCallback? onRetirer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      key: ValueKey<String>('tirage-cible-${cible.type.name}-${cible.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TexteSansCoupure(cible.libelle, style: textes.titleSmall),
            ),
            Ecart.hSm,
            StatusPill(
              libelle: libelleTypeCible(cible.type),
              ton: TonEtat.neutre,
            ),
          ],
        ),
        if (onRetirer != null) ...<Widget>[
          Ecart.vXs,
          LienFleche(
            key: ValueKey<String>(
              'tirage-retirer-${cible.type.name}-${cible.id}',
            ),
            libelle: t.admin.tirage.retirerCible(libelle: cible.libelle),
            alignerEnDebut: true,
            fleche: false,
            onPress: onRetirer!,
          ),
        ],
      ],
    );
  }
}

/// La feuille d'ajout d'une cible : choisir une classe ou un enseignant
/// parmi ceux que le serveur propose.
class _FeuilleCible extends ConsumerStatefulWidget {
  const _FeuilleCible({required this.deja});

  final List<CibleTirage> deja;

  @override
  ConsumerState<_FeuilleCible> createState() => _FeuilleCibleEtat();
}

class _FeuilleCibleEtat extends ConsumerState<_FeuilleCible> {
  String? _choisie;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final r = t.admin.tirage;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<CibleTirage>> candidats = ref.watch(
      candidatsCibleProvider,
    );
    return Column(
      key: const ValueKey<String>('tirage-feuille-cible'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(r.ajouterContexte, style: textes.bodyMedium),
        Ecart.vXl,
        BlocAsynchrone<List<CibleTirage>>(
          valeur: candidats,
          squelette: const Skeleton.liste(lignes: 2),
          onReessayer: () => ref.invalidate(candidatsCibleProvider),
          estVide: (List<CibleTirage> l) =>
              l.where((CibleTirage c) => !widget.deja.contains(c)).isEmpty,
          vide: EmptyState(
            key: const ValueKey<String>('tirage-aucun-candidat'),
            message: r.aucunCandidat,
            invitation: r.aucunCandidatDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          ),
          erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
              ? EtatSansDonnees(
                  key: const ValueKey<String>('tirage-candidats-sans-donnees'),
                  quoi: r.erreurCandidats,
                  onAction: reessayer,
                )
              : EtatSysteme(
                  key: const ValueKey<String>('tirage-candidats-erreur'),
                  nature: NatureEtat.echecServeur,
                  phrase: r.erreurCandidats,
                  onAction: reessayer,
                ),
          construire: (List<CibleTirage> liste) {
            final List<CibleTirage> libres = <CibleTirage>[
              for (final CibleTirage c in liste)
                if (!widget.deja.contains(c)) c,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(r.ajouterChoix, style: textes.titleMedium),
                Ecart.vMd,
                ChoiceCardGroup(
                  key: const ValueKey<String>('tirage-candidat'),
                  autoriserSaisieLibre: false,
                  options: <OptionChoix>[
                    for (final CibleTirage c in libres)
                      OptionChoix(
                        cle: ValueKey<String>(
                          'tirage-candidat-${c.type.name}-${c.id}',
                        ),
                        valeur: '${c.type.name}:${c.id}',
                        libelle: c.libelle,
                        description: libelleTypeCible(c.type),
                      ),
                  ],
                  onChange: (ReponseChoix reponse) => setState(() {
                    _choisie = reponse.valeurs.firstOrNull;
                    _message = null;
                  }),
                ),
                if (_message case final String message) ...<Widget>[
                  Ecart.vMd,
                  MessageAlerte(
                    message,
                    key: const ValueKey<String>('tirage-cible-message'),
                  ),
                ],
                Ecart.vXxl,
                BasDeFeuille(
                  key: const ValueKey<String>('tirage-ajouter-confirmer'),
                  libelle: r.ajouterConfirmer,
                  enCours: false,
                  horsLigne: r.horsLigne,
                  onPress: () {
                    final CibleTirage? cible = libres
                        .where(
                          (CibleTirage c) =>
                              '${c.type.name}:${c.id}' == _choisie,
                        )
                        .firstOrNull;
                    if (cible == null) {
                      setState(() => _message = r.manqueCible);
                      return;
                    }
                    Navigator.of(context).pop(cible);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// L'historique audite : filtre par statut, recherche, tableau pagine.
class _Historique extends ConsumerWidget {
  const _Historique({
    required this.filtre,
    required this.page,
    required this.derniere,
    required this.recherche,
    required this.onChercher,
    required this.onFiltre,
    required this.onPage,
    required this.onLue,
    required this.echec,
    required this.onRelire,
  });

  final FiltreTirages filtre;
  final int page;
  final PageTirages? derniere;
  final TextEditingController recherche;
  final ValueChanged<String> onChercher;
  final ValueChanged<FiltreTirages> onFiltre;
  final ValueChanged<int> onPage;
  final ValueChanged<PageTirages> onLue;
  final Widget Function(Object erreur, VoidCallback? reessayer) echec;
  final VoidCallback onRelire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.tirage;
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<PageTirages> lecture = ref.watch(
      pageTiragesProvider(RequeteTirages(filtre: filtre, page: page)),
    );
    if (lecture.hasValue) onLue(lecture.requireValue);
    final PageTirages? reference = lecture.value ?? derniere;
    final bool commandes = reference != null && reference.totalSansFiltre > 0;
    int? compte(StatutTirage s) => reference?.compteurs[s];
    FilterPill pastille(StatutTirage? statut, String libelle, int? compteur) =>
        FilterPill(
          key: ValueKey<String>('tirage-filtre-${statut?.name ?? 'tous'}'),
          libelle: libelle,
          compteur: compteur,
          retenue: filtre.statut == statut,
          onPress: () => onFiltre(filtre.avec(statut: () => statut)),
        );

    return Column(
      key: const ValueKey<String>('tirage-historique'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: r.historiqueTitre),
        Ecart.vXs,
        TexteSansCoupure(r.historiqueDetail, style: textes.bodySmall),
        Ecart.vMd,
        if (commandes) ...<Widget>[
          ChampRecherche(
            cleChamp: const ValueKey<String>('tirage-recherche'),
            controleur: recherche,
            libelle: r.rechercheLibelle,
            aide: r.rechercheAide,
            onChange: onChercher,
          ),
          Ecart.vMd,
          RangeeFiltres(
            filtres: <Widget>[
              pastille(null, r.filtreTous, reference.tousStatuts),
              pastille(
                StatutTirage.attribuee,
                r.filtreAttribuees,
                compte(StatutTirage.attribuee),
              ),
              pastille(
                StatutTirage.enCours,
                r.filtreEnCours,
                compte(StatutTirage.enCours),
              ),
              pastille(
                StatutTirage.controlee,
                r.filtreControlees,
                compte(StatutTirage.controlee),
              ),
              pastille(
                StatutTirage.nonControlee,
                r.filtreNonControlees,
                compte(StatutTirage.nonControlee),
              ),
              pastille(
                StatutTirage.dejaControlee,
                r.filtreDejaControlees,
                compte(StatutTirage.dejaControlee),
              ),
            ],
          ),
          Ecart.vXl,
        ],
        BlocAsynchrone<PageTirages>(
          key: const ValueKey<String>('tirage-bloc'),
          valeur: lecture,
          squelette: const Skeleton.liste(lignes: 4),
          onReessayer: onRelire,
          estVide: (PageTirages p) => p.totalSansFiltre == 0,
          vide: EmptyState(
            key: const ValueKey<String>('tirage-vide'),
            message: r.vide,
            invitation: r.videDetail,
            icone: AppIcons.controleQualite,
          ),
          erreurVersEtat: echec,
          construire: (PageTirages p) => _Tableau(page: p, onPage: onPage),
        ),
      ],
    );
  }
}

class _Tableau extends StatelessWidget {
  const _Tableau({required this.page, required this.onPage});

  final PageTirages page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final r = t.admin.tirage;
    if (page.lignes.isEmpty) {
      return EmptyState(
        key: const ValueKey<String>('tirage-aucun-filtre'),
        message: r.aucunAvecCeFiltre,
        invitation: r.aucunAvecCeFiltreDetail,
        registre: RegistreVide.subi,
        icone: AppIcons.rienAAfficher,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PileCartes(
          key: const ValueKey<String>('tirage-liste'),
          children: <Widget>[
            for (final TirageAudite t in page.lignes) _CarteTirage(tirage: t),
          ],
        ),
        Ecart.vLg,
        TexteSansCoupure(
          r.resume(
            debut: '${page.debut}',
            fin: '${page.fin}',
            total: '${page.total}',
          ),
          key: const ValueKey<String>('tirage-resume'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (page.pages > 1) ...<Widget>[
          Ecart.vSm,
          BarrePrecedentSuivant(
            position: t.commun.formats.pageSur(
              page: '${page.page}',
              total: '${page.pages}',
            ),
            positionSemantique: r.positionSemantique(
              page: '${page.page}',
              total: '${page.pages}',
            ),
            libellePrecedent: r.precedente,
            libelleSuivant: r.suivante,
            onPrecedent: page.page > 1 ? () => onPage(page.page - 1) : null,
            onSuivant: page.page < page.pages
                ? () => onPage(page.page + 1)
                : null,
          ),
        ],
      ],
    );
  }
}

/// Un tirage : la classe et son enseignant, le controleur, la date, le statut
/// (le mot et le ton, jamais la couleur seule) et, pour une mission non
/// controlee, le rapport parti a l'administration (BR-CT-15).
class _CarteTirage extends StatelessWidget {
  const _CarteTirage({required this.tirage});

  final TirageAudite tirage;

  TonEtat get _ton => switch (tirage.statut) {
    StatutTirage.controlee => TonEtat.succes,
    StatutTirage.enCours => TonEtat.accent,
    StatutTirage.attribuee => TonEtat.neutre,
    StatutTirage.nonControlee => TonEtat.alerte,
    StatutTirage.dejaControlee => TonEtat.avertissement,
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.tirage;
    final TirageAudite x = tirage;
    return AppCard(
      key: ValueKey<String>('tirage-${x.id}'),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(x.classe, style: textes.titleMedium),
          ),
          StatusPill(libelle: libelleStatutTirage(x.statut), ton: _ton),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: <Widget>[
          LigneCleValeur(cle: r.colonneEnseignant, valeur: x.enseignant),
          LigneCleValeur(cle: r.colonneControleur, valeur: x.controleur),
          LigneCleValeur(
            cle: r.colonneQuand,
            valeur: libelleQuandTirage(x.quand),
          ),
          LigneCleValeur(
            cle: r.colonneCritere,
            valeur: libelleCritereTirage(x.critere),
          ),
          if (x.statut == StatutTirage.nonControlee && x.rapportEnvoye)
            TexteSansCoupure(
              r.rapportEnvoye,
              key: ValueKey<String>('tirage-rapport-${x.id}'),
              style: textes.bodyMedium,
            ),
        ],
      ),
    );
  }
}

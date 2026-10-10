/// ECHELLE-ADM-FUSION-1 : les feuilles de la direction pour fusionner une
/// classe avec une classe parallele (R9), transferer un eleve vers une classe
/// parallele (R10, R5) et lire l'historique de ces mouvements.
///
/// Rien ne se fait sans l'apercu des effets puis la confirmation de la
/// direction. L'ecran ne decide d'aucune regle : quelles classes sont des
/// cibles, ce que la fusion fera, le refus en cas de chevauchement viennent
/// du port. Quand la reponse n'arrive pas, aucun etat n'est suppose (D5) :
/// « non confirme », la meme cle d'envoi est reprise (idempotence).
///
/// Etats de chaque feuille : chargement (`Skeleton`), contenu, vide
/// (`EmptyState`), erreur (`EtatSysteme`, « Reessayer »), hors ligne (le
/// bouton n'est pas rendu, une phrase dit pourquoi ; `EtatSansDonnees` si
/// rien n'a pu etre lu).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/port_fusion_classes.dart';
import '../../core/admin/port_pilotage.dart';
import '../../core/admin/service_groupes.dart' show groupesProvider;
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_groupes/bas_de_feuille.dart';
import '../admin_regroupements/feuille_classe_regroupement.dart'
    show nouvelleCleEnvoi;
import 'fusion_libelles.dart';

/// Ouvre la feuille de fusion de [classe].
Future<void> ouvrirFusion(BuildContext context, ClasseListee classe) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.fusion.fusionTitre(libelle: classe.nom),
      constructeur: (BuildContext _) => FeuilleFusion(classe: classe),
    );

/// Ouvre la feuille de transfert d'un eleve de [classe].
Future<void> ouvrirTransfert(BuildContext context, ClasseListee classe) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.fusion.transfertTitre(
        deLibelle: deDevant(classe.nom, cle: 'admin.fusion.transfertTitre'),
      ),
      constructeur: (BuildContext _) => FeuilleTransfert(classe: classe),
    );

/// Ouvre l'historique de [classe].
Future<void> ouvrirHistorique(BuildContext context, ClasseListee classe) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.fusion.historiqueTitre(
        deLibelle: deDevant(classe.nom, cle: 'admin.fusion.historiqueTitre'),
      ),
      constructeur: (BuildContext _) => HistoriqueClasse(classe: classe),
    );

/// Relit tout ce qu'une fusion ou un transfert fait bouger : la liste des
/// classes, le tableau de pilotage, les cibles, les eleves, l'historique.
void _relire(WidgetRef ref) => ref
  ..invalidate(groupesProvider)
  ..invalidate(pageClassesAdminProvider)
  ..invalidate(pagePilotageProvider)
  ..invalidate(classesCiblesProvider)
  ..invalidate(membresTransferablesProvider)
  ..invalidate(historiqueClasseProvider);

/// Une lecture qui a echoue : hors ligne sans donnees, ou une erreur avec
/// « Reessayer ». Jamais une page blanche.
Widget _echec({
  required bool horsLigne,
  required String cle,
  required String phraseErreur,
  required String phraseSansDonnees,
  required VoidCallback? reessayer,
}) => horsLigne
    ? EtatSansDonnees(
        key: ValueKey<String>('$cle-sans-donnees'),
        quoi: phraseSansDonnees,
        onAction: reessayer,
      )
    : EtatSysteme(
        key: ValueKey<String>('$cle-erreur'),
        nature: NatureEtat.echecServeur,
        phrase: phraseErreur,
        onAction: reessayer,
      );

/// La classe qui accueille, a choisir parmi [cibles].
class _ChoixCible extends StatelessWidget {
  const _ChoixCible({
    required this.cles,
    required this.titre,
    required this.cibles,
    required this.onChoix,
  });

  final String cles;
  final String titre;
  final List<ClasseCible> cibles;
  final ValueChanged<String?> onChoix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(titre, style: Theme.of(context).textTheme.titleMedium),
      Ecart.vMd,
      ChoiceCardGroup(
        key: ValueKey<String>(cles),
        autoriserSaisieLibre: false,
        options: <OptionChoix>[
          for (final ClasseCible c in cibles)
            OptionChoix(
              cle: ValueKey<String>('$cles-${c.classeId}'),
              valeur: c.classeId,
              libelle: c.nom,
              description: libelleDetailCible(c),
            ),
        ],
        onChange: (ReponseChoix r) => onChoix(r.valeurs.firstOrNull),
      ),
    ],
  );
}

/// La feuille de fusion : choisir la classe qui accueille, lire l'apercu des
/// effets, confirmer, lire le resultat.
class FeuilleFusion extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleFusion({required this.classe, super.key});

  /// La classe qui sera fusionnee (elle disparait).
  final ClasseListee classe;

  @override
  ConsumerState<FeuilleFusion> createState() => _FeuilleFusionEtat();
}

class _FeuilleFusionEtat extends ConsumerState<FeuilleFusion> {
  /// Une seule cle pour toute la feuille : deux pressions, ou une pression
  /// apres une reponse perdue, reprennent la meme fusion cote serveur.
  final String _cleEnvoi = nouvelleCleEnvoi();

  String? _cibleId;
  bool _envoi = false;
  String? _message;
  ResultatFusion? _resultat;

  Future<void> _fusionner() async {
    // Double appui : le second ne part pas.
    if (_envoi) return;
    final String? cible = _cibleId;
    if (cible == null) {
      setState(() => _message = t.admin.fusion.manqueCible);
      return;
    }
    final PortFusionClasses? port = ref.read(portFusionClassesProvider);
    if (port == null) return;
    setState(() {
      _envoi = true;
      _message = null;
    });
    ResultatFusion? resultat;
    try {
      resultat = await port.fusionner(
        sourceId: widget.classe.id,
        cibleId: cible,
        cleEnvoi: _cleEnvoi,
      );
    } on Object {
      // Sans reponse, rien n'est suppose (D5) : « non confirme ».
      resultat = null;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case null:
          _message = t.admin.fusion.fusionNonConfirmee;
        case FusionRefusee(:final String motif):
          _message = t.admin.fusion.fusionRefusee(motif: motif);
        case FusionFaite() || FusionDejaFaite():
          _resultat = resultat;
      }
    });
    if (resultat is FusionFaite || resultat is FusionDejaFaite) _relire(ref);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.fusion;
    final ResultatFusion? resultat = _resultat;
    if (resultat is FusionFaite) {
      return Column(
        key: const ValueKey<String>('fusion-faite'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(
              r.fusionFaite(
                n: resultat.elevesDeplaces,
                cible: resultat.cibleNom,
              ),
              style: textes.titleMedium,
            ),
          ),
          Ecart.vSm,
          TexteSansCoupure(r.famillesPrevenues, style: textes.bodyMedium),
        ],
      );
    }
    if (resultat is FusionDejaFaite) {
      return Semantics(
        liveRegion: true,
        child: TexteSansCoupure(
          r.fusionDejaFaite,
          key: const ValueKey<String>('fusion-deja-faite'),
          style: textes.titleMedium,
        ),
      );
    }
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<ClasseCible>> cibles = ref.watch(
      classesCiblesProvider((classeId: widget.classe.id, eleves: null)),
    );
    return Column(
      key: const ValueKey<String>('fusion-feuille'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(r.fusionContexte, style: textes.bodyMedium),
        Ecart.vXl,
        BlocAsynchrone<List<ClasseCible>>(
          valeur: cibles,
          squelette: const Skeleton.liste(lignes: 2),
          onReessayer: () => ref.invalidate(classesCiblesProvider),
          estVide: (List<ClasseCible> l) => l.isEmpty,
          vide: EmptyState(
            key: const ValueKey<String>('fusion-aucune-cible'),
            message: r.aucuneCible,
            invitation: r.aucuneCibleDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          ),
          erreurVersEtat: (Object _, VoidCallback? reessayer) => _echec(
            horsLigne: horsLigne,
            cle: 'fusion-cibles',
            phraseErreur: r.erreurCibles,
            phraseSansDonnees: r.sansDonneesCibles,
            reessayer: reessayer,
          ),
          construire: (List<ClasseCible> liste) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ChoixCible(
                cles: 'fusion-cible',
                titre: r.choixTitre,
                cibles: liste,
                onChoix: (String? id) => setState(() {
                  _cibleId = id;
                  _message = null;
                }),
              ),
              if (_cibleId case final String cible) ...<Widget>[
                Ecart.vXl,
                _Apercu(sourceId: widget.classe.id, cibleId: cible),
              ],
              if (_message case final String message) ...<Widget>[
                Ecart.vMd,
                MessageAlerte(
                  message,
                  key: const ValueKey<String>('fusion-message'),
                ),
              ],
              Ecart.vXxl,
              BasDeFeuille(
                key: const ValueKey<String>('fusion-confirmer'),
                libelle: r.confirmerFusion,
                enCours: _envoi,
                horsLigne: r.fusionHorsLigne,
                onPress: () => unawaited(_fusionner()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// L'apercu des effets d'une fusion : membres, effectif, enseignant libere,
/// familles prevenues, et ce qui ne se defait pas.
class _Apercu extends ConsumerWidget {
  const _Apercu({required this.sourceId, required this.cibleId});

  final String sourceId;
  final String cibleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.fusion;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<ApercuFusion> apercu = ref.watch(
      apercuFusionProvider((sourceId: sourceId, cibleId: cibleId)),
    );
    return Column(
      key: ValueKey<String>('fusion-apercu-$cibleId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(r.apercuTitre, style: textes.titleMedium),
        Ecart.vMd,
        BlocAsynchrone<ApercuFusion>(
          valeur: apercu,
          squelette: const Skeleton.liste(lignes: 2),
          onReessayer: () => ref.invalidate(apercuFusionProvider),
          erreurVersEtat: (Object _, VoidCallback? reessayer) => _echec(
            horsLigne: horsLigne,
            cle: 'fusion-apercu',
            phraseErreur: r.apercuErreur,
            phraseSansDonnees: r.apercuErreur,
            reessayer: reessayer,
          ),
          construire: (ApercuFusion a) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    TexteSansCoupure(
                      r.apercuMembres(n: a.membresDeplaces, cible: a.cible.nom),
                      key: const ValueKey<String>('fusion-apercu-membres'),
                      style: textes.bodyMedium,
                    ),
                    TexteSansCoupure(
                      r.apercuEffectif(
                        cible: a.cible.nom,
                        apres: '${a.membresApres}',
                        capacite: '${a.cible.capacite}',
                      ),
                      key: const ValueKey<String>('fusion-apercu-effectif'),
                      style: textes.bodyMedium,
                    ),
                    TexteSansCoupure(
                      a.enseignantLibere == null
                          ? r.apercuSansEnseignant
                          : r.apercuEnseignantLibere(
                              enseignant: a.enseignantLibere!,
                            ),
                      key: const ValueKey<String>('fusion-apercu-enseignant'),
                      style: textes.bodyMedium,
                    ),
                    TexteSansCoupure(
                      r.apercuFamilles(n: a.famillesNotifiees),
                      key: const ValueKey<String>('fusion-apercu-familles'),
                      style: textes.bodyMedium,
                    ),
                  ],
                ),
              ),
              Ecart.vMd,
              TexteSansCoupure(r.apercuIrreversible, style: textes.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// La feuille de transfert : choisir l'eleve, choisir la classe parallele
/// qui l'accueille, confirmer. Un chevauchement (R5) est refuse en clair.
class FeuilleTransfert extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleTransfert({required this.classe, super.key});

  /// La classe d'ou part l'eleve.
  final ClasseListee classe;

  @override
  ConsumerState<FeuilleTransfert> createState() => _FeuilleTransfertEtat();
}

class _FeuilleTransfertEtat extends ConsumerState<FeuilleTransfert> {
  final String _cleEnvoi = nouvelleCleEnvoi();

  String? _eleveId;
  String? _cibleId;
  bool _envoi = false;
  String? _message;
  ResultatTransfert? _resultat;

  /// Une nouvelle cle des que le choix change : « meme feuille, meme
  /// demande » ne vaut que pour le meme eleve et la meme classe.
  String get _cle => '$_cleEnvoi:${_eleveId ?? ''}:${_cibleId ?? ''}';

  Future<void> _transferer(
    List<MembreTransferable> membres,
    List<ClasseCible> cibles,
  ) async {
    if (_envoi) return;
    final MembreTransferable? eleve = membres
        .where((MembreTransferable m) => m.eleveId == _eleveId)
        .firstOrNull;
    final ClasseCible? cible = cibles
        .where((ClasseCible c) => c.classeId == _cibleId)
        .firstOrNull;
    if (eleve == null) {
      setState(() => _message = t.admin.fusion.manqueEleve);
      return;
    }
    if (cible == null) {
      setState(() => _message = t.admin.fusion.manqueCible);
      return;
    }
    final PortFusionClasses? port = ref.read(portFusionClassesProvider);
    if (port == null) return;
    setState(() {
      _envoi = true;
      _message = null;
    });
    ResultatTransfert? resultat;
    try {
      resultat = await port.transferer(
        eleveId: eleve.eleveId,
        sourceId: widget.classe.id,
        cibleId: cible.classeId,
        cleEnvoi: _cle,
      );
    } on Object {
      resultat = null;
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case null:
          _message = t.admin.fusion.transfertNonConfirme;
        case TransfertRefuse():
          _message = libelleRefusTransfert(
            resultat,
            prenom: eleve.prenom,
            cible: cible.nom,
          );
        case TransfertFait() || TransfertDejaFait():
          _resultat = resultat;
      }
    });
    if (resultat is TransfertFait || resultat is TransfertDejaFait) {
      _relire(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.fusion;
    final ResultatTransfert? resultat = _resultat;
    if (resultat is TransfertFait) {
      return Column(
        key: const ValueKey<String>('transfert-fait'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: TexteSansCoupure(
              r.transfertFait(
                prenom: resultat.prenom,
                cible: resultat.cibleNom,
              ),
              style: textes.titleMedium,
            ),
          ),
          Ecart.vSm,
          TexteSansCoupure(r.famillesPrevenues, style: textes.bodyMedium),
        ],
      );
    }
    if (resultat is TransfertDejaFait) {
      return Semantics(
        liveRegion: true,
        child: TexteSansCoupure(
          r.transfertDejaFait,
          key: const ValueKey<String>('transfert-deja-fait'),
          style: textes.titleMedium,
        ),
      );
    }
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<MembreTransferable>> membres = ref.watch(
      membresTransferablesProvider(widget.classe.id),
    );
    return Column(
      key: const ValueKey<String>('transfert-feuille'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(r.transfertContexte, style: textes.bodyMedium),
        Ecart.vXl,
        BlocAsynchrone<List<MembreTransferable>>(
          valeur: membres,
          squelette: const Skeleton.liste(lignes: 2),
          onReessayer: () => ref.invalidate(membresTransferablesProvider),
          estVide: (List<MembreTransferable> l) => l.isEmpty,
          vide: EmptyState(
            key: const ValueKey<String>('transfert-aucun-eleve'),
            message: r.aucunEleve,
            invitation: r.aucunEleveDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          ),
          erreurVersEtat: (Object _, VoidCallback? reessayer) => _echec(
            horsLigne: horsLigne,
            cle: 'transfert-eleves',
            phraseErreur: r.erreurEleves,
            phraseSansDonnees: r.erreurEleves,
            reessayer: reessayer,
          ),
          construire: (List<MembreTransferable> eleves) => _CorpsTransfert(
            eleves: eleves,
            classeId: widget.classe.id,
            eleveId: _eleveId,
            cibleId: _cibleId,
            message: _message,
            envoi: _envoi,
            onEleve: (String? id) => setState(() {
              _eleveId = id;
              _message = null;
            }),
            onCible: (String? id) => setState(() {
              _cibleId = id;
              _message = null;
            }),
            onConfirmer: (List<ClasseCible> cibles) =>
                unawaited(_transferer(eleves, cibles)),
          ),
        ),
      ],
    );
  }
}

class _CorpsTransfert extends ConsumerWidget {
  const _CorpsTransfert({
    required this.eleves,
    required this.classeId,
    required this.eleveId,
    required this.cibleId,
    required this.message,
    required this.envoi,
    required this.onEleve,
    required this.onCible,
    required this.onConfirmer,
  });

  final List<MembreTransferable> eleves;
  final String classeId;
  final String? eleveId;
  final String? cibleId;
  final String? message;
  final bool envoi;
  final ValueChanged<String?> onEleve;
  final ValueChanged<String?> onCible;
  final void Function(List<ClasseCible> cibles) onConfirmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.admin.fusion;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<ClasseCible>> cibles = ref.watch(
      classesCiblesProvider((classeId: classeId, eleves: 1)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(r.eleveTitre, style: textes.titleMedium),
        Ecart.vMd,
        ChoiceCardGroup(
          key: const ValueKey<String>('transfert-eleve'),
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final MembreTransferable m in eleves)
              OptionChoix(
                cle: ValueKey<String>('transfert-eleve-${m.eleveId}'),
                valeur: m.eleveId,
                libelle: m.prenom,
              ),
          ],
          onChange: (ReponseChoix reponse) =>
              onEleve(reponse.valeurs.firstOrNull),
        ),
        Ecart.vXl,
        BlocAsynchrone<List<ClasseCible>>(
          valeur: cibles,
          squelette: const Skeleton.liste(lignes: 2),
          onReessayer: () => ref.invalidate(classesCiblesProvider),
          estVide: (List<ClasseCible> l) => l.isEmpty,
          vide: EmptyState(
            key: const ValueKey<String>('transfert-aucune-cible'),
            message: r.aucuneCible,
            invitation: r.aucuneCibleDetail,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          ),
          erreurVersEtat: (Object _, VoidCallback? reessayer) => _echec(
            horsLigne: horsLigne,
            cle: 'transfert-cibles',
            phraseErreur: r.erreurCibles,
            phraseSansDonnees: r.sansDonneesCibles,
            reessayer: reessayer,
          ),
          construire: (List<ClasseCible> liste) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ChoixCible(
                cles: 'transfert-cible',
                titre: r.transfertCibleTitre,
                cibles: liste,
                onChoix: onCible,
              ),
              if (message case final String texte) ...<Widget>[
                Ecart.vMd,
                MessageAlerte(
                  texte,
                  key: const ValueKey<String>('transfert-message'),
                ),
              ],
              Ecart.vXxl,
              BasDeFeuille(
                key: const ValueKey<String>('transfert-confirmer'),
                libelle: r.confirmerTransfert,
                enCours: envoi,
                horsLigne: r.transfertHorsLigne,
                onPress: () => onConfirmer(liste),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// L'historique d'une classe : ses fusions et ses transferts, le plus recent
/// d'abord, avec leur date et leur heure.
class HistoriqueClasse extends ConsumerWidget {
  /// Cree l'historique.
  const HistoriqueClasse({required this.classe, super.key});

  /// La classe.
  final ClasseListee classe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.fusion;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<EvenementClasse>> lecture = ref.watch(
      historiqueClasseProvider(classe.id),
    );
    return BlocAsynchrone<List<EvenementClasse>>(
      key: const ValueKey<String>('historique-bloc'),
      valeur: lecture,
      squelette: const Skeleton.liste(lignes: 3),
      onReessayer: () => ref.invalidate(historiqueClasseProvider),
      estVide: (List<EvenementClasse> l) => l.isEmpty,
      vide: EmptyState(
        key: const ValueKey<String>('historique-vide'),
        message: r.historiqueVide,
        invitation: r.historiqueVideDetail,
        registre: RegistreVide.subi,
        icone: AppIcons.rienAAfficher,
      ),
      erreurVersEtat: (Object _, VoidCallback? reessayer) => _echec(
        horsLigne: horsLigne,
        cle: 'historique',
        phraseErreur: r.historiqueErreur,
        phraseSansDonnees: r.historiqueErreur,
        reessayer: reessayer,
      ),
      construire: (List<EvenementClasse> evenements) => CarteLignes(
        key: const ValueKey<String>('historique-liste'),
        lignes: <Widget>[
          for (final EvenementClasse e in evenements)
            LigneCleValeur(
              key: ValueKey<String>('historique-${e.id}'),
              cle: libelleEvenement(e),
              valeur: libelleQuand(e.quand),
            ),
        ],
      ),
    );
  }
}

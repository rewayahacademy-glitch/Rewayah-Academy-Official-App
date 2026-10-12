import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_partage_pedagogique.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart' show horsLigneProvider;
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../classe_tuteur/contexte_classe.dart' show cheminClasse;
import '../compte/carte_rubriques.dart';
import 'composants_historique.dart';
import 'filtres_historique.dart';

/// La cle d'un compte rendu : la seance et l'eleve (jamais l'un sans l'autre).
typedef CleCompteRendu = ({String seanceId, String eleveId});

/// Le compte rendu que la famille de l'eleve peut lire (PED-APRES-1, TUT-PED-APR-01).
///
/// **`autoDispose` et lie a la session** : rien ne survit a la sortie de l'ecran
/// ni a un changement de compte ou de foyer, donc aucun cache a servir apres une
/// revocation et aucun flash des donnees d'un autre eleve (A13). La cle porte
/// l'eleve : un autre eleve est une autre lecture, jamais la precedente.
final compteRenduFamilleProvider = FutureProvider.autoDispose
    .family<CompteRenduFamille, CleCompteRendu>((Ref ref, CleCompteRendu cle) {
      ref.watch(
        sessionProvider.select((s) => (s.profileId, s.householdId, s.role)),
      );
      return ref
          .watch(portPartagePedagogiqueProvider)
          .compteRenduFamille(seanceId: cle.seanceId, eleveId: cle.eleveId);
    });

/// Le bloc « Compte rendu pédagogique » du detail de seance du tuteur.
///
/// **Lecture seule, aucune action de modification.** Il ne lit que le port de
/// partage (jamais `lesson_reports`) et rend, selon ce que le serveur dit :
/// le compte rendu partageable, un message neutre (partage desactive ou
/// revoque), l'attente du cahier, l'absence de champ partageable, ou
/// l'indisponibilite de la source. **Hors ligne, il ne lit rien et n'affiche
/// aucune valeur gardee** : un compte rendu a pu etre revoque entre-temps.
class BlocCompteRendu extends ConsumerWidget {
  /// Cree le bloc.
  const BlocCompteRendu({
    required this.seanceId,
    required this.eleveId,
    this.classeId,
    super.key,
  });

  /// La seance.
  final String seanceId;

  /// L'eleve dont la famille lit.
  final String eleveId;

  /// La classe de la seance, si elle est connue : sans elle, aucun lien vers
  /// le travail ou la progression (pas de lien qui ne mene nulle part).
  final String? classeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (horsLigne) {
      return _CadreCompteRendu(
        titre: t.historique.compteRendu.titre,
        child: _PhraseCompteRendu(t.historique.compteRendu.horsLignePhrase),
      );
    }
    final CleCompteRendu cle = (seanceId: seanceId, eleveId: eleveId);
    final AsyncValue<CompteRenduFamille> lecture = ref.watch(
      compteRenduFamilleProvider(cle),
    );
    return BlocAsynchrone<CompteRenduFamille>(
      valeur: lecture,
      squelette: const Skeleton.liste(lignes: 3),
      onReessayer: () => ref.invalidate(compteRenduFamilleProvider(cle)),
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
        // Aucune cause technique a l'ecran : l'indisponibilite et le refus ne
        // se reessaient pas (recommencer ne change rien), un echec oui.
        final bool definitif =
            erreur is CapaciteIndisponible || erreur is PermissionInsuffisante;
        return EtatSysteme(
          nature: definitif ? NatureEtat.indisponible : NatureEtat.echecServeur,
          titre: t.historique.compteRendu.titre,
          phrase: t.historique.compteRendu.illisiblePhrase,
          onAction: definitif ? null : reessayer,
          dependance: erreur is CapaciteIndisponible ? erreur.dependance : null,
        );
      },
      construire: (CompteRenduFamille compteRendu) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarteCompteRendu(compteRendu: compteRendu),
          if (compteRendu.etat == EtatCompteRendu.partage &&
              compteRendu.aDuContenu &&
              classeId != null) ...<Widget>[
            Ecart.vMd,
            LienFleche(
              libelle: t.historique.compteRendu.voirTravail,
              alignerEnDebut: true,
              onPress: () => _ouvrir(context, ref, 'travail'),
            ),
            LienFleche(
              libelle: t.historique.compteRendu.voirProgression,
              alignerEnDebut: true,
              onPress: () => _ouvrir(context, ref, 'progression'),
            ),
          ],
        ],
      ),
    );
  }

  /// Un lien vers une sous-page existante de la classe, pour **le meme eleve**
  /// que le detail (Historique, Progression et Travail parlent du meme enfant).
  void _ouvrir(BuildContext context, WidgetRef ref, String segment) {
    ref.read(selectionEleveProvider.notifier).choisir(eleveId);
    GoRouter.of(context).go(cheminClasse(classeId!, eleveId, segment));
  }
}

/// Le compte rendu tel que la famille le lit : **le seul rendu**, partage par
/// le detail du tuteur et par l'apercu de la direction (ADM-PED-APR-03), pour
/// que la direction voie exactement ce que la famille verra.
///
/// N'affiche que les champs presents (aucune rubrique vide), dans l'ordre :
/// travaille, appreciation, a renforcer, a preparer, commentaire partage.
class CarteCompteRendu extends StatelessWidget {
  /// Cree la carte.
  const CarteCompteRendu({required this.compteRendu, super.key});

  /// Ce que le serveur autorise.
  final CompteRenduFamille compteRendu;

  @override
  Widget build(BuildContext context) {
    final l = t.historique.compteRendu;
    final bool lisible =
        compteRendu.etat == EtatCompteRendu.partage && compteRendu.aDuContenu;
    final String titre = compteRendu.etat == EtatCompteRendu.nonPartage
        ? l.nonDisponibleTitre
        : l.titre;
    return _CadreCompteRendu(
      titre: titre,
      child: lisible
          ? _Rubriques(compteRendu: compteRendu)
          : _PhraseCompteRendu(switch (compteRendu.etat) {
              EtatCompteRendu.nonPartage => l.nonPartagePhrase,
              EtatCompteRendu.enAttente => l.enAttentePhrase,
              // Partage annonce mais sans aucun champ : meme phrase que
              // « aucun champ », jamais une carte vide.
              EtatCompteRendu.aucunChamp ||
              EtatCompteRendu.partage => l.aucunChampPhrase,
            }),
    );
  }
}

/// Le titre de bloc et sa carte, au gabarit des autres blocs du detail.
class _CadreCompteRendu extends StatelessWidget {
  const _CadreCompteRendu({required this.titre, required this.child});

  final String titre;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          child: Semantics(
            header: true,
            child: Text(
              titre,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
        ),
        SurfaceCarte(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _PhraseCompteRendu extends StatelessWidget {
  const _PhraseCompteRendu(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => NoteHistorique(texte);
}

class _Rubriques extends StatelessWidget {
  const _Rubriques({required this.compteRendu});

  final CompteRenduFamille compteRendu;

  @override
  Widget build(BuildContext context) {
    final l = t.historique.compteRendu;
    final List<Widget> rubriques = <Widget>[
      if ((compteRendu.travaille ?? '').isNotEmpty)
        _Rubrique(
          libelle: l.travaille,
          lignes: <String>[compteRendu.travaille!],
        ),
      if ((compteRendu.appreciation ?? '').isNotEmpty)
        _Rubrique(
          libelle: l.appreciation,
          lignes: <String>[compteRendu.appreciation!],
        ),
      if (compteRendu.aRenforcer.isNotEmpty)
        _Rubrique(libelle: l.aRenforcer, lignes: compteRendu.aRenforcer),
      if (compteRendu.aPreparer.isNotEmpty)
        _Rubrique(libelle: l.aPreparer, lignes: compteRendu.aPreparer),
      if ((compteRendu.commentairePartage ?? '').isNotEmpty)
        _Rubrique(
          libelle: l.commentaire,
          lignes: <String>[compteRendu.commentairePartage!],
        ),
    ];
    final DateTime? corrige = compteRendu.corrigeLe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < rubriques.length; i++) ...<Widget>[
          if (i > 0) Ecart.vLg,
          rubriques[i],
        ],
        if (corrige != null) ...<Widget>[
          Ecart.vLg,
          NoteHistorique(l.corrigeLe(date: dateCourte(corrige))),
        ],
      ],
    );
  }
}

/// Une rubrique : son intitule en encre attenuee, ses lignes en encre forte.
/// Lue d'un seul noeud (l'intitule puis le texte).
class _Rubrique extends StatelessWidget {
  const _Rubrique({required this.libelle, required this.lignes});

  final String libelle;
  final List<String> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            libelle,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          for (final String ligne in lignes)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
              child: Text(
                ligne,
                style: palette.inkStrong.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

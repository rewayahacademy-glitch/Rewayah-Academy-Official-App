// Le detail d'une transaction dans l'espace de rapprochement (spec §25, §47,
// §48 ; CPT-BR-14, 17) : panneau a 1440, feuille sous 1200.
//
// Ce que la source rend, rien d'autre : l'etat (§25), la cible deja reliee,
// les correspondances proposees, le doublon potentiel (jamais silencieux,
// §47), le journal. « Rapprocher » et « Marquer comme doublon » ne se
// montrent que si la source permet `rapprocher` ; sinon la raison rendue
// (DR-19). Chaque ecriture porte une cle d'idempotence, gardee tant que la
// reponse n'est pas arrivee : un nouvel appui apres un echec rejoue la meme
// cle, la source n'agit qu'une fois. L'etat affiche apres l'ecriture est
// celui que la source rend, jamais un succes suppose (§5.3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/capacites/port_rapprochement.dart';
import '../../../../core/comptable/modeles_comptable.dart';
import '../../../../core/comptable/statuts_comptable.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/action_principale.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/bandeau_attention.dart';
import '../../../../core/widgets/comptable/ligne_activite.dart';
import '../../../../core/widgets/ligne_cle_valeur.dart';
import '../../../../core/widgets/montant_sensible.dart';
import '../../../../core/widgets/pastilles_comptable.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_pill.dart';
import '../commun_encaissements.dart';
import 'donnees_rapprochement.dart';

/// Vrai quand l'element n'attend plus rien du Comptable.
bool estRelie(EtatRapprochement etat) =>
    etat == EtatRapprochement.rapproche ||
    etat == EtatRapprochement.automatique;

/// Le detail d'un element, lu dans la liste du port par son identifiant
/// (la liste relue apres une ecriture met le detail a jour).
class PanneauRapprochement extends ConsumerStatefulWidget {
  /// Cree le panneau.
  const PanneauRapprochement({required this.elementId, super.key});

  /// L'element.
  final String elementId;

  /// La cle du bouton « Rapprocher » d'un candidat.
  static Key rapprocherKey(String cibleId) =>
      ValueKey<String>('rap-rapprocher-$cibleId');

  /// La cle du bouton « Marquer comme doublon ».
  static const Key doublonKey = ValueKey<String>('rap-doublon');

  /// La cle du resultat rendu par la source.
  static const Key resultatKey = ValueKey<String>('rap-resultat');

  @override
  ConsumerState<PanneauRapprochement> createState() =>
      _PanneauRapprochementState();
}

class _PanneauRapprochementState extends ConsumerState<PanneauRapprochement> {
  /// Les cles d'idempotence en vol, par action (« doublon », « cible:x »).
  final Map<String, String> _cles = <String, String>{};
  String? _resultat;
  bool _echec = false;
  bool _envoi = false;

  @override
  void didUpdateWidget(PanneauRapprochement ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.elementId != widget.elementId) {
      _cles.clear();
      _resultat = null;
      _echec = false;
    }
  }

  Future<void> _ecrire(
    String action,
    Future<ElementRapprochement> Function(String cle) appel,
  ) async {
    if (_envoi) return;
    final String cle = _cles.putIfAbsent(action, () => const Uuid().v4());
    setState(() {
      _envoi = true;
      _echec = false;
      _resultat = null;
    });
    try {
      final ElementRapprochement reponse = await appel(cle);
      _cles.remove(action);
      if (!mounted) return;
      setState(() {
        _resultat = t.comptable.encaissements.rap.resultat(
          etat: libelleRapprochement(reponse.etat),
        );
      });
      ref
        ..invalidate(elementsRapprochementProvider)
        ..invalidate(journalRapprochementProvider(widget.elementId));
    } on Object {
      if (mounted) setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _actualiser() {
    setState(() => _echec = false);
    ref
      ..invalidate(elementsRapprochementProvider)
      ..invalidate(propositionRapprochementProvider(widget.elementId))
      ..invalidate(journalRapprochementProvider(widget.elementId));
  }

  @override
  Widget build(BuildContext context) {
    final List<ElementRapprochement> elements =
        ref.watch(elementsRapprochementProvider).value ??
        const <ElementRapprochement>[];
    ElementRapprochement? element;
    for (final ElementRapprochement e in elements) {
      if (e.id == widget.elementId) element = e;
    }
    final ElementRapprochement? el = element;
    if (el == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.comptable.encaissements.rap;
    final e = t.comptable.encaissements;
    final PortRapprochement port = ref.read(portRapprochementProvider);
    final bool peut = el.permissions.permet(ActionFinance.rapprocher);
    final RaisonBlocage? raison = el.permissions.raisonDe(
      ActionFinance.rapprocher,
    );
    final String? cible = el.cibleLibelle;
    final String? reference = el.reference;
    final String? prestataire = el.prestataire;
    final String? resultat = _resultat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            el.libelle,
            style: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXs,
        NoteAttenuee(
          r.natureDate(
            nature: libelleNatureRapprochement(el.nature),
            date: dateComptable(el.date),
          ),
        ),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PastilleRapprochement(el.etat),
        ),
        if (resultat != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            key: PanneauRapprochement.resultatKey,
            liveRegion: true,
            child: Text(
              resultat,
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        if (_echec) ...<Widget>[
          Ecart.vMd,
          BandeauAttention(
            titre: r.erreurEnvoiTitre,
            message: r.erreurEnvoi,
            ton: TonEtat.avertissement,
            action: ActionPrincipale(
              libelle: r.actualiser,
              niveau: NiveauAction.tertiaire,
              onPress: _actualiser,
            ),
          ),
        ],
        Ecart.vLg,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LigneMontant(libelle: r.montant, montant: el.montant, fort: true),
              if (reference != null)
                LigneCleValeur(
                  cle: e.reference,
                  valeur: reference,
                  chiffres: true,
                ),
              if (prestataire != null)
                LigneCleValeur(cle: e.prestataire, valeur: prestataire),
              if (cible != null)
                LigneCleValeur(
                  cle: e.rapprochement,
                  valeur: r.relieA(libelle: cible),
                ),
            ],
          ),
        ),
        if (el.etat == EtatRapprochement.doublonPotentiel) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            titre: r.doublonTitre,
            message: r.doublonPhrase,
            ton: TonEtat.alerte,
            action: peut
                ? ActionPrincipale(
                    key: PanneauRapprochement.doublonKey,
                    libelle: r.marquerDoublon,
                    niveau: NiveauAction.secondaire,
                    enCours: _envoi,
                    onPress: () => _ecrire(
                      'doublon',
                      (String cle) => port.marquerDoublon(
                        transactionId: el.id,
                        cleIdempotence: cle,
                      ),
                    ),
                  )
                : null,
          ),
        ],
        if (!peut && raison != null) ...<Widget>[
          Ecart.vMd,
          NoteAttenuee(libelleRaisonBlocage(raison)),
        ],
        if (!estRelie(el.etat)) ...<Widget>[
          Ecart.vLg,
          TitreZone(r.candidats),
          Ecart.vSm,
          _Candidats(
            element: el,
            peut: peut,
            envoi: _envoi,
            onRapprocher: (ElementRapprochement c) => _ecrire(
              'cible:${c.id}',
              (String cle) => port.rapprocher(
                transactionId: el.id,
                cibleId: c.id,
                cleIdempotence: cle,
              ),
            ),
          ),
        ],
        Ecart.vLg,
        TitreZone(r.journal),
        Ecart.vSm,
        AppCard(
          child: BlocEncaissements<List<EntreeJournal>>(
            valeur: ref.watch(journalRapprochementProvider(el.id)),
            onReessayer: () =>
                ref.invalidate(journalRapprochementProvider(el.id)),
            squelette: const Skeleton.texte(lignes: 2),
            vide: NoteAttenuee(r.journalVide),
            construire: (List<EntreeJournal> entrees) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final EntreeJournal j in entrees) LigneActivite(j),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Les correspondances proposees par la source, du plus probable au moins
/// probable ; un doublon vu par la source est dit en tete.
class _Candidats extends ConsumerWidget {
  const _Candidats({
    required this.element,
    required this.peut,
    required this.envoi,
    required this.onRapprocher,
  });

  final ElementRapprochement element;
  final bool peut;
  final bool envoi;
  final void Function(ElementRapprochement cible) onRapprocher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.comptable.encaissements.rap;
    return BlocEncaissements<PropositionRapprochement>(
      valeur: ref.watch(propositionRapprochementProvider(element.id)),
      onReessayer: () =>
          ref.invalidate(propositionRapprochementProvider(element.id)),
      squelette: const Skeleton.liste(lignes: 2),
      construire: (PropositionRapprochement p) {
        final bool doublonSeul =
            p.doublonPotentiel &&
            element.etat != EtatRapprochement.doublonPotentiel;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (doublonSeul) ...<Widget>[
              BandeauAttention(
                titre: r.doublonTitre,
                message: r.doublonPhrase,
                ton: TonEtat.alerte,
              ),
              Ecart.vMd,
            ],
            if (p.candidats.isEmpty)
              AppCard(child: NoteAttenuee(r.candidatsAucun))
            else
              for (int i = 0; i < p.candidats.length; i++) ...<Widget>[
                if (i > 0) Ecart.vLg,
                _Candidat(
                  candidat: p.candidats[i],
                  peut: peut,
                  envoi: envoi,
                  onRapprocher: () => onRapprocher(p.candidats[i]),
                ),
              ],
          ],
        );
      },
    );
  }
}

class _Candidat extends StatelessWidget {
  const _Candidat({
    required this.candidat,
    required this.peut,
    required this.envoi,
    required this.onRapprocher,
  });

  final ElementRapprochement candidat;
  final bool peut;
  final bool envoi;
  final VoidCallback onRapprocher;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.comptable.encaissements.rap;
    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          candidat.libelle,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        NoteAttenuee(
          r.natureDate(
            nature: libelleNatureRapprochement(candidat.nature),
            date: dateComptable(candidat.date),
          ),
        ),
      ],
    );
    final Widget montant = MontantSensible(candidat.montant);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (texteAgrandi(context)) ...<Widget>[texte, Ecart.vSm, montant] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: texte),
                Ecart.hLg,
                montant,
              ],
            ),
          if (peut) ...<Widget>[
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                label: r.rapprocherLecteur(libelle: candidat.libelle),
                excludeSemantics: true,
                button: true,
                child: ActionPrincipale(
                  key: PanneauRapprochement.rapprocherKey(candidat.id),
                  libelle: r.rapprocher,
                  niveau: NiveauAction.secondaire,
                  enCours: envoi,
                  onPress: onRapprocher,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

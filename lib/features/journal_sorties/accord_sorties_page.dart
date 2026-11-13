import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/journal_sorties/port_journal_sorties.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;
import '../suivi_foyer/filtres_historique.dart' show dateCourte;
import 'texte_accord_sorties.dart';

/// HORS-SALLE-2 : l'accord du journal des sorties de l'application
/// (`/tuteur/compte/sorties` pour le tuteur, `/compte/sorties` pour l'eleve
/// adulte autonome).
///
/// Le tuteur a une carte par enfant mineur du foyer ; l'eleve adulte une
/// seule, pour lui-meme. Le texte (PROPOSITION a valider par le directeur)
/// une fois, puis les cartes : la case jamais precochee, ou « Accepte le … »
/// et « Retirer mon accord ». Un seul bouton plein, « Enregistrer mon
/// accord », pour les cases cochees. La liste vient du serveur, qui decide
/// qui peut donner l'accord pour qui (`accords_sorties`).
///
/// Tant que la direction n'a pas allume le journal, la page n'est pas
/// proposee dans le Compte ; atteinte par son adresse, elle le dit et ne
/// montre aucune case.
class AccordSortiesPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const AccordSortiesPage({super.key, this.onRetour});

  /// Le retour ; le Compte du tuteur par defaut.
  final VoidCallback? onRetour;

  @override
  ConsumerState<AccordSortiesPage> createState() => _AccordSortiesPageState();
}

class _AccordSortiesPageState extends ConsumerState<AccordSortiesPage> {
  final Set<String> _cochees = <String>{};
  bool _envoi = false;
  String? _retraitEnCours;
  String? _erreur;
  String? _annonce;
  final FocusNode _focusCase = FocusNode(debugLabel: 'case-accord-sorties');

  @override
  void dispose() {
    _focusCase.dispose();
    super.dispose();
  }

  void _retour() {
    final VoidCallback? retour = widget.onRetour;
    if (retour != null) {
      retour();
      return;
    }
    GoRouter.of(context).go(Routes.tuteurCompte);
  }

  String _messageRefus(Object e) => switch (e) {
    AccordSortiesRefuse(motif: MotifRefusAccord.versionPerimee) =>
      t.journalSorties.accord.versionPerimee,
    AccordSortiesRefuse(motif: MotifRefusAccord.journalEteint) =>
      t.journalSorties.accord.eteint,
    _ => t.journalSorties.accord.erreur,
  };

  Future<void> _enregistrer(EtatAccordsSorties etat) async {
    if (_cochees.isEmpty) {
      // Jamais grise : l'appui dit ce qui manque et rend le focus a la case.
      final String message = t.journalSorties.accord.manque;
      setState(() => _erreur = message);
      signalerManque(context, message, champ: _focusCase);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _annonce = null;
    });
    final PortJournalSorties port = ref.read(portJournalSortiesProvider);
    try {
      for (final String eleve in _cochees.toList()) {
        await port.accepter(eleveId: eleve, version: etat.versionCourante!);
        _cochees.remove(eleve);
      }
      if (mounted) setState(() => _annonce = t.journalSorties.accord.merci);
    } on Object catch (e) {
      if (mounted) setState(() => _erreur = _messageRefus(e));
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
        ref.invalidate(accordsSortiesProvider);
      }
    }
  }

  Future<void> _retirer(String eleveId) async {
    setState(() {
      _retraitEnCours = eleveId;
      _erreur = null;
      _annonce = null;
    });
    try {
      await ref.read(portJournalSortiesProvider).retirer(eleveId);
      if (mounted) setState(() => _annonce = t.journalSorties.accord.retire);
    } on Object catch (e) {
      if (mounted) setState(() => _erreur = _messageRefus(e));
    } finally {
      if (mounted) {
        setState(() => _retraitEnCours = null);
        ref.invalidate(accordsSortiesProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(monHorlogeProvider);
    final AsyncValue<EtatAccordsSorties?> lecture = ref.watch(
      accordsSortiesProvider,
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget corps;
    if (lecture.hasError && !lecture.hasValue) {
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              t.journalSorties.accord.lectureErreur,
              style: textes.bodyLarge,
            ),
          ),
          Ecart.vXl,
          // Un seul bouton plein par ecran (K-56) : celui de l'accord ;
          // « Reessayer » est en contour.
          ActionPrincipale(
            libelle: t.commun.reessayer,
            niveau: NiveauAction.secondaire,
            onPress: () => ref.invalidate(accordsSortiesProvider),
          ),
        ],
      );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 4);
    } else {
      final EtatAccordsSorties? etat = lecture.value;
      corps = etat == null || !etat.propose
          ? Text(t.journalSorties.accord.horsService, style: textes.bodyLarge)
          : _contenu(etat, textes);
    }
    return PageShell(
      titre: t.journalSorties.accord.titre,
      onRetour: _retour,
      child: corps,
    );
  }

  Widget _contenu(EtatAccordsSorties etat, TextTheme textes) {
    final AppPalette palette = AppPalette.of(context);
    // Le serveur dit, par eleve, s'il est autonome : un eleve adulte qui est
    // aussi parent voit sa propre decision (texte de l'adulte) ET celles de
    // ses enfants (texte du parent), chacune separee. Aucun role n'est lu.
    final List<AccordSortiesEleve> pourSoi = <AccordSortiesEleve>[
      for (final AccordSortiesEleve e in etat.eleves)
        if (e.autonome) e,
    ];
    final List<AccordSortiesEleve> enfants = <AccordSortiesEleve>[
      for (final AccordSortiesEleve e in etat.eleves)
        if (!e.autonome) e,
    ];
    final bool unSansAccord = etat.eleves.any(
      (AccordSortiesEleve e) => !e.enCours,
    );
    // Le focus revient a la premiere case quand rien n'est coche.
    final String? premiereCase = <AccordSortiesEleve>[...pourSoi, ...enfants]
        .where((AccordSortiesEleve e) => !e.enCours)
        .map((AccordSortiesEleve e) => e.eleveId)
        .firstOrNull;
    List<Widget> groupe(
      List<AccordSortiesEleve> eleves, {
      required bool adulte,
    }) => <Widget>[
      TexteAccordSorties(adulte: adulte),
      Ecart.vXl,
      PileCartes(
        children: <Widget>[
          for (final AccordSortiesEleve e in eleves)
            if (e.enCours)
              _CarteAccepte(
                eleve: e,
                adulte: adulte,
                enCours: _retraitEnCours == e.eleveId,
                onRetirer: _retraitEnCours == null && !_envoi
                    ? () => unawaited(_retirer(e.eleveId))
                    : null,
              )
            else
              CaseAccordTexte(
                key: ValueKey<String>('case-sorties-${e.eleveId}'),
                libelle: adulte
                    ? t.journalSorties.texte.adulte.caseAccord
                    : t.journalSorties.texte.parent.caseAccord(
                        dePrenom: deDevant(e.prenom),
                      ),
                cochee: _cochees.contains(e.eleveId),
                focusNode: e.eleveId == premiereCase ? _focusCase : null,
                onChanged: _envoi
                    ? null
                    : (bool v) => setState(() {
                        _erreur = null;
                        v
                            ? _cochees.add(e.eleveId)
                            : _cochees.remove(e.eleveId);
                      }),
              ),
        ],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          enfants.isEmpty
              ? t.journalSorties.accord.introAdulte
              : t.journalSorties.accord.intro,
          style: textes.bodyLarge,
        ),
        Ecart.vXl,
        if (pourSoi.isNotEmpty) ...groupe(pourSoi, adulte: true),
        if (pourSoi.isNotEmpty && enfants.isNotEmpty) Ecart.vXxl,
        if (enfants.isNotEmpty) ...groupe(enfants, adulte: false),
        if (_erreur != null || _annonce != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur ?? _annonce!,
              style: _erreur != null
                  ? palette.inkAlert.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    )
                  : textes.bodyMedium,
            ),
          ),
        ],
        if (unSansAccord) ...<Widget>[
          Ecart.vXl,
          ActionPrincipale(
            libelle: t.journalSorties.accord.enregistrer,
            onPress: () => unawaited(_enregistrer(etat)),
            enCours: _envoi,
          ),
        ],
      ],
    );
  }
}

/// Une carte d'accord donne : le prenom (chez le tuteur), la date, et le lien
/// pour le retirer.
class _CarteAccepte extends StatelessWidget {
  const _CarteAccepte({
    required this.eleve,
    required this.adulte,
    required this.enCours,
    required this.onRetirer,
  });

  final AccordSortiesEleve eleve;
  final bool adulte;
  final bool enCours;
  final VoidCallback? onRetirer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime? le = eleve.accepteLe;
    final VoidCallback? retirer = onRetirer;
    return AppCard(
      key: ValueKey<String>('accord-sorties-${eleve.eleveId}'),
      actions: LienFleche(
        libelle: adulte
            ? t.journalSorties.accord.retirer
            : t.journalSorties.accord.retirerPour(prenom: eleve.prenom),
        alignerEnFin: true,
        onPress: retirer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!adulte) Text(eleve.prenom, style: textes.titleMedium),
          Text(
            le == null
                ? t.journalSorties.accord.merci
                : t.journalSorties.accord.accepteLe(
                    date: dateCourte(chezMoi(le)),
                  ),
            style: textes.bodyLarge,
          ),
        ],
      ),
    );
  }
}

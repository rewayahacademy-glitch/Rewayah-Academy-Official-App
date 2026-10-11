import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/recherche/controleur_recherche.dart';
import '../../../core/recherche/etat_recherche.dart';
import '../../../core/recherche/modeles_recherche.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/champ_recherche.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/rangee_filtres.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/skeleton.dart';
import '../resolveur_cible.dart';

/// La cle du champ de saisie : la coque admin porte son propre champ, les
/// tests et D5 designent celui-ci par sa cle.
const Key cleChampRecherche = ValueKey<String>('recherche-champ');

/// Les textes d'un espace de recherche.
String libelleEspaceRecherche(EspaceRecherche espace) {
  final e = t.recherche.espace;
  return switch (espace) {
    EspaceRecherche.famille => e.famille,
    EspaceRecherche.eleve => e.eleve,
    EspaceRecherche.eleveGuide => e.eleveGuide,
    EspaceRecherche.enseignant => e.enseignant,
    EspaceRecherche.controleur => e.controleur,
    EspaceRecherche.comptable => e.comptable,
    EspaceRecherche.administration => e.administration,
  };
}

/// Le titre d'une section de resultats.
String libelleDomaineRecherche(DomaineRecherche domaine) {
  final d = t.recherche.domaines;
  return switch (domaine) {
    DomaineRecherche.classes => d.classes,
    DomaineRecherche.supports => d.supports,
    DomaineRecherche.personnes => d.personnes,
    DomaineRecherche.enseignants => d.enseignants,
    DomaineRecherche.pedagogie => d.pedagogie,
    DomaineRecherche.controle => d.controle,
    DomaineRecherche.finances => d.finances,
    DomaineRecherche.fils => d.fils,
  };
}

/// L'icone d'un type de resultat.
AppIcon iconeResultat(TypeResultat type) => switch (type) {
  TypeResultat.classe => AppIcons.classes,
  TypeResultat.seance => AppIcons.cours,
  TypeResultat.support => AppIcons.supports,
  TypeResultat.personne || TypeResultat.eleveClasse => AppIcons.eleves,
  TypeResultat.enseignant => AppIcons.profil,
  TypeResultat.remplacement => AppIcons.reaffectation,
  TypeResultat.mission => AppIcons.controleQualite,
  TypeResultat.operation => AppIcons.finance,
  TypeResultat.fil => AppIcons.discussion,
};

/// La surface de recherche (spec RECH-03 §4, §5) : un champ, puis **une
/// phase, un texte**.
///
/// Rien ne part pour un champ vide ou trop court ; chaque resultat ouvre sa
/// route canonique et aucun ne porte d'action d'ecriture ; une panne n'est
/// jamais un « aucun resultat » ; la requete ne quitte jamais cet ecran (ni
/// adresse, ni cache, ni historique).
class EcranRecherche extends ConsumerStatefulWidget {
  /// Cree l'ecran d'un [contexte].
  const EcranRecherche({required this.contexte, super.key});

  /// L'espace actif et le domaine d'ouverture.
  final ContexteRecherche contexte;

  @override
  ConsumerState<EcranRecherche> createState() => _EtatEcranRecherche();
}

class _EtatEcranRecherche extends ConsumerState<EcranRecherche> {
  final TextEditingController _texte = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _texte.dispose();
    _focus.dispose();
    super.dispose();
  }

  RechercheControleur get _controleur =>
      ref.read(rechercheControleurProvider(widget.contexte).notifier);

  void _retour() {
    final GoRouter routeur = GoRouter.of(context);
    if (routeur.canPop()) {
      routeur.pop();
    } else {
      routeur.go(Routes.racine);
    }
  }

  void _modifier() {
    _focus.requestFocus();
    _texte.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _texte.text.length,
    );
  }

  void _ouvrir(ResultatRecherche resultat) {
    final String? chemin = cheminPourCible(
      resultat.cible,
      widget.contexte.espace,
    );
    if (chemin != null) GoRouter.of(context).push(chemin);
  }

  @override
  Widget build(BuildContext context) {
    final EtatRecherche etat = ref.watch(
      rechercheControleurProvider(widget.contexte),
    );
    final bool guide = widget.contexte.espace == EspaceRecherche.eleveGuide;
    final List<DomaineRecherche> portees =
        ref.watch(porteesRechercheProvider(widget.contexte)).value ??
        const <DomaineRecherche>[];
    return PageShell(
      titre: guide ? t.recherche.guide.titre : t.recherche.titre,
      sousTitre: guide ? null : libelleEspaceRecherche(widget.contexte.espace),
      onRetour: _retour,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChampRecherche(
            cleChamp: cleChampRecherche,
            controleur: _texte,
            focusNode: _focus,
            libelle: t.recherche.champ.libelle,
            aide: t.recherche.champ.aide,
            autofocus: true,
            onChange: _controleur.ecrire,
            onValider: (String _) => _controleur.valider(),
          ),
          // Les puces ne viennent que des domaines que le serveur sert
          // (jamais codees) ; l'Interface guidee n'en a pas : un domaine a la
          // fois (§4.5).
          if (!guide &&
              widget.contexte.domaineCible == null &&
              portees.length > 1) ...<Widget>[
            Ecart.vMd,
            Semantics(
              container: true,
              label: t.recherche.filtres,
              child: RangeeFiltres(
                filtres: <Widget>[
                  FilterPill(
                    libelle: t.recherche.tout,
                    retenue: etat.filtre == null,
                    onPress: () => _controleur.choisirDomaine(null),
                  ),
                  for (final DomaineRecherche d in portees)
                    FilterPill(
                      libelle: libelleDomaineRecherche(d),
                      retenue: etat.filtre == d,
                      onPress: () => _controleur.choisirDomaine(d),
                    ),
                ],
              ),
            ),
          ],
          Ecart.vLg,
          _Corps(
            etat: etat,
            contexte: widget.contexte,
            guide: guide,
            onOuvrir: _ouvrir,
            onModifier: _modifier,
            onReessayer: _controleur.reessayer,
            onReessayerDomaine: _controleur.reessayerDomaine,
            onPlus: _controleur.plusDeResultats,
            onRetour: _retour,
          ),
        ],
      ),
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.etat,
    required this.contexte,
    required this.guide,
    required this.onOuvrir,
    required this.onModifier,
    required this.onReessayer,
    required this.onReessayerDomaine,
    required this.onPlus,
    required this.onRetour,
  });

  final EtatRecherche etat;
  final ContexteRecherche contexte;
  final bool guide;
  final ValueChanged<ResultatRecherche> onOuvrir;
  final VoidCallback onModifier;
  final VoidCallback onReessayer;
  final ValueChanged<DomaineRecherche> onReessayerDomaine;
  final ValueChanged<DomaineRecherche> onPlus;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.recherche.etats;
    switch (etat.phase) {
      case PhaseRecherche.inactif:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              guide
                  ? t.recherche.guide.initial.titre
                  : t.recherche.initial.titre,
              style: textes.titleMedium,
            ),
            Ecart.vSm,
            Text(
              guide
                  ? t.recherche.guide.initial.phrase
                  : t.recherche.initial.phrase,
              style: textes.bodyMedium,
            ),
          ],
        );
      case PhaseRecherche.saisie:
        return Text(t.recherche.courte, style: textes.bodyMedium);
      case PhaseRecherche.attente:
        // Le delai de saisie : rien ne clignote, les anciens resultats sont
        // deja retires.
        return const SizedBox.shrink();
      case PhaseRecherche.chargement:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                etat.lent ? t.recherche.lent : t.recherche.chargement,
                style: textes.bodyMedium,
              ),
            ),
            Ecart.vLg,
            const Skeleton.liste(),
          ],
        );
      case PhaseRecherche.resultats:
      case PhaseRecherche.partiels:
        return _Resultats(
          etat: etat,
          onOuvrir: onOuvrir,
          onReessayerDomaine: onReessayerDomaine,
          onPlus: onPlus,
          espace: contexte.espace,
          guide: guide,
        );
      case PhaseRecherche.vide:
        return EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: e.vide.titre,
          phrase: e.vide.phrase,
          libelleAction: e.vide.action,
          onAction: onModifier,
        );
      case PhaseRecherche.erreur:
        return EtatSysteme(
          nature: NatureEtat.echecServeur,
          titre: e.erreur.titre,
          phrase: e.erreur.phrase,
          onAction: onReessayer,
        );
      case PhaseRecherche.delai:
        return EtatSysteme(
          nature: NatureEtat.chargementProlonge,
          titre: e.delai.titre,
          phrase: e.delai.phrase,
          onAction: onReessayer,
        );
      case PhaseRecherche.horsLigne:
        // Hors ligne se dit UNE fois (K-42) : le bandeau de la page porte le
        // fait ; ce bloc dit ce qui manque et propose de relire.
        return EtatSysteme(
          nature: NatureEtat.horsLigne,
          titre: e.horsLigne.titre,
          phrase: e.horsLigne.phrase,
          onAction: onReessayer,
        );
      case PhaseRecherche.nonAutorise:
        return EtatSysteme(
          nature: NatureEtat.indisponible,
          titre: e.nonRaccorde.titre,
          phrase: e.nonRaccorde.phrase,
          libelleAction: e.nonRaccorde.action,
          onAction: onRetour,
        );
      case PhaseRecherche.sessionExpiree:
        return EtatSysteme(
          nature: NatureEtat.sessionExpiree,
          titre: e.sessionExpiree.titre,
          phrase: e.sessionExpiree.phrase,
          onAction: () => GoRouter.of(context).go(Routes.connexion),
        );
    }
  }
}

class _Resultats extends StatelessWidget {
  const _Resultats({
    required this.etat,
    required this.espace,
    required this.guide,
    required this.onOuvrir,
    required this.onReessayerDomaine,
    required this.onPlus,
  });

  final EtatRecherche etat;
  final EspaceRecherche espace;
  final bool guide;
  final ValueChanged<ResultatRecherche> onOuvrir;
  final ValueChanged<DomaineRecherche> onReessayerDomaine;
  final ValueChanged<DomaineRecherche> onPlus;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final List<EtatDomaine> avecElements = etat.avecElements.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (avecElements.isNotEmpty) ...<Widget>[
          Semantics(
            liveRegion: true,
            label: t.recherche.categoriesAffichees(nombre: avecElements.length),
            child: Text(
              t.recherche.resultatsPour(requete: etat.texte),
              style: textes.titleMedium,
            ),
          ),
          Ecart.vLg,
        ],
        _Sections(
          blocs: <Widget>[
            for (final EtatDomaine d in etat.domaines)
              if (d.elements.isNotEmpty)
                _Section(
                  domaine: d,
                  espace: espace,
                  onOuvrir: onOuvrir,
                  onPlus: onPlus,
                )
              else if (d.avancement == AvancementDomaine.enEchec)
                EtatSysteme(
                  nature: NatureEtat.echecServeur,
                  titre: t.recherche.etats.domaineIndisponible.titre,
                  phrase: t.recherche.etats.domaineIndisponible.phrase,
                  libelleAction: t.recherche.etats.domaineIndisponible.action,
                  onAction: () => onReessayerDomaine(d.domaine),
                ),
          ],
        ),
        if (etat.lent) ...<Widget>[
          Ecart.vSm,
          Text(t.recherche.lent, style: textes.bodySmall),
        ],
        Ecart.vLg,
        Text(
          guide ? t.recherche.guide.limite : t.recherche.limite,
          style: textes.bodySmall,
        ),
      ],
    );
  }
}

/// Les sections de resultats : une colonne sur mobile ou a texte agrandi, deux
/// colonnes quand la place le permet (`AppGabarit.choixEnColonnes`), jamais
/// de colonnes ecrasees (spec §4.3, §4.4).
class _Sections extends StatelessWidget {
  const _Sections({required this.blocs});

  final List<Widget> blocs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool colonnes =
            blocs.length > 1 &&
            AppGabarit.choixEnColonnes(
              c.maxWidth,
              MediaQuery.textScalerOf(context),
            );
        if (!colonnes) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final Widget b in blocs) ...<Widget>[b, Ecart.vLg],
            ],
          );
        }
        // Un bloc sur deux dans chaque colonne, l'ordre de lecture gardé.
        final List<Widget> gauche = <Widget>[
          for (int i = 0; i < blocs.length; i += 2) ...<Widget>[
            blocs[i],
            Ecart.vLg,
          ],
        ];
        final List<Widget> droite = <Widget>[
          for (int i = 1; i < blocs.length; i += 2) ...<Widget>[
            blocs[i],
            Ecart.vLg,
          ],
        ];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: gauche,
              ),
            ),
            Ecart.hXl,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: droite,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.domaine,
    required this.espace,
    required this.onOuvrir,
    required this.onPlus,
  });

  final EtatDomaine domaine;
  final EspaceRecherche espace;
  final ValueChanged<ResultatRecherche> onOuvrir;
  final ValueChanged<DomaineRecherche> onPlus;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: libelleDomaineRecherche(domaine.domaine)),
        Ecart.vSm,
        CarteLignes(
          lignes: <Widget>[
            for (final ResultatRecherche r in domaine.elements)
              SettingRow(
                title: r.titre,
                description: r.contexte,
                icon: iconeResultat(r.type),
                // Un resultat sans route reelle n'est pas un bouton : aucun
                // geste, aucun chevron, jamais « vers le neant ».
                onPress: cheminPourCible(r.cible, espace) == null
                    ? null
                    : () => onOuvrir(r),
              ),
          ],
        ),
        if (domaine.pageEnCours) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(t.recherche.pageSuivante, style: textes.bodySmall),
          ),
        ] else if (domaine.pageEnEchec) ...<Widget>[
          Ecart.vSm,
          Text(t.recherche.pageEnEchec, style: textes.bodySmall),
        ],
        if (domaine.aPlus && !domaine.pageEnCours)
          LienFleche(
            libelle: t.recherche.voirDavantage,
            libelleSemantique:
                '${t.recherche.voirDavantage}, '
                '${libelleDomaineRecherche(domaine.domaine)}',
            onPress: () => onPlus(domaine.domaine),
            alignerEnFin: true,
          ),
      ],
    );
  }
}

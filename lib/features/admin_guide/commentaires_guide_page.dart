import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import 'port_commentaires_guide.dart';

/// GUIDE-COMMENTAIRES (directeur, 21/11/2026 : « il faut ouvrir la page des
/// commentaires cote admin ») : la direction lit les commentaires du guide de
/// l'enseignant, partie par partie, les moins claires d'abord, et repond dans
/// le fil de chaque lecteur. Circuit a part, hors de la messagerie
/// (directeur, 21/11/2026).
class CommentairesGuidePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CommentairesGuidePage({super.key});

  /// A partir de cette largeur de contenu, deux colonnes de cartes.
  static const double largeurDeuxColonnes = 960;

  /// Fils montres d'abord dans une partie ; les autres a la demande.
  static const int filsVisibles = 3;

  /// La cle du choix « en attente » / « toutes les parties ».
  static const ValueKey<String> cleFiltre = ValueKey<String>(
    'guide-com-filtre',
  );

  /// La cle de la carte d'une partie.
  static ValueKey<String> clePartie(String code) =>
      ValueKey<String>('guide-com-partie-$code');

  /// La cle du lien qui montre les autres fils de [code].
  static ValueKey<String> cleAutresFils(String code) =>
      ValueKey<String>('guide-com-autres-$code');

  /// La cle du lien qui deplie le fil de [lecteur] sur [code].
  static ValueKey<String> cleVoirFil(String code, String lecteur) =>
      ValueKey<String>('guide-com-voir-$code-$lecteur');

  /// La cle du champ de reponse au fil de [lecteur] sur [code].
  static ValueKey<String> cleChamp(String code, String lecteur) =>
      ValueKey<String>('guide-com-champ-$code-$lecteur');

  /// La cle du bouton « Repondre » du fil de [lecteur] sur [code].
  static ValueKey<String> cleRepondre(String code, String lecteur) =>
      ValueKey<String>('guide-com-repondre-$code-$lecteur');

  @override
  ConsumerState<CommentairesGuidePage> createState() => _EtatPage();
}

/// Ce que la page montre : les fils qui attendent la direction, ou tout.
enum FiltreFilsGuide {
  /// Les seuls fils dont le dernier message est d'un lecteur.
  attente,

  /// Toutes les parties et tous les fils.
  tous,
}

class _EtatPage extends ConsumerState<CommentairesGuidePage> {
  /// Choisi par la personne ; nul tant qu'elle n'a rien choisi (on part
  /// alors de « en attente » s'il y a un fil qui attend, sinon de tout).
  FiltreFilsGuide? _filtre;

  @override
  Widget build(BuildContext context) {
    final l = t.admin.guideCommentaires;
    final AsyncValue<List<PartieGuideDirection>> lu = ref.watch(
      commentairesGuideProvider,
    );
    final List<SousLien> pages = pagesOperations();
    final Widget corps;
    if (lu.hasValue) {
      final List<PartieGuideDirection> parties = lu.requireValue;
      final int enAttente = <FilGuide>[
        for (final PartieGuideDirection p in parties) ...p.fils,
      ].where((FilGuide f) => f.attendReponse).length;
      final FiltreFilsGuide filtre =
          _filtre ??
          (enAttente > 0 ? FiltreFilsGuide.attente : FiltreFilsGuide.tous);
      // GUIDE-COMMENTAIRES-PILE (directeur, 21/11/2026 : « tu as omis de
      // penser a ce qui se passe quand les commentaires s'accumulent ») : en
      // attente d'abord, les parties sans fil qui attend disparaissent de
      // cette vue.
      final List<PartieGuideDirection> montrees = filtre == FiltreFilsGuide.tous
          ? parties
          : <PartieGuideDirection>[
              for (final PartieGuideDirection p in parties)
                if (p.fils.any((FilGuide f) => f.attendReponse))
                  PartieGuideDirection(
                    code: p.code,
                    titre: p.titre,
                    jaime: p.jaime,
                    pasClair: p.pasClair,
                    fils: <FilGuide>[
                      for (final FilGuide f in p.fils)
                        if (f.attendReponse) f,
                    ],
                  ),
            ];
      final Widget selecteur = SelecteurSection<FiltreFilsGuide>(
        key: CommentairesGuidePage.cleFiltre,
        libelle: l.filtres,
        valeur: filtre,
        onChange: (FiltreFilsGuide f) => setState(() => _filtre = f),
        sections: <Segment<FiltreFilsGuide>>[
          Segment<FiltreFilsGuide>(
            valeur: FiltreFilsGuide.attente,
            libelle: l.filtreAttente(n: enAttente),
          ),
          Segment<FiltreFilsGuide>(
            valeur: FiltreFilsGuide.tous,
            libelle: l.filtreTous(n: parties.length),
          ),
        ],
      );
      // Sur ordinateur, jamais une carte de telephone etiree sur toute la
      // largeur (directeur, 21/11/2026) : deux colonnes, dans l'ordre de
      // lecture, ligne par ligne ; au telephone, une seule.
      final Widget cartesOuVide = montrees.isEmpty
          ? EmptyState(message: l.aucunEnAttente, icone: AppIcons.succes)
          : LayoutBuilder(
              builder: (BuildContext _, BoxConstraints c) {
                final List<Widget> cartes = <Widget>[
                  for (final PartieGuideDirection p in montrees)
                    _CartePartie(
                      key: CommentairesGuidePage.clePartie(p.code),
                      partie: p,
                    ),
                ];
                if (c.maxWidth < CommentairesGuidePage.largeurDeuxColonnes) {
                  return PileCartes(children: cartes);
                }
                return PileCartes(
                  children: <Widget>[
                    for (int i = 0; i < cartes.length; i += 2)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: cartes[i]),
                          Ecart.hLg,
                          Expanded(
                            child: i + 1 < cartes.length
                                ? cartes[i + 1]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                  ],
                );
              },
            );
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppPage.largeurLecture,
              ),
              child: selecteur,
            ),
          ),
          Ecart.vLg,
          cartesOuVide,
        ],
      );
    } else if (lu.hasError) {
      corps = EmptyState(
        message: lu.error is CapaciteIndisponible ? l.indisponible : l.erreur,
        icone: AppIcons.avertissement,
        libelleAction: lu.error is CapaciteIndisponible
            ? null
            : t.commun.reessayer,
        onAction: lu.error is CapaciteIndisponible
            ? null
            : () => ref.invalidate(commentairesGuideProvider),
      );
    } else {
      corps = const Skeleton.liste(lignes: 4);
    }
    return PageShell(
      titre: l.titre,
      entete: SousNavigationDomaine(
        onglets: pages,
        indexActif: pages.indexWhere(
          (SousLien o) => o.chemin == Routes.adminOperationsGuide,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppPage.largeurLecture,
              ),
              child: Text(
                l.intro,
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
          Ecart.vLg,
          corps,
        ],
      ),
    );
  }
}

class _CartePartie extends StatefulWidget {
  const _CartePartie({required this.partie, super.key});

  final PartieGuideDirection partie;

  @override
  State<_CartePartie> createState() => _EtatCartePartie();
}

class _EtatCartePartie extends State<_CartePartie> {
  bool _tous = false;

  @override
  Widget build(BuildContext context) {
    final l = t.admin.guideCommentaires;
    final PartieGuideDirection partie = widget.partie;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final int rang = int.tryParse(partie.code.substring(1)) ?? 0;
    const int max = CommentairesGuidePage.filsVisibles;
    final List<FilGuide> fils = _tous || partie.fils.length <= max
        ? partie.fils
        : partie.fils.take(max).toList();
    final int caches = partie.fils.length - max;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('$rang. ${partie.titre}', style: textes.titleMedium),
          Ecart.vXs,
          Text(
            l.totaux(jaime: partie.jaime, pasClair: partie.pasClair),
            style: muet,
          ),
          Ecart.vLg,
          if (partie.fils.isEmpty)
            Text(l.aucun, style: muet)
          else ...<Widget>[
            for (int i = 0; i < fils.length; i++) ...<Widget>[
              if (i > 0) ...<Widget>[Ecart.vMd, const FiletCarte(), Ecart.vMd],
              _Fil(code: partie.code, fil: fils[i]),
            ],
            if (caches > 0) ...<Widget>[
              Ecart.vSm,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: LienFleche(
                  key: CommentairesGuidePage.cleAutresFils(partie.code),
                  libelle: _tous ? l.replierFils : l.autresFils(n: caches),
                  alignerEnDebut: true,
                  onPress: () => setState(() => _tous = !_tous),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Fil extends ConsumerStatefulWidget {
  const _Fil({required this.code, required this.fil});

  final String code;
  final FilGuide fil;

  @override
  ConsumerState<_Fil> createState() => _EtatFil();
}

class _EtatFil extends ConsumerState<_Fil> {
  final TextEditingController _texte = TextEditingController();
  bool _deplie = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _repondre() async {
    final String corps = _texte.text.trim();
    if (corps.isEmpty || _envoi || widget.fil.messages.isEmpty) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portCommentairesGuideProvider)
          .repondre(commentaire: widget.fil.messages.last.id, corps: corps);
      if (!mounted) return;
      _texte.clear();
      ref.invalidate(commentairesGuideProvider);
      setState(() => _envoi = false);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = t.admin.guideCommentaires.echec;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.guideCommentaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    String auteur(AuteurMessageGuide a) => switch (a) {
      AuteurMessageGuide.lecteur => widget.fil.lecteur,
      AuteurMessageGuide.direction => l.direction,
      AuteurMessageGuide.praxis => l.praxis,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(widget.fil.lecteur, style: textes.titleSmall)),
            if (widget.fil.attendReponse)
              StatusPill(libelle: l.attend, ton: TonEtat.avertissement),
          ],
        ),
        Ecart.vSm,
        // Replie : le seul dernier message, sur trois lignes au plus ; deplie :
        // toute la conversation (GUIDE-COMMENTAIRES-PILE).
        for (final MessageGuide m
            in _deplie
                ? widget.fil.messages
                : widget.fil.messages.skip(
                    widget.fil.messages.length > 1
                        ? widget.fil.messages.length - 1
                        : 0,
                  )) ...<Widget>[
          // Le nom du lecteur est deja en tete du fil : seules les reponses
          // de la direction et de Praxis portent leur auteur.
          if (m.auteur != AuteurMessageGuide.lecteur)
            Text(auteur(m.auteur), style: muet),
          Text(
            m.corps,
            style: textes.bodyMedium,
            maxLines: _deplie ? null : 3,
            overflow: _deplie ? null : TextOverflow.ellipsis,
          ),
          Ecart.vSm,
        ],
        if (widget.fil.messages.length > 1 ||
            widget.fil.messages.any((MessageGuide m) => m.corps.length > 180))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: CommentairesGuidePage.cleVoirFil(
                widget.code,
                widget.fil.lecteur,
              ),
              libelle: _deplie
                  ? l.replierFil
                  : l.voirFil(n: widget.fil.messages.length),
              alignerEnDebut: true,
              onPress: () => setState(() => _deplie = !_deplie),
            ),
          ),
        if (_deplie || widget.fil.attendReponse)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: ZoneSaisie(
                  controleur: _texte,
                  cleChamp: CommentairesGuidePage.cleChamp(
                    widget.code,
                    widget.fil.lecteur,
                  ),
                  libelle: l.champ(nom: widget.fil.lecteur),
                  libelleVisible: false,
                  minLignes: 1,
                  maxLignes: 5,
                  erreur: _erreur,
                ),
              ),
              Ecart.hSm,
              Transform.flip(
                flipX: rtl,
                child: BoutonIcone(
                  key: CommentairesGuidePage.cleRepondre(
                    widget.code,
                    widget.fil.lecteur,
                  ),
                  icone: AppIcons.envoyerMessage,
                  libelle: l.repondre,
                  forme: FormeBoutonIcone.disque,
                  onPress: () => unawaited(_repondre()),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

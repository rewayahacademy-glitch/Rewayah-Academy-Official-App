// CAHIER-C2 (06/11/2026, ETUDE-CAHIER-2026-11.md §4.1 et §5) : le contenu
// d'une etape du programme, saisi par la direction.
//
// Ce que la direction decide ici, une fois par version : les objectifs
// observables de l'etape (3 a 5), le livre ou elle se lit et ses pages, la
// duree prevue par tranche d'age et la date limite de l'etape (SOCLE-PROGRAMME,
// 12/11/2026 : une valeur saisie et rendue par le serveur, tableau 1 bis des
// reglages, jamais deduite de la duree prevue ; l'ancienne regle x 1,3 donnait
// 18 au lieu de 19 et rendait la version impubliable). Le serveur
// refuse la publication d'une version dont une etape est incomplete
// (migration 20261110600000) ; l'ecran ne decide rien.
//
// K-57 : deduit (date limite, pages gardees), choisi (livre, duree au pas a
// pas, jamais au clavier), saisi (les objectifs seuls : un texte de la
// direction, rien ne peut le deduire ; les pages, facultatives, parce que le
// livre de lecture n'est pas encore numerote).

import 'package:flutter/material.dart';

import '../../core/admin/service_programme.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/tranche_age.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/choix_nombre.dart';

/// La duree prevue proposee pour une tranche sans valeur : une semaine,
/// le minimum du serveur ; la direction l'ajuste au pas a pas.
const int _dureeParDefaut = 1;

/// Le formulaire du contenu d'une etape ; en lecture seule pour une version
/// publiee ou archivee.
class FeuilleContenuNiveau extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleContenuNiveau({
    required this.niveau,
    required this.modifiable,
    required this.onEnvoyer,
    required this.onSucces,
    super.key,
  });

  /// L'etape.
  final NiveauProgramme niveau;

  /// Faux pour une version publiee ou archivee : tout se lit, rien ne s'ecrit.
  final bool modifiable;

  /// L'ecriture au serveur.
  final Future<void> Function({
    required List<String> objectifs,
    required PlageSupport? plage,
    required Map<String, DureeEtape> durees,
  })
  onEnvoyer;

  /// Apres un enregistrement confirme.
  final VoidCallback onSucces;

  /// La cle du bouton d'enregistrement.
  static const Key enregistrerKey = ValueKey<String>('contenu-enregistrer');

  @override
  State<FeuilleContenuNiveau> createState() => _FeuilleContenuNiveauEtat();
}

class _FeuilleContenuNiveauEtat extends State<FeuilleContenuNiveau> {
  static const int _nombreObjectifs = 5;

  late final List<TextEditingController> _objectifs =
      List<TextEditingController>.generate(
        _nombreObjectifs,
        (int i) => TextEditingController(
          text: i < widget.niveau.objectifs.length
              ? widget.niveau.objectifs[i]
              : '',
        ),
      );
  late SupportEtape? _support = widget.niveau.plage?.support;
  late final TextEditingController _pageDebut = TextEditingController(
    text: widget.niveau.plage?.pageDebut?.toString() ?? '',
  );
  late final TextEditingController _pageFin = TextEditingController(
    text: widget.niveau.plage?.pageFin?.toString() ?? '',
  );
  late final Map<String, int> _prevues = <String, int>{
    for (final String code in tranchesProgramme)
      code: widget.niveau.durees[code]?.prevue ?? _dureeParDefaut,
  };
  // La date limite rendue par le serveur, telle quelle ; sans valeur, la duree
  // prevue (la plus petite date limite admise), que la direction ajuste.
  late final Map<String, int> _limites = <String, int>{
    for (final String code in tranchesProgramme)
      code:
          widget.niveau.durees[code]?.limite ??
          widget.niveau.durees[code]?.prevue ??
          _dureeParDefaut,
  };
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    for (final TextEditingController c in _objectifs) {
      c.dispose();
    }
    _pageDebut.dispose();
    _pageFin.dispose();
    super.dispose();
  }

  /// Un nombre de page lu, `null` si vide ; `-1` si illisible.
  int? _page(TextEditingController c) {
    final String brut = c.text.trim();
    if (brut.isEmpty) return null;
    return int.tryParse(brut) ?? -1;
  }

  Future<void> _envoyer() async {
    final int? debut = _page(_pageDebut);
    final int? fin = _page(_pageFin);
    final bool pagesInvalides =
        (debut != null && debut < 1) ||
        (fin != null && fin < 1) ||
        (debut != null && fin != null && fin < debut);
    if (pagesInvalides) {
      setState(() => _erreur = t.admin.programmes.contenu.manquePages);
      return;
    }
    final SupportEtape? support = _support;
    // Les lignes ne se saisissent pas encore (livre non numerote) : celles
    // qui existent sont gardees telles quelles.
    final PlageSupport? plage = support == null
        ? null
        : PlageSupport(
            support: support,
            pageDebut: debut,
            ligneDebut: widget.niveau.plage?.ligneDebut,
            pageFin: fin,
            ligneFin: widget.niveau.plage?.ligneFin,
          );
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onEnvoyer(
        objectifs: <String>[
          for (final TextEditingController c in _objectifs)
            if (c.text.trim().isNotEmpty) c.text.trim(),
        ],
        plage: plage,
        durees: <String, DureeEtape>{
          for (final MapEntry<String, int> e in _prevues.entries)
            e.key: DureeEtape(
              prevue: e.value,
              limite: (_limites[e.key] ?? e.value) < e.value
                  ? e.value
                  : (_limites[e.key] ?? e.value),
            ),
        },
      );
      widget.onSucces();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (!mounted) return;
      setState(
        () => _erreur = t.admin.programmes.contenu.erreur(
          message: messageMetier(erreur),
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle aide = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool modifiable = widget.modifiable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          modifiable
              ? t.admin.programmes.contenu.intro
              : t.admin.programmes.contenu.lectureSeule,
          style: textes.bodyMedium,
        ),
        if (modifiable) ...<Widget>[
          Ecart.vSm,
          Text(t.admin.programmes.contenu.propositionDetail, style: aide),
        ],
        Ecart.vXl,
        Text(
          t.admin.programmes.contenu.objectifsTitre,
          style: textes.titleSmall,
        ),
        Ecart.vSm,
        if (modifiable) ...<Widget>[
          Text(t.admin.programmes.contenu.objectifsAide, style: aide),
          Ecart.vMd,
          for (int i = 0; i < _nombreObjectifs; i++) ...<Widget>[
            ChampEtiquete(
              key: ValueKey<String>('contenu-objectif-$i'),
              libelle: t.admin.programmes.contenu.objectifNumero(
                numero: '${i + 1}',
              ),
              controller: _objectifs[i],
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (i < _nombreObjectifs - 1) Ecart.vMd,
          ],
        ] else
          for (final String objectif in widget.niveau.objectifs)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: Text(objectif, style: textes.bodyMedium),
            ),
        Ecart.vXl,
        Text(t.admin.programmes.contenu.livreTitre, style: textes.titleSmall),
        Ecart.vSm,
        Text(t.admin.programmes.contenu.livreAide, style: aide),
        Ecart.vMd,
        if (modifiable)
          ChoiceCardGroup(
            key: const ValueKey<String>('contenu-livre'),
            autoriserSaisieLibre: false,
            valeurInitiale: _support == null
                ? null
                : ReponseChoix(valeurs: <String>{_support!.valeurSql}),
            options: <OptionChoix>[
              OptionChoix(
                valeur: SupportEtape.livreRewayah.valeurSql,
                libelle: t.admin.programmes.contenu.livreRewayah,
                description: t.admin.programmes.contenu.livreRewayahDetail,
              ),
              OptionChoix(
                valeur: SupportEtape.mushaf.valeurSql,
                libelle: t.admin.programmes.contenu.mushaf,
                description: t.admin.programmes.contenu.mushafDetail,
              ),
            ],
            onChange: (ReponseChoix r) => setState(() {
              _support = r.valeurs.contains(SupportEtape.mushaf.valeurSql)
                  ? SupportEtape.mushaf
                  : (r.valeurs.isEmpty ? null : SupportEtape.livreRewayah);
            }),
          )
        else
          Text(switch (_support) {
            SupportEtape.mushaf => t.admin.programmes.contenu.mushaf,
            SupportEtape.livreRewayah =>
              t.admin.programmes.contenu.livreRewayah,
            null => t.enseignant.eleve.nonRenseigne,
          }, style: textes.bodyMedium),
        if (modifiable && _support != null) ...<Widget>[
          Ecart.vMd,
          ChampEtiquete(
            key: const ValueKey<String>('contenu-page-debut'),
            libelle: t.admin.programmes.contenu.pageDebut,
            controller: _pageDebut,
            keyboardType: TextInputType.number,
          ),
          Ecart.vMd,
          ChampEtiquete(
            key: const ValueKey<String>('contenu-page-fin'),
            libelle: t.admin.programmes.contenu.pageFin,
            controller: _pageFin,
            keyboardType: TextInputType.number,
          ),
        ],
        Ecart.vXl,
        Text(t.admin.programmes.contenu.dureesTitre, style: textes.titleSmall),
        Ecart.vSm,
        Text(t.admin.programmes.contenu.dureesAide, style: aide),
        Ecart.vMd,
        for (final String code in tranchesProgramme)
          if (modifiable || widget.niveau.durees[code] != null) ...<Widget>[
            if (modifiable)
              ChoixNombre(
                key: ValueKey<String>('contenu-duree-$code'),
                libelle: t.admin.programmes.contenu.dureeTranche(
                  tranche: libelleTranche(code),
                ),
                valeur: _prevues[code] ?? _dureeParDefaut,
                min: 1,
                max: 260,
                libelleMoins: t.admin.programmes.contenu.dureeMoins(
                  tranche: libelleTranche(code),
                ),
                libellePlus: t.admin.programmes.contenu.dureePlus(
                  tranche: libelleTranche(code),
                ),
                onChange: (int v) => setState(() {
                  _prevues[code] = v;
                  if ((_limites[code] ?? v) < v) _limites[code] = v;
                }),
              )
            else
              Text(
                LibellesGroupe.insecable(
                  t.admin.programmes.contenu.dureeLecture(
                    tranche: libelleTranche(code),
                    prevue: '${widget.niveau.durees[code]?.prevue}',
                  ),
                ),
                style: textes.bodyMedium,
              ),
            Ecart.vSm,
            if (modifiable)
              ChoixNombre(
                key: ValueKey<String>('contenu-limite-$code'),
                libelle: t.admin.programmes.contenu.limiteTranche(
                  tranche: libelleTranche(code),
                ),
                valeur: _limites[code] ?? _prevues[code] ?? _dureeParDefaut,
                min: _prevues[code] ?? 1,
                max: 520,
                libelleMoins: t.admin.programmes.contenu.limiteMoins(
                  tranche: libelleTranche(code),
                ),
                libellePlus: t.admin.programmes.contenu.limitePlus(
                  tranche: libelleTranche(code),
                ),
                onChange: (int v) => setState(() => _limites[code] = v),
              )
            else
              Text(
                LibellesGroupe.insecable(
                  t.admin.programmes.contenu.dateLimite(
                    semaines: '${widget.niveau.durees[code]?.limite}',
                  ),
                ),
                style: aide,
              ),
            Ecart.vLg,
          ],
        if (_erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vMd,
        ],
        if (modifiable)
          ActionPrincipale(
            key: FeuilleContenuNiveau.enregistrerKey,
            libelle: t.admin.programmes.contenu.enregistrer,
            enCours: _envoi,
            onPress: _envoyer,
          ),
      ],
    );
  }
}

/// Le message metier d'une erreur du serveur, sans son enveloppe.
String messageMetier(Object erreur) {
  final String brut = erreur.toString();
  const String marque = 'message: ';
  final int debut = brut.indexOf(marque);
  if (debut >= 0) {
    final int fin = brut.indexOf(', code:', debut);
    return brut.substring(debut + marque.length, fin < 0 ? null : fin);
  }
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

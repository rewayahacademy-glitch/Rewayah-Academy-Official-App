// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : la feuille de saisie d'une date du
// calendrier (ajouter, modifier). Le serveur valide (maximum du Ramadan et de
// l'Aid, dates, portee) ; la feuille dit ce qui manque et les refus.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_groupes.dart';
import '../../core/admin/service_programme.dart' show tranchesProgramme;
import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/tranche_age.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';

// ---------------------------------------------------------------------------

/// Ouvre la saisie d'une date ([source] nul : une nouvelle).
void ouvrirSaisieDate(
  BuildContext context,
  WidgetRef ref,
  EvenementCalendrier? source,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: source == null
        ? t.calendrier.dates.feuille.titreAjout
        : t.calendrier.dates.feuille.titreModif,
    constructeur: (BuildContext contexte) => _FeuilleSaisie(source: source),
  );
}

class _FeuilleSaisie extends ConsumerStatefulWidget {
  const _FeuilleSaisie({required this.source});

  final EvenementCalendrier? source;

  @override
  ConsumerState<_FeuilleSaisie> createState() => _FeuilleSaisieEtat();
}

class _FeuilleSaisieEtat extends ConsumerState<_FeuilleSaisie> {
  final TextEditingController _titre = TextEditingController();
  TypeEvenement _type = TypeEvenement.fermeture;
  CategorieFermeture _categorie = CategorieFermeture.autre;
  PorteeEvenement _portee = PorteeEvenement.ecole;
  String? _cohorte;
  String? _groupeId;
  DateTime? _du;
  DateTime? _au;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final EvenementCalendrier? s = widget.source;
    if (s != null) {
      _titre.text = s.titre;
      _type = s.type;
      _categorie = s.categorie ?? CategorieFermeture.autre;
      _portee = s.portee;
      _cohorte = s.cohorte;
      _groupeId = s.groupeId;
      _du = s.du;
      _au = s.au;
    }
  }

  @override
  void dispose() {
    _titre.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final PortCalendrierDirection? port = ref.read(
      portCalendrierDirectionProvider,
    );
    if (port == null) return;
    final DateTime? du = _du;
    final DateTime? au = _au;
    String? manque;
    if (_titre.text.trim().isEmpty) {
      manque = messageRefusCalendrier(MotifRefusCalendrier.evenementInvalide);
    } else if (du == null || au == null || au.isBefore(du)) {
      manque = messageRefusCalendrier(MotifRefusCalendrier.datesInvalides);
    } else if ((_portee == PorteeEvenement.tranche && _cohorte == null) ||
        (_portee == PorteeEvenement.classe && _groupeId == null)) {
      manque = messageRefusCalendrier(MotifRefusCalendrier.porteeInvalide);
    }
    if (manque != null) {
      setState(() => _erreur = manque);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await port.enregistrer(
        id: widget.source?.id,
        type: _type,
        categorie: _type == TypeEvenement.fermeture ? _categorie : null,
        titre: _titre.text.trim(),
        du: du!,
        au: au!,
        portee: _portee,
        cohorte: _portee == PorteeEvenement.tranche ? _cohorte : null,
        groupeId: _portee == PorteeEvenement.classe ? _groupeId : null,
      );
      ref.invalidate(calendrierDirectionProvider);
      if (mounted) Navigator.of(context).pop();
    } on CalendrierRefuse catch (r) {
      if (mounted) {
        setState(
          () => _erreur = messageRefusCalendrier(r.motif, enModification: true),
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _erreur = messageRefusCalendrier(MotifRefusCalendrier.inconnu),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = t.calendrier.dates.feuille;
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime aujourdhui = ref.watch(horlogeFormulairesProvider)();
    final AsyncValue<List<GroupeAdmin>> groupes = ref.watch(groupesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ChoiceCardGroup(
          key: ValueKey<String>('type-${_type.valeurSql}'),
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_type.valeurSql}),
          options: <OptionChoix>[
            for (final TypeEvenement ty in TypeEvenement.values)
              OptionChoix(valeur: ty.valeurSql, libelle: libelleType(ty)),
          ],
          onChange: (ReponseChoix r) {
            final TypeEvenement? choisi = TypeEvenement.depuisSql(
              r.valeurs.isEmpty ? null : r.valeurs.first,
            );
            if (choisi != null && choisi != _type) {
              setState(() => _type = choisi);
            }
          },
        ),
        if (_type == TypeEvenement.fermeture) ...<Widget>[
          Ecart.vLg,
          Text(f.champCategorie, style: textes.titleSmall),
          Ecart.vSm,
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            valeurInitiale: ReponseChoix(
              valeurs: <String>{_categorie.valeurSql},
            ),
            options: <OptionChoix>[
              for (final CategorieFermeture c in CategorieFermeture.values)
                OptionChoix(valeur: c.valeurSql, libelle: libelleCategorie(c)),
            ],
            onChange: (ReponseChoix r) {
              final CategorieFermeture? choisie = CategorieFermeture.depuisSql(
                r.valeurs.isEmpty ? null : r.valeurs.first,
              );
              if (choisie != null) setState(() => _categorie = choisie);
            },
          ),
          Ecart.vSm,
          Text(t.calendrier.dates.categorieAide, style: textes.bodySmall),
        ],
        Ecart.vLg,
        ChampEtiquete(
          libelle: f.champTitre,
          controller: _titre,
          aide: f.aideTitre,
          obligatoire: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String _) {
            if (_erreur != null) setState(() => _erreur = null);
          },
        ),
        Ecart.vLg,
        ChampDate(
          libelle: f.champDu,
          valeur: _du,
          aujourdhui: aujourdhui,
          aide: f.aideDates,
          onChoix: (DateTime jour) => setState(() {
            _du = jour;
            if (_au != null && _au!.isBefore(jour)) _au = jour;
            _erreur = null;
          }),
        ),
        Ecart.vLg,
        ChampDate(
          libelle: f.champAu,
          valeur: _au,
          aujourdhui: _du ?? aujourdhui,
          dernier: (_du ?? aujourdhui).add(const Duration(days: 365)),
          onChoix: (DateTime jour) => setState(() {
            _au = jour;
            _erreur = null;
          }),
        ),
        Ecart.vLg,
        Text(f.champPortee, style: textes.titleSmall),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_portee.valeurSql}),
          options: <OptionChoix>[
            OptionChoix(
              valeur: PorteeEvenement.ecole.valeurSql,
              libelle: t.calendrier.dates.portee.ecole,
            ),
            OptionChoix(
              valeur: PorteeEvenement.tranche.valeurSql,
              libelle: t.calendrier.dates.portee.tranche,
            ),
            OptionChoix(
              valeur: PorteeEvenement.classe.valeurSql,
              libelle: t.calendrier.dates.portee.classe,
            ),
          ],
          onChange: (ReponseChoix r) {
            final PorteeEvenement? choisie = PorteeEvenement.depuisSql(
              r.valeurs.isEmpty ? null : r.valeurs.first,
            );
            if (choisie != null && choisie != _portee) {
              setState(() => _portee = choisie);
            }
          },
        ),
        if (_portee == PorteeEvenement.tranche) ...<Widget>[
          Ecart.vLg,
          Text(f.champTranche, style: textes.titleSmall),
          Ecart.vSm,
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            valeurInitiale: _cohorte == null
                ? null
                : ReponseChoix(valeurs: <String>{_cohorte!}),
            options: <OptionChoix>[
              for (final String c in tranchesProgramme)
                OptionChoix(valeur: c, libelle: libelleTranche(c)),
            ],
            onChange: (ReponseChoix r) => setState(
              () => _cohorte = r.valeurs.isEmpty ? null : r.valeurs.first,
            ),
          ),
        ],
        if (_portee == PorteeEvenement.classe) ...<Widget>[
          Ecart.vLg,
          Text(f.champClasse, style: textes.titleSmall),
          Ecart.vSm,
          if (groupes.value case final List<GroupeAdmin> l when l.isNotEmpty)
            ChoiceCardGroup(
              autoriserSaisieLibre: false,
              valeurInitiale: _groupeId == null
                  ? null
                  : ReponseChoix(valeurs: <String>{_groupeId!}),
              options: <OptionChoix>[
                for (final GroupeAdmin g in l.where((GroupeAdmin g) => g.actif))
                  OptionChoix(valeur: g.id, libelle: g.libelle),
              ],
              onChange: (ReponseChoix r) => setState(
                () => _groupeId = r.valeurs.isEmpty ? null : r.valeurs.first,
              ),
            )
          else
            Text(f.aucuneClasse, style: textes.bodyMedium),
        ],
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: const ValueKey<String>('calendrier-enregistrer'),
          libelle: f.enregistrer,
          enCours: _envoi,
          onPress: _enregistrer,
        ),
      ],
    );
  }
}

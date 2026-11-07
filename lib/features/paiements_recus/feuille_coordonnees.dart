// La feuille « Mes coordonnees de versement » (lot FINANCE-ENSEIGNANT,
// 06/11/2026) : l'enseignant saisit les champs que le modele Wise demande
// (`champs`, rendus par le serveur), ni plus ni moins. Modele du directeur du
// 06/11 : nom du titulaire, numero de compte ou IBAN, code SWIFT, pays, ville,
// adresse ; l'Etat seulement aux Etats-Unis et au Canada ; code postal
// facultatif.
//
// K-57 : deduit (la devise, rendue par le serveur ; le pays, quand le profil
// porte un code a deux lettres ; les textes deja enregistres, sauf les numeros,
// que le serveur ne rend que masques), choisi (le pays, dans la liste des
// pays), saisi (titulaire, numero, SWIFT, ville, adresse : seule la banque de
// l'enseignant les connait).
//
// Le serveur juge en dernier ; la feuille ne fait que signaler un champ vide
// ou un caractere qui casserait le fichier.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_coordonnees_versement.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import '../../core/widgets/texte_protege.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;
import 'etat_coordonnees.dart';

/// Ouvre la feuille ; rend l'etat enregistre, ou `null` si la personne
/// renonce.
Future<MesCoordonneesVersement?> ouvrirFeuilleCoordonnees(
  BuildContext context,
  MesCoordonneesVersement actuel,
) {
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  return AppBottomSheet.ouvrir<MesCoordonneesVersement>(
    context,
    titre: t.comptable.beneficiaires.recevoir.wise.formTitre,
    constructeur: (BuildContext feuille) => UncontrolledProviderScope(
      container: portee,
      child: TexteProtege(child: FeuilleCoordonnees(actuel: actuel)),
    ),
  );
}

/// Le contenu de la feuille.
class FeuilleCoordonnees extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleCoordonnees({required this.actuel, super.key});

  /// L'etat actuel, rendu par le serveur.
  final MesCoordonneesVersement actuel;

  /// La cle du champ [c].
  static Key cleChamp(ChampVersement c) =>
      ValueKey<String>('coordonnees-${c.code}');

  /// La cle du bouton d'enregistrement.
  static const Key cleEnregistrer = ValueKey<String>('coordonnees-enregistrer');

  /// La cle du message d'echec.
  static const Key cleEchec = ValueKey<String>('coordonnees-echec');

  /// La cle de l'option « a mon nom » ([oui]) ou non.
  static Key cleAMonNom({required bool oui}) =>
      ValueKey<String>('coordonnees-a-mon-nom-$oui');

  /// La cle de l'option d'un lien avec le titulaire.
  static Key cleLien(LienTitulaire l) =>
      ValueKey<String>('coordonnees-lien-${l.code}');

  /// La cle de la case d'accord.
  static const Key cleAccord = ValueKey<String>('coordonnees-accord');

  /// La cle d'un pays dans la liste.
  static Key clePays(String code) => ValueKey<String>('coordonnees-pays-$code');

  @override
  ConsumerState<FeuilleCoordonnees> createState() => _FeuilleCoordonneesEtat();
}

/// Les numeros : jamais preremplis, le serveur ne les rend que masques.
const Set<ChampVersement> _numeros = <ChampVersement>{
  ChampVersement.numeroCompte,
  ChampVersement.iban,
  ChampVersement.swift,
};

class _FeuilleCoordonneesEtat extends ConsumerState<FeuilleCoordonnees> {
  late final Map<ChampVersement, TextEditingController> _champs =
      <ChampVersement, TextEditingController>{
        for (final ChampDemande c in widget.actuel.champs)
          if (c.champ != ChampVersement.adressePays)
            c.champ: TextEditingController(text: _initial(c.champ)),
      };
  late String? _pays = _paysInitial();
  // Jamais precoche : un compte a un autre nom se redit a chaque changement.
  late bool _aMonNom = widget.actuel.compteAMonNom;
  late LienTitulaire? _lien = widget.actuel.lienTitulaire;
  bool _accord = false;
  String? _erreurLien;
  String? _erreurAccord;
  final Map<ChampVersement, String> _erreurs = <ChampVersement, String>{};
  bool _enCours = false;
  bool _echec = false;

  String? _paysInitial() {
    final String? deja = widget.actuel.valeurs[ChampVersement.adressePays];
    if (deja != null) return deja;
    final String? profil = widget.actuel.paysProfil;
    return profil != null && paysDuCode(profil) != null
        ? profil.toUpperCase()
        : null;
  }

  String _initial(ChampVersement c) {
    if (_numeros.contains(c)) return '';
    return widget.actuel.valeurs[c] ?? '';
  }

  /// Les champs demandes pour le pays choisi.
  List<ChampDemande> get _demandes => <ChampDemande>[
    for (final ChampDemande c in widget.actuel.champs)
      if (c.demandePour(_pays)) c,
  ];

  @override
  void dispose() {
    for (final TextEditingController c in _champs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirPays() async {
    final String? code = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.avis.form.pays.choisir,
      constructeur: (BuildContext contexte) =>
          _ListePays(onChoix: (String c) => Navigator.of(contexte).pop(c)),
    );
    if (code == null || !mounted) return;
    setState(() {
      _pays = code;
      _erreurs.remove(ChampVersement.adressePays);
    });
  }

  Future<void> _enregistrer() async {
    if (_enCours) return;
    final w = t.comptable.beneficiaires.recevoir.wise;
    final Map<ChampVersement, String> erreurs = <ChampVersement, String>{};
    final Map<ChampVersement, String> valeurs = <ChampVersement, String>{};
    for (final ChampDemande d in _demandes) {
      final String v = d.champ == ChampVersement.adressePays
          ? (_pays ?? '')
          : _champs[d.champ]!.text.trim();
      if (v.isEmpty) {
        if (d.obligatoire) erreurs[d.champ] = w.champRequis;
      } else if (caracteresInterditsVersement.hasMatch(v)) {
        erreurs[d.champ] = w.caracteresInterdits;
      } else {
        valeurs[d.champ] = v;
      }
    }
    final String? erreurLien = !_aMonNom && _lien == null ? w.lienRequis : null;
    final String? erreurAccord = !_aMonNom && !_accord
        ? w.autorisationRequise
        : null;
    setState(() {
      _erreurs
        ..clear()
        ..addAll(erreurs);
      _erreurLien = erreurLien;
      _erreurAccord = erreurAccord;
      _echec = false;
    });
    if (erreurs.isNotEmpty || erreurLien != null || erreurAccord != null) {
      return;
    }
    setState(() => _enCours = true);
    try {
      final MesCoordonneesVersement apres = await ref
          .read(portCoordonneesVersementProvider)
          .enregistrer(
            deviseCible: widget.actuel.deviseCible,
            valeurs: valeurs,
            compteAMonNom: _aMonNom,
            lien: _lien,
            autorisation: _accord,
          );
      if (!mounted) return;
      Navigator.of(context).pop(apres);
    } on PaysVersementIndisponible {
      if (!mounted) return;
      setState(() {
        _erreurs[ChampVersement.adressePays] = w.paysIndisponible(
          pays: nomDuPays(_pays ?? ''),
        );
        _enCours = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _echec = true;
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = t.comptable.beneficiaires.recevoir.wise;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final String devise = widget.actuel.deviseCible;
    final String? pays = _pays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(w.formIntro(devise: devise), style: attenue),
        if (devise == 'USD') ...<Widget>[
          Ecart.vSm,
          Text(w.formUsdAide, style: attenue),
        ],
        Ecart.vLg,
        for (final ChampDemande d in _demandes) ...<Widget>[
          if (d.champ == ChampVersement.adressePays)
            Column(
              key: FeuilleCoordonnees.cleChamp(d.champ),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarteLignes(
                  lignes: <Widget>[
                    SettingRow(
                      title: libelleChampVersement(d.champ),
                      value: pays == null
                          ? t.avis.form.pays.choisir
                          : nomDuPays(pays),
                      lien: true,
                      onPress: () => unawaited(_choisirPays()),
                    ),
                  ],
                ),
                Ecart.vXs,
                Text(
                  _erreurs[d.champ] ?? aideChampVersement(d.champ),
                  style:
                      (_erreurs.containsKey(d.champ)
                              ? palette.inkAlert
                              : palette.inkMuted)
                          .applyTo(
                            Theme.of(context).textTheme.bodySmall ??
                                const TextStyle(),
                          ),
                ),
              ],
            )
          else
            ChampEtiquete(
              key: FeuilleCoordonnees.cleChamp(d.champ),
              libelle: libelleChampVersement(d.champ),
              controller: _champs[d.champ]!,
              obligatoire: d.obligatoire,
              textCapitalization:
                  d.champ == ChampVersement.swift ||
                      d.champ == ChampVersement.iban ||
                      d.champ == ChampVersement.adresseEtat
                  ? TextCapitalization.characters
                  : TextCapitalization.none,
              aide: _erreurs[d.champ] ?? aideChampVersement(d.champ),
              onChanged: (String _) {
                if (_erreurs.containsKey(d.champ)) {
                  setState(() => _erreurs.remove(d.champ));
                }
              },
            ),
          Ecart.vLg,
        ],
        // Le compte : a mon nom, ou a celui d'un proche (directeur, 06/11).
        Text(
          w.aMonNomQuestion,
          style: palette.inkStrong.applyTo(
            Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{'$_aMonNom'}),
          options: <OptionChoix>[
            OptionChoix(
              valeur: 'true',
              libelle: w.aMonNomOui,
              cle: FeuilleCoordonnees.cleAMonNom(oui: true),
            ),
            OptionChoix(
              valeur: 'false',
              libelle: w.aMonNomNon,
              description: w.aMonNomNonDetail,
              cle: FeuilleCoordonnees.cleAMonNom(oui: false),
            ),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.isEmpty) return;
            setState(() {
              _aMonNom = r.valeurs.first == 'true';
              _accord = false;
            });
          },
        ),
        if (!_aMonNom) ...<Widget>[
          Ecart.vLg,
          Text(
            w.lienQuestion,
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            valeurInitiale: _lien == null
                ? null
                : ReponseChoix(valeurs: <String>{_lien!.code}),
            options: <OptionChoix>[
              for (final LienTitulaire l in LienTitulaire.values)
                OptionChoix(
                  valeur: l.code,
                  libelle: libelleLienTitulaire(l),
                  cle: FeuilleCoordonnees.cleLien(l),
                ),
            ],
            onChange: (ReponseChoix r) => setState(() {
              _lien = r.valeurs.isEmpty
                  ? null
                  : LienTitulaire.depuisCode(r.valeurs.first);
              _erreurLien = null;
            }),
          ),
          if (_erreurLien case final String e) ...<Widget>[
            Ecart.vSm,
            Text(
              e,
              style: palette.inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vLg,
          ListenableBuilder(
            listenable: _champs[ChampVersement.titulaire]!,
            builder: (BuildContext _, Widget? _) => CaseAccordTexte(
              key: FeuilleCoordonnees.cleAccord,
              libelle: w.autorisation(
                titulaire: _champs[ChampVersement.titulaire]!.text.trim(),
              ),
              cochee: _accord,
              erreur: _erreurAccord,
              onChanged: (bool v) => setState(() {
                _accord = v;
                _erreurAccord = null;
              }),
            ),
          ),
        ],
        Ecart.vLg,
        if (_echec) ...<Widget>[
          BandeauAttention(
            key: FeuilleCoordonnees.cleEchec,
            titre: w.erreurTitre,
            message: w.erreurEnregistrement,
            ton: TonEtat.alerte,
          ),
          Ecart.vLg,
        ],
        ActionPrincipale(
          key: FeuilleCoordonnees.cleEnregistrer,
          libelle: w.enregistrer,
          enCours: _enCours,
          onPress: _enregistrer,
        ),
      ],
    );
  }
}

/// La liste des pays, avec sa recherche (meme forme que le formulaire d'avis).
class _ListePays extends StatefulWidget {
  const _ListePays({required this.onChoix});

  final ValueChanged<String> onChoix;

  @override
  State<_ListePays> createState() => _ListePaysEtat();
}

class _ListePaysEtat extends State<_ListePays> {
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = t.avis.form.pays;
    final List<PaysIso> pays = chercherPays(_recherche.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ChampRecherche(
          controleur: _recherche,
          libelle: f.rechercheLibelle,
          aide: f.rechercheAide,
          onChange: (String _) => setState(() {}),
        ),
        Ecart.vLg,
        if (pays.isEmpty)
          Text(f.aucun, style: Theme.of(context).textTheme.bodyMedium)
        else
          CarteLignes(
            lignes: <Widget>[
              for (final PaysIso p in pays)
                SettingRow(
                  key: FeuilleCoordonnees.clePays(p.code),
                  title: p.nom,
                  onPress: () => widget.onChoix(p.code),
                ),
            ],
          ),
      ],
    );
  }
}

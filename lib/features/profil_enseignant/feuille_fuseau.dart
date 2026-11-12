// FUSEAU-IDENTITE-PRO (garde-cap, 12/11/2026, voie A) : l'enseignant regle
// lui-meme son fuseau horaire, depuis « Identite professionnelle » (et depuis
// ses disponibilites, quand le fuseau manque). C'est la seule facon pour lui
// de corriger un fuseau faux.
//
// * L'ecriture passe par `maj_profil_enseignant(p_timezone)` : la RPC existe
//   et verifie le nom (aucune migration). Un nom refuse est dit en clair
//   ([FuseauInconnu]), jamais avale.
// * Les choix : les fuseaux du pays declare d'abord, puis les fuseaux que
//   l'application propose deja (`fuseauxProposes`, lus tels quels : la liste
//   des familles ne change pas). Chaque choix montre sa ville seule : le
//   client n'a pas de base de fuseaux, il n'invente aucun decalage. Sous les
//   choix, un champ d'expert pour le nom international, avec un exemple
//   (« Asia/Riyadh »). La liste complete avec decalages attend une lecture
//   serveur (FUSEAU-LISTE-COMPLETE, au registre).
// * Action sensible (`DECISION-FLUIDITE-2026-11-07.md`) : on attend la reponse
//   du serveur, bouton en attente ; la feuille ne se ferme qu'apres elle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/profil/service_declaration.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/zone_saisie.dart';
import '../parcours_offres/libelles_parcours.dart' show fuseauxProposes;
import 'declaration_choix.dart' show PaysPropose, paysProposes;

/// Les fuseaux a proposer : le fuseau [actuel] s'il existe, puis ceux du
/// [pays] declare, puis les fuseaux proposes par l'application, sans doublon
/// et dans un ordre stable.
List<String> fuseauxAProposer({String? actuel, String? pays}) {
  final List<String> liste = <String>[];
  void ajouter(String iana) {
    final String nu = iana.trim();
    if (nu.isNotEmpty && !liste.contains(nu)) liste.add(nu);
  }

  if (actuel != null) ajouter(actuel);
  for (final PaysPropose p in paysProposes) {
    if (p.nom == pays?.trim()) p.fuseaux.forEach(ajouter);
  }
  for (final f in fuseauxProposes) {
    ajouter(f.iana);
  }
  return liste;
}

/// Les fuseaux du [pays] declare.
Set<String> fuseauxDuPays(String? pays) => <String>{
  for (final PaysPropose p in paysProposes)
    if (p.nom == pays?.trim()) ...p.fuseaux,
};

/// « +3 », « +5:30 », « -4 », « +0 » : le decalage sur UTC.
String decalageCourt(Duration decalage) {
  final String signe = decalage.isNegative ? '-' : '+';
  final int minutes = decalage.inMinutes.abs();
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return m == 0 ? '$signe$h' : '$signe$h:${m.toString().padLeft(2, '0')}';
}

/// Le fuseau du profil a afficher : « Riyad · UTC+3 », ou `null` sans
/// fuseau de profil. Le decalage est celui que le serveur rend
/// (`mon_horloge`), jamais un calcul du client.
String? fuseauDuProfilAffiche(MonHorloge? horloge) {
  final String? fuseau = horloge?.moi?.fuseau;
  final Duration? decalage = horloge?.moi?.decalage;
  if (fuseau == null || fuseau.trim().isEmpty || decalage == null) return null;
  return t.enseignant.profil.fuseauValeur(
    ville: villeDuFuseauLibelle(fuseau),
    decalage: decalageCourt(decalage),
  );
}

/// Ouvre la feuille du fuseau, ecrit le choix au serveur, puis relit le
/// fuseau du profil et le profil. Rend `true` quand le fuseau est enregistre.
Future<bool> ouvrirFeuilleFuseau(
  BuildContext context,
  WidgetRef ref, {
  String? pays,
}) async {
  final String? actuel = ref.read(monHorlogeProvider).value?.moi?.fuseau;
  final ServiceDeclarationEnseignant service = ref.read(
    serviceDeclarationProvider,
  );
  final bool? fait = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.enseignant.profil.modifierFuseau,
    constructeur: (BuildContext _) => FeuilleFuseau(
      actuel: actuel,
      pays: pays,
      ecrire: (String fuseau) => service.declarer(fuseau: fuseau),
    ),
  );
  if (fait != true) return false;
  ref
    ..invalidate(monHorlogeProvider)
    ..invalidate(profilEnseignantProvider);
  return true;
}

enum _Issue { aucune, requis, inconnu, erreur }

/// Le corps de la feuille du fuseau.
class FeuilleFuseau extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleFuseau({
    required this.ecrire,
    this.actuel,
    this.pays,
    super.key,
  });

  /// Le fuseau du profil, s'il existe.
  final String? actuel;

  /// Le pays declare, s'il existe.
  final String? pays;

  /// L'ecriture au serveur.
  final Future<void> Function(String fuseau) ecrire;

  /// Cle de l'action « Enregistrer ».
  static const Key enregistrerKey = ValueKey<String>('fuseau-enregistrer');

  /// Cle du champ d'expert.
  static const Key expertKey = ValueKey<String>('fuseau-expert');

  /// Cle de la phrase d'issue.
  static const Key issueKey = ValueKey<String>('fuseau-issue');

  /// Cle de la carte d'un fuseau.
  static Key carteKey(String iana) => ValueKey<String>('fuseau-$iana');

  @override
  State<FeuilleFuseau> createState() => _FeuilleFuseauEtat();
}

class _FeuilleFuseauEtat extends State<FeuilleFuseau> {
  late final List<String> _choix = fuseauxAProposer(
    actuel: widget.actuel,
    pays: widget.pays,
  );
  late final Set<String> _duPays = fuseauxDuPays(widget.pays);
  late final ReponseChoix? _initiale = widget.actuel == null
      ? null
      : ReponseChoix(valeurs: <String>{widget.actuel!.trim()});
  late ReponseChoix? _reponse = _initiale;
  final TextEditingController _expert = TextEditingController();
  bool _enCours = false;
  _Issue _issue = _Issue.aucune;

  @override
  void dispose() {
    _expert.dispose();
    super.dispose();
  }

  /// Le nom ecrit par l'expert d'abord ; sinon la carte choisie.
  String? get _retenu {
    final String ecrit = _expert.text.trim();
    if (ecrit.isNotEmpty) return ecrit;
    final Set<String> valeurs = _reponse?.valeurs ?? const <String>{};
    return valeurs.isEmpty ? null : valeurs.first;
  }

  Future<void> _enregistrer() async {
    if (_enCours) return;
    final String? fuseau = _retenu;
    if (fuseau == null) {
      setState(() => _issue = _Issue.requis);
      return;
    }
    setState(() {
      _enCours = true;
      _issue = _Issue.aucune;
    });
    _Issue issue;
    try {
      await widget.ecrire(fuseau);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    } on FuseauInconnu {
      issue = _Issue.inconnu;
    } on Object {
      issue = _Issue.erreur;
    }
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _issue = issue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final s = t.enseignant.profil;
    final String? phrase = switch (_issue) {
      _Issue.aucune => null,
      _Issue.requis => s.fuseauRequis,
      _Issue.inconnu => s.fuseauInconnu,
      _Issue.erreur => s.fuseauErreur,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(s.fuseauConsigne, style: textes.bodyMedium),
        Ecart.vLg,
        ChoiceCardGroup(
          valeurInitiale: _initiale,
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final String iana in _choix)
              OptionChoix(
                cle: FeuilleFuseau.carteKey(iana),
                valeur: iana,
                libelle: villeDuFuseauLibelle(iana),
                description: _duPays.contains(iana) ? s.fuseauDuPays : null,
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            _reponse = r;
            _issue = _Issue.aucune;
          }),
        ),
        Ecart.vLg,
        ZoneSaisie(
          controleur: _expert,
          cleChamp: FeuilleFuseau.expertKey,
          libelle: s.fuseauExpert,
          aide: s.fuseauExpertAide,
          onChanged: (_) {
            if (_issue != _Issue.aucune) setState(() => _issue = _Issue.aucune);
          },
        ),
        if (phrase != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              phrase,
              key: FeuilleFuseau.issueKey,
              style: AppPalette.of(context).inkAlert
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
        Ecart.vXl,
        ActionPrincipale(
          key: FeuilleFuseau.enregistrerKey,
          libelle: s.enregistrer,
          enCours: _enCours,
          onPress: _enregistrer,
        ),
      ],
    );
  }
}

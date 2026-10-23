// Le fuseau horaire du candidat (CAND-01) : deduit de l'appareil, puis confirme
// par une carte (« Chez vous, il est 14:05 ? », Oui ou Changer). Il ne part
// jamais sans cette confirmation : le fuseau commande l'heure de l'entretien
// (« un fuseau ne se devine pas », PORTS, Heures).
//
// Sans fuseau lisible sur l'appareil (hors web), la carte n'est pas posee :
// la personne choisit sa ville dans une liste, sans taper un identifiant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/fuseau_appareil.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/pays_iso.dart' show formeDeRecherche;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/setting_row.dart';
import 'libelles_parcours.dart';

/// Le fuseau IANA de l'appareil, ou `null` quand la plateforme ne le donne pas.
final Provider<String?> fuseauAppareilCandidatureProvider = Provider<String?>(
  (Ref _) => fuseauIanaAppareil(),
);

/// L'horloge de l'appareil.
final Provider<DateTime Function()> horlogeCandidatureProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);

/// Les villes proposees d'emblee, dans l'ordre : celles que l'application
/// nomme (`commun.fuseaux`). Les autres se trouvent par la recherche.
const List<String> villesProposees = <String>[
  'Europe/Paris',
  'Europe/Brussels',
  'Europe/London',
  'Africa/Casablanca',
  'Africa/Dakar',
  'Africa/Conakry',
  'Africa/Bamako',
  'Africa/Nouakchott',
  'Africa/Abidjan',
  'Africa/Lagos',
  'Asia/Riyadh',
  'America/Toronto',
  'America/New_York',
  'America/Los_Angeles',
];

/// Au plus ce nombre de villes est montre pour une recherche.
const int resultatsMax = 40;

/// La carte de confirmation du fuseau, ou la liste des villes.
class FuseauEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const FuseauEtape({
    required this.options,
    required this.choisi,
    required this.onChange,
    super.key,
  });

  /// Les fuseaux que le serveur accepte.
  final List<String> options;

  /// Le fuseau retenu, s'il y en a un.
  final String? choisi;

  /// Appele quand un fuseau est retenu.
  final ValueChanged<String> onChange;

  /// La cle de la carte « Chez vous, il est ... ».
  static const Key carteKey = ValueKey<String>('fuseau-carte');

  /// La cle du groupe Oui / Changer.
  static const Key confirmationKey = ValueKey<String>('fuseau-confirmation');

  /// La cle de la carte « Oui ».
  static const Key ouiKey = ValueKey<String>('fuseau-oui');

  /// La cle de la carte « Changer ».
  static const Key changerKey = ValueKey<String>('fuseau-changer');

  /// La cle du fuseau retenu.
  static const Key retenuKey = ValueKey<String>('fuseau-retenu');

  /// La cle du champ de recherche.
  static const Key champKey = ValueKey<String>('fuseau-recherche');

  /// La cle d'une ligne de la liste.
  static Key ligneKey(String iana) => ValueKey<String>('fuseau-ligne-$iana');

  @override
  ConsumerState<FuseauEtape> createState() => _FuseauEtapeState();
}

class _FuseauEtapeState extends ConsumerState<FuseauEtape> {
  final TextEditingController _requete = TextEditingController();
  late bool _liste;

  /// Le fuseau de l'appareil, quand le serveur l'accepte.
  String? get _propose {
    final String? appareil = ref.read(fuseauAppareilCandidatureProvider);
    return appareil != null && widget.options.contains(appareil)
        ? appareil
        : null;
  }

  @override
  void initState() {
    super.initState();
    // Sans fuseau lisible, ou apres un autre choix que la proposition : la
    // liste des villes.
    final String? choisi = widget.choisi;
    _liste = _propose == null || (choisi != null && choisi != _propose);
  }

  @override
  void dispose() {
    _requete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? choisi = widget.choisi;
    if (_liste) {
      return _choixVille(context, choisi);
    }
    return _confirmation(context, choisi);
  }

  Widget _confirmation(BuildContext context, String? choisi) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String propose = _propose!;
    final r = t.recrutement.parcours.fuseau;
    final DateTime maintenant = ref.watch(horlogeCandidatureProvider)();
    final String heure = isolerSens(heureDeLAppareil(maintenant));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          key: FuseauEtape.carteKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  r.heureChezVous(heure: heure),
                  style: textes.titleLarge,
                ),
              ),
              Ecart.vSm,
              Text(
                r.lieuPropose(lieu: nomDeLieu(propose)),
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
        Ecart.vLg,
        ChoiceCardGroup(
          key: FuseauEtape.confirmationKey,
          autoriserSaisieLibre: false,
          coteACote: true,
          valeurInitiale: choisi == propose
              ? const ReponseChoix(valeurs: <String>{'oui'})
              : null,
          options: <OptionChoix>[
            OptionChoix(
              cle: FuseauEtape.ouiKey,
              valeur: 'oui',
              libelle: r.oui,
              description: r.ouiDescription,
              explication: r.ouiExplication,
              icone: AppIcons.horloge,
            ),
            OptionChoix(
              cle: FuseauEtape.changerKey,
              valeur: 'changer',
              libelle: r.changer,
              description: r.changerDescription,
              explication: r.changerExplication,
              icone: AppIcons.maison,
            ),
          ],
          onChange: (ReponseChoix reponse) {
            if (reponse.valeurs.contains('oui')) {
              widget.onChange(propose);
            } else if (reponse.valeurs.contains('changer')) {
              setState(() => _liste = true);
            }
          },
        ),
      ],
    );
  }

  /// Les villes : celles que l'application nomme, ou le resultat d'une
  /// recherche.
  List<String> _villes() {
    final String q = formeDeRecherche(_requete.text);
    if (q.isEmpty) {
      return <String>[
        for (final String z in villesProposees)
          if (widget.options.contains(z)) z,
      ];
    }
    final List<String> trouvees = <String>[
      for (final String z in widget.options)
        if (formeDeRecherche(nomDeLieu(z)).contains(q) ||
            formeDeRecherche(z.replaceAll('_', ' ')).contains(q))
          z,
    ];
    trouvees.sort(
      (String a, String b) =>
          formeDeRecherche(nomDeLieu(a))
              .compareTo(formeDeRecherche(nomDeLieu(b))),
    );
    return trouvees.take(resultatsMax).toList();
  }

  Widget _choixVille(BuildContext context, String? choisi) {
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.recrutement.parcours.fuseau;
    final List<String> villes = _villes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_propose != null) ...<Widget>[
          LienFleche(
            libelle: r.retour,
            alignerEnDebut: true,
            onPress: () => setState(() {
              _liste = false;
              _requete.clear();
            }),
          ),
          Ecart.vMd,
        ],
        if (choisi != null) ...<Widget>[
          AppCard(
            key: FuseauEtape.retenuKey,
            selectionnee: true,
            child: Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: IconTheme(
                    data: IconThemeData(
                      color: AppPalette.of(context).washAccent.onBackground,
                      size: AppSpacing.xxl,
                    ),
                    child: Icon(AppIcons.succes.actif),
                  ),
                ),
                Ecart.hMd,
                Expanded(
                  child: Text(
                    r.retenu(lieu: nomDeLieu(choisi)),
                    style: textes.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Ecart.vLg,
        ],
        Text(r.choisirTitre, style: textes.titleMedium),
        Ecart.vSm,
        Text(r.choisirExplication, style: textes.bodyMedium),
        Ecart.vLg,
        ChampRecherche(
          cleChamp: FuseauEtape.champKey,
          controleur: _requete,
          libelle: r.recherche,
          aide: r.rechercheAide,
          onChange: (String _) => setState(() {}),
        ),
        Ecart.vLg,
        if (villes.isEmpty)
          Text(r.aucune, style: textes.bodyMedium)
        else
          CarteLignes(
            lignes: <Widget>[
              for (final String z in villes)
                SettingRow(
                  key: FuseauEtape.ligneKey(z),
                  title: nomDeLieu(z),
                  description: regionDuFuseau(z),
                  onPress: () {
                    widget.onChange(z);
                    setState(_requete.clear);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

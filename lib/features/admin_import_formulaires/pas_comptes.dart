// Pas 6 de l'import des formulaires (`ADM-23`) : les comptes.
//
// Une question : ces nombres sont-ils ceux que vous attendiez ? Les quatre
// compteurs sont ceux du serveur (nouvelles, deja connues, ignorees, a corriger),
// jamais recalcules. L'ecart avec le decompte attendu se lit **avant** de
// confirmer (L3-4). Le decompte attendu se choisit en cartes : le fichier du
// 21 octobre (440 lignes, 409 personnes), d'autres nombres, ou aucun. Seul le
// choix « d'autres nombres » demande de la frappe, et seulement des chiffres.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/section_header.dart';
import 'composants_import.dart';
import 'controleur_import.dart';

/// Le libelle d'un nombre d'unites : « 440 lignes », « 1 personne ».
String uniteDe(NatureCompte nature, int n) => switch (nature) {
  NatureCompte.lignes => t.admin.importFormulaires.unite.lignes(n: n),
  NatureCompte.personnes => t.admin.importFormulaires.unite.personnes(n: n),
};

/// La phrase des ecarts : « Écart avec les comptes attendus : attendu 440
/// lignes, 409 personnes, lu 438 lignes, 400 personnes. Vérifiez avant de
/// confirmer. » Une seule phrase, quel que soit le nombre d'ecarts.
String phraseEcarts(List<EcartCompte> ecarts) =>
    t.admin.importFormulaires.comptes.ecart(
      attendu: ecarts
          .map((EcartCompte e) => uniteDe(e.nature, e.attendu))
          .join(', '),
      lu: ecarts.map((EcartCompte e) => uniteDe(e.nature, e.lu)).join(', '),
    );

/// Les chiffres seulement, sept au plus : un compte n'a pas d'autre forme.
final List<TextInputFormatter> chiffresSeulement = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(7),
];

/// Le pas « Comptes ».
class PasComptes extends StatefulWidget {
  /// Cree le pas.
  const PasComptes({required this.controleur, required this.empile, super.key});

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Vrai sur telephone.
  final bool empile;

  /// La cle du champ des lignes attendues.
  static const Key champLignesKey = ValueKey<String>('import-attendu-lignes');

  /// La cle du champ des personnes attendues.
  static const Key champPersonnesKey = ValueKey<String>(
    'import-attendu-personnes',
  );

  @override
  State<PasComptes> createState() => _PasComptesEtat();
}

class _PasComptesEtat extends State<PasComptes> {
  late final TextEditingController _lignes = TextEditingController(
    text: widget.controleur.attenduLignes?.toString() ?? '',
  );
  late final TextEditingController _personnes = TextEditingController(
    text: widget.controleur.attenduPersonnes?.toString() ?? '',
  );

  ControleurImportCandidatures get _c => widget.controleur;

  @override
  void dispose() {
    _lignes.dispose();
    _personnes.dispose();
    super.dispose();
  }

  void _surSaisie() => setState(
    () => _c.repondreAttendus(
      ReponseAttendus.autres,
      lignes: int.tryParse(_lignes.text.trim()),
      personnes: int.tryParse(_personnes.text.trim()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires.comptes;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final CompteursImport? compteurs = _c.apercu?.compteurs;
    final ReponseAttendus? reponse = _c.reponseAttendus;
    final List<EcartCompte> ecarts = _c.ecarts;
    final bool repondu = _c.comptesRepondus;
    final String? consigne = repondu
        ? null
        : reponse == ReponseAttendus.autres
        ? a.saisirNombre
        : a.choisir;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(question: a.question, explication: a.explication),
        Ecart.vXl,
        if (compteurs != null) ...<Widget>[
          CompteursCarte(compteurs: compteurs),
          Ecart.vXl,
        ],
        SectionHeader(titre: a.attendus.question),
        Ecart.vMd,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: reponse == null
              ? null
              : ReponseChoix(valeurs: <String>{reponse.name}),
          options: <OptionChoix>[
            OptionChoix(
              valeur: ReponseAttendus.fichierDu2110.name,
              cle: const ValueKey<String>('import-attendu-fichier2110'),
              libelle: a.attendus.fichier2110.titre,
              description: a.attendus.fichier2110.description,
              icone: AppIcons.echeance,
            ),
            OptionChoix(
              valeur: ReponseAttendus.autres.name,
              cle: const ValueKey<String>('import-attendu-autres'),
              libelle: a.attendus.autres.titre,
              description: a.attendus.autres.description,
              icone: AppIcons.crayon,
            ),
            OptionChoix(
              valeur: ReponseAttendus.aucun.name,
              cle: const ValueKey<String>('import-attendu-aucun'),
              libelle: a.attendus.aucun.titre,
              description: a.attendus.aucun.description,
              icone: AppIcons.moins,
            ),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.isEmpty) return;
            final ReponseAttendus choix = ReponseAttendus.values.firstWhere(
              (ReponseAttendus x) => x.name == r.valeurs.first,
            );
            setState(
              () => _c.repondreAttendus(
                choix,
                lignes: int.tryParse(_lignes.text.trim()),
                personnes: int.tryParse(_personnes.text.trim()),
              ),
            );
          },
        ),
        if (reponse == ReponseAttendus.autres) ...<Widget>[
          Ecart.vSm,
          AppCard(
            key: const ValueKey<String>('import-attendus-saisie'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TexteSansCoupure(
                  a.attendus.aide,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vMd,
                KeyedSubtree(
                  key: PasComptes.champLignesKey,
                  child: ChampEtiquete(
                    libelle: a.attendus.lignes,
                    controller: _lignes,
                    keyboardType: TextInputType.number,
                    inputFormatters: chiffresSeulement,
                    onChanged: (String _) => _surSaisie(),
                  ),
                ),
                Ecart.vMd,
                KeyedSubtree(
                  key: PasComptes.champPersonnesKey,
                  child: ChampEtiquete(
                    libelle: a.attendus.personnes,
                    controller: _personnes,
                    keyboardType: TextInputType.number,
                    inputFormatters: chiffresSeulement,
                    onChanged: (String _) => _surSaisie(),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (repondu && _c.attendus != null) ...<Widget>[
          Ecart.vLg,
          if (ecarts.isEmpty)
            Row(
              key: const ValueKey<String>('import-comptes-accord'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(
                  child: IconTheme(
                    data: palette.inkSuccess.asIconTheme(size: AppSpacing.xl),
                    child: Icon(AppIcons.succes.actif),
                  ),
                ),
                Ecart.hSm,
                Expanded(
                  child: TexteSansCoupure(a.accord, style: textes.bodyLarge),
                ),
              ],
            )
          else
            BandeauAttention(
              key: const ValueKey<String>('import-comptes-ecart'),
              titre: a.ecartTitre,
              message: phraseEcarts(ecarts),
            ),
        ],
        Ecart.vLg,
        ActionsDuPas(
          empile: widget.empile,
          libelleAction: repondu ? t.commun.continuer : null,
          onAction: _c.suivant,
          onRetour: _c.precedent,
          souscription: consigne == null
              ? null
              : IndicationPas(message: consigne, discret: true),
        ),
      ],
    );
  }
}

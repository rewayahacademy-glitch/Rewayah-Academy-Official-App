import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_parcours/libelles_parcours.dart';
import '../../core/tc_parcours/port_signalement.dart';
import '../../core/tc_parcours/student_concern.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/choice_card_group.dart';

/// Le signalement structure, depuis la fiche d'un eleve (spec section 12.2).
///
/// **Le professeur ne retape aucun identifiant.** La seance, le groupe, l'eleve
/// et son propre profil sont joints par le port ; l'ecran les affiche en une
/// phrase et n'en propose aucun a la saisie. Il choisit une categorie et ecrit
/// ce qu'il a a dire.
///
/// **Deux champs de texte, et l'ecran dit lequel part ou.** La note interne est
/// lue par l'administration seulement ; le message pour la famille est
/// facultatif, et c'est l'administration qui decide de le transmettre. La
/// phrase « elle ne part jamais automatiquement a la famille » est ecrite sous
/// le champ lui-meme, pas dans une page d'aide : c'est la seule place ou elle
/// est lue au moment ou elle compte.
class FeuilleSignalement extends ConsumerStatefulWidget {
  /// Cree la feuille de signalement.
  const FeuilleSignalement({
    required this.groupeId,
    required this.academyId,
    required this.prenomEleve,
    this.sessionId,
    super.key,
  });

  /// Ouvre la feuille et rend le signalement depose, ou `null` si l'enseignant
  /// a referme sans envoyer.
  ///
  /// `AppBottomSheet.ouvrir` est le seul point d'entree d'une surface modale du
  /// produit : le depot n'ouvre pas de boite de dialogue Material.
  ///
  /// TC-Z-SUIVI : `t.tc.parcours.signalement.envoye` (« Signalement transmis a
  /// l'administration. ») n'est encore affiche par aucun appelant -- cette
  /// feuille se contente de rendre le signalement depose, la confirmation
  /// reste a poser cote appelant.
  static Future<StudentConcern?> ouvrir(
    BuildContext context, {
    required String groupeId,
    required String academyId,
    required String prenomEleve,
    String? sessionId,
  }) => AppBottomSheet.ouvrir<StudentConcern>(
    context,
    titre: t.tc.parcours.signalement.titre,
    constructeur: (BuildContext _) => FeuilleSignalement(
      groupeId: groupeId,
      academyId: academyId,
      prenomEleve: prenomEleve,
      sessionId: sessionId,
    ),
  );

  /// Le groupe concerne. **Prerempli.**
  final String groupeId;

  /// L'eleve concerne, par son identifiant d'academie. **Prerempli.**
  final String academyId;

  /// Le prenom affiche. **Jamais un nom de famille**, pas meme une initiale.
  final String prenomEleve;

  /// La seance concernee, quand le signalement nait d'une seance.
  final String? sessionId;

  @override
  ConsumerState<FeuilleSignalement> createState() => _FeuilleSignalementState();
}

class _FeuilleSignalementState extends ConsumerState<FeuilleSignalement> {
  final TextEditingController _interne = TextEditingController();
  final TextEditingController _famille = TextEditingController();

  CategorieSignalement _categorie = CategorieSignalement.pedagogique;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _interne.dispose();
    _famille.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le contexte, dit une fois, en toutes lettres : c'est ce qui remplace
        // les quatre champs d'identifiants que le professeur aurait eu a
        // retaper.
        Text(
          t.tc.parcours.signalement.contexte(eleve: widget.prenomEleve),
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,

        Text(t.tc.parcours.signalement.categorie, style: textes.titleSmall),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_categorie.valeurSql}),
          options: <OptionChoix>[
            for (final CategorieSignalement categorie
                in CategorieSignalement.values)
              OptionChoix(
                valeur: categorie.valeurSql,
                libelle: libelleCategorieSignalement(categorie),
              ),
          ],
          onChange: _changerCategorie,
        ),
        Ecart.vXl,

        TextField(
          controller: _interne,
          maxLines: 3,
          // Le bouton depend de ce champ : sans ce rappel, il resterait inerte
          // alors que la note est saisie.
          onChanged: (String _) => setState(() {}),
          decoration: InputDecoration(
            labelText: t.tc.parcours.signalement.interne,
          ),
        ),
        Ecart.vXs,
        Text(
          t.tc.parcours.signalement.interneAide,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,

        TextField(
          controller: _famille,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t.tc.parcours.signalement.famille,
          ),
        ),
        Ecart.vXs,
        Text(
          t.tc.parcours.signalement.familleAide,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,

        ActionPrincipale(
          libelle: t.tc.parcours.signalement.envoyer,
          enCours: _envoi,
          onPress: _interne.text.trim().isEmpty ? null : _envoyer,
        ),
        if (_interne.text.trim().isEmpty) ...<Widget>[
          Ecart.vSm,
          Text(
            t.tc.parcours.signalement.interneRequis,
            textAlign: TextAlign.center,
            style: textes.bodySmall,
          ),
        ],
        if (_erreur case final String message) ...<Widget>[
          Ecart.vMd,
          Text(
            message,
            textAlign: TextAlign.center,
            // L'encre d'alerte, jamais la paire : `surfaceAlert` ecrit en
            // blanc, illisible sur la feuille.
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }

  void _changerCategorie(ReponseChoix choix) {
    if (choix.valeurs.length != 1) {
      return;
    }
    final CategorieSignalement? choisie = CategorieSignalement.depuisSql(
      choix.valeurs.first,
    );
    if (choisie != null) {
      setState(() => _categorie = choisie);
    }
  }

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final String famille = _famille.text.trim();
      final StudentConcern signalement = await ref
          .read(portSignalementProvider)
          .signaler(
            categorie: _categorie,
            groupeId: widget.groupeId,
            sessionId: widget.sessionId,
            academyId: widget.academyId,
            internalDetails: _interne.text,
            // Vide vaut absent : un message famille vide ouvrirait l'action
            // « Transmettre » sur rien.
            familySummary: famille.isEmpty ? null : famille,
          );
      if (mounted) {
        Navigator.of(context).pop(signalement);
      }
    } on Object {
      // Volontairement un `Object` : le port peut lever son propre
      // `EchecSignalement` comme une erreur de plateforme, et l'enseignant doit
      // pouvoir reessayer dans les deux cas.
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = t.tc.parcours.signalement.echec;
        });
      }
    }
  }
}

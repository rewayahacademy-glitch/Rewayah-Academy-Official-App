// NOM-PROPRE (INCIDENT-CANDIDATS, directeur, 14/11/2026) : a l'ouverture, une
// personne dont le nom enregistre ne suit pas la regle (chiffres, signes, une
// seule lettre) le corrige sur un ecran court avant de continuer. Le serveur
// dit qui est concerne (`mon_nom_a_corriger`) ; une lecture qui echoue ne
// bloque jamais l'application.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/identite/nom_propre.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/page_shell.dart';

/// Montre [child], ou l'ecran de correction du nom quand le serveur dit que le
/// nom de la personne connectee est a corriger.
class GardeNomPropre extends ConsumerWidget {
  /// Cree le garde.
  const GardeNomPropre({required this.child, super.key});

  /// L'application.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(sessionProvider);
    final String? id = session.profileId;
    if (id == null || session.lectureProfil != LectureProfil.presente) {
      return child;
    }
    final EtatNomPropre? etat = ref.watch(nomACorrigerProvider(id)).value;
    if (etat == null || !etat.aCorriger) return child;
    // Un Navigator propre : les champs de saisie ont besoin d'un Overlay, et
    // le garde est pose au-dessus de celui du routeur.
    return Navigator(
      onGenerateRoute: (RouteSettings _) => MaterialPageRoute<void>(
        builder: (BuildContext _) =>
            CorrectionNomPage(profileId: id, etat: etat),
      ),
    );
  }
}

/// L'ecran court de correction du nom.
class CorrectionNomPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const CorrectionNomPage({
    required this.profileId,
    required this.etat,
    super.key,
  });

  /// La personne connectee.
  final String profileId;

  /// Le nom enregistre.
  final EtatNomPropre etat;

  /// Le champ du prenom.
  static const Key prenomKey = Key('correction-nom-prenom');

  /// Le champ du nom.
  static const Key nomKey = Key('correction-nom-nom');

  /// L'action « Enregistrer mon nom ».
  static const Key enregistrerKey = Key('correction-nom-enregistrer');

  @override
  ConsumerState<CorrectionNomPage> createState() => _CorrectionNomPageState();
}

class _CorrectionNomPageState extends ConsumerState<CorrectionNomPage> {
  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  bool _tente = false;
  bool _envoi = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Une valeur deja juste est gardee ; une valeur fautive est videe, pour
    // ne pas faire effacer « ٠ » a la main.
    String garder(String? v) => v != null && nomPropreValide(v) ? v : '';
    _prenom = TextEditingController(text: garder(widget.etat.prenom));
    _nom = TextEditingController(text: garder(widget.etat.nom));
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  String? _erreur(TextEditingController champ, String message) =>
      _tente && !nomPropreValide(champ.text) ? message : null;

  Future<void> _enregistrer() async {
    if (!nomPropreValide(_prenom.text) || !nomPropreValide(_nom.text)) {
      setState(() => _tente = true);
      return;
    }
    final PortNomPropre? port = ref.read(portNomPropreProvider);
    if (port == null) return;
    setState(() {
      _envoi = true;
      _message = null;
    });
    try {
      await port.corriger(prenom: _prenom.text, nom: _nom.text);
      // Le succes se dit par la relecture du serveur : le garde laisse
      // passer quand il ne demande plus rien.
      ref.invalidate(nomACorrigerProvider(widget.profileId));
    } on NomNonConforme {
      if (mounted) {
        setState(() {
          _tente = true;
          _message = t.inscription.nomEnLettresNom;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _message = t.inscription.nomPropre.nonConfirme);
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    return PageShell(
      titre: t.inscription.nomPropre.titre,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TexteSansCoupure(
              t.inscription.nomPropre.explication,
              style: textes.bodyLarge,
            ),
            Ecart.vSm,
            TexteSansCoupure(t.inscription.commeSurLaPiece, style: attenue),
            Ecart.vXl,
            ChampEtiquete(
              libelle: t.inscription.prenom,
              obligatoire: true,
              cleChamp: CorrectionNomPage.prenomKey,
              controller: _prenom,
              onChanged: (String _) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              actionClavier: TextInputAction.next,
              remplissage: const <String>[AutofillHints.givenName],
              erreur: _erreur(_prenom, t.inscription.nomEnLettresPrenom),
            ),
            Ecart.vLg,
            ChampEtiquete(
              libelle: t.inscription.nom,
              obligatoire: true,
              cleChamp: CorrectionNomPage.nomKey,
              controller: _nom,
              onChanged: (String _) => setState(() {}),
              onSubmitted: (String _) => unawaited(_enregistrer()),
              textCapitalization: TextCapitalization.words,
              actionClavier: TextInputAction.done,
              remplissage: const <String>[AutofillHints.familyName],
              erreur: _erreur(_nom, t.inscription.nomEnLettresNom),
            ),
            if (_message != null) ...<Widget>[
              Ecart.vLg,
              Semantics(
                liveRegion: true,
                child: TexteSansCoupure(
                  _message!,
                  style: palette.inkAlert.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ],
            Ecart.vXl,
            ActionPrincipale(
              key: CorrectionNomPage.enregistrerKey,
              libelle: t.inscription.nomPropre.enregistrer,
              enCours: _envoi,
              onPress: _envoi ? null : () => unawaited(_enregistrer()),
            ),
          ],
        ),
      ),
    );
  }
}

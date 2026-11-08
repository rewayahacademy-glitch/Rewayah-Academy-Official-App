/// La confirmation du nom en lettres latines, dans la Salle d'examen (decision
/// du directeur du 23/10/2026, `docs/current/DECISION-CANDIDATURES-2026-10-21.md`,
/// section « Les noms dans une seule ecriture sur les listes »).
///
/// Pour les dossiers concernes seulement : le nom d'origine n'est pas en
/// alphabet latin (reponse importee d'un formulaire, ou question laissee sans
/// reponse a l'inscription) et rien n'est confirme. Le champ est pre-rempli par
/// la proposition de translitteration (`proposerNomLatin`), que la personne
/// corrige ou confirme ; **rien n'est enregistre avant « Confirmer mon nom »**.
/// « Plus tard » ne bloque rien : le questionnaire s'ouvre, et la liste de la
/// direction garde la marque « a confirmer ».
///
/// Etats : chargement (`Skeleton`, le temps de lire le nom), contenu, erreur
/// de lecture (le questionnaire s'ouvre, jamais bloque), erreur d'envoi (la
/// phrase dit que le nom n'est pas confirme et quoi faire, K-59), hors ligne
/// (le bandeau de la page le dit ; l'envoi echoue en « non confirme »). Sans
/// port, ou sans lot serveur, la question ne se pose pas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/nom_latin.dart';
import '../../core/candidature/port_nom_latin.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'lecture_page.dart';

/// Pose la confirmation du nom latin avant [enfant] quand elle est due.
class PorteNomLatin extends ConsumerStatefulWidget {
  /// Cree la porte.
  const PorteNomLatin({required this.enfant, super.key});

  /// Ce qui s'ouvre une fois le nom confirme, ou quand il n'y a rien a confirmer.
  final Widget enfant;

  @override
  ConsumerState<PorteNomLatin> createState() => _PorteNomLatinState();
}

class _PorteNomLatinState extends ConsumerState<PorteNomLatin> {
  /// La personne a confirme, ou choisi « Plus tard » : le parcours s'ouvre.
  bool _passee = false;

  @override
  Widget build(BuildContext context) {
    // Sans port (lot serveur non branche) : rien a demander, sans attendre.
    if (_passee || ref.watch(portNomLatinProvider) == null) {
      return widget.enfant;
    }
    final AsyncValue<EtatNomLatin?> etat = ref.watch(etatNomLatinProvider);
    if (etat.isLoading && !etat.hasValue) {
      return const PageSimple(titre: null, corps: Skeleton.liste(lignes: 3));
    }
    final EtatNomLatin? lu = etat.value;
    // Une erreur de lecture ne bloque pas le questionnaire.
    if (lu == null || !lu.aConfirmer) {
      return widget.enfant;
    }
    return NomLatinEtape(
      etat: lu,
      onTermine: () {
        ref.invalidate(etatNomLatinProvider);
        setState(() => _passee = true);
      },
    );
  }
}

/// L'ecran de confirmation : une phrase qui dit pourquoi, le nom d'origine
/// rappele, le champ pre-rempli, un seul bouton plein.
class NomLatinEtape extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const NomLatinEtape({required this.etat, required this.onTermine, super.key});

  /// L'etat du nom, tel que le serveur le rend.
  final EtatNomLatin etat;

  /// Appele quand la personne a confirme ou choisi « Plus tard ».
  final VoidCallback onTermine;

  /// La cle du champ.
  static const Key champKey = ValueKey<String>('nom-latin-champ');

  /// La cle du bouton plein.
  static const Key confirmerKey = ValueKey<String>('nom-latin-confirmer');

  /// La cle du lien « Plus tard ».
  static const Key plusTardKey = ValueKey<String>('nom-latin-plus-tard');

  @override
  ConsumerState<NomLatinEtape> createState() => _NomLatinEtapeState();
}

class _NomLatinEtapeState extends ConsumerState<NomLatinEtape> {
  late final TextEditingController _champ;
  bool _enCours = false;
  bool _tente = false;

  /// Le serveur a refuse le texte (il n'est pas latin pour lui).
  bool _refuse = false;
  String? _echec;

  @override
  void initState() {
    super.initState();
    _champ = TextEditingController(
      text: proposerNomLatin(widget.etat.nomComplet),
    );
  }

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    if (_enCours) {
      return;
    }
    if (!nomEstLatin(_champ.text)) {
      setState(() {
        _tente = true;
        _echec = null;
      });
      return;
    }
    final PortNomLatin? port = ref.read(portNomLatinProvider);
    if (port == null) {
      return;
    }
    setState(() {
      _enCours = true;
      _echec = null;
    });
    try {
      await port.confirmer(nomLatinNettoye(_champ.text));
    } on NomNonLatin {
      if (mounted) {
        setState(() {
          _enCours = false;
          _refuse = true;
        });
      }
      return;
    } on Object {
      // D5 : ce qui a ete envoye est non confirme.
      if (mounted) {
        setState(() {
          _enCours = false;
          _echec = t.recrutement.nomLatin.echec;
        });
      }
      return;
    }
    if (mounted) {
      widget.onTermine();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.nomLatin;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String origine = widget.etat.nomComplet.trim();
    return PageShell(
      titre: r.titre,
      onRetour: () => GoRouter.of(context).go(Routes.attente),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_echec != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _echec!,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          ActionPrincipale(
            key: NomLatinEtape.confirmerKey,
            libelle: r.confirmer,
            onPress: _enCours ? null : _confirmer,
            enCours: _enCours,
          ),
          Ecart.vXs,
          Center(
            child: ActionPrincipale(
              key: NomLatinEtape.plusTardKey,
              libelle: r.plusTard,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: _enCours ? null : widget.onTermine,
            ),
          ),
        ],
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TexteSansCoupure(
                r.explication,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
              if (origine.isNotEmpty) ...<Widget>[
                Ecart.vMd,
                TexteSansCoupure(
                  r.origine(nom: isolerSens(origine)),
                  style: palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
              Ecart.vXl,
              TextField(
                key: NomLatinEtape.champKey,
                controller: _champ,
                onChanged: (String _) => setState(() {
                  _echec = null;
                  _refuse = false;
                }),
                onSubmitted: (String _) => _confirmer(),
                // Un nom latin se lit de gauche a droite, quelle que soit la
                // langue de l'ecran.
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: r.libelle,
                  helperText: r.aide,
                  helperMaxLines: 3,
                  errorText: _refuse || (_tente && !nomEstLatin(_champ.text))
                      ? r.erreur
                      : null,
                  errorMaxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

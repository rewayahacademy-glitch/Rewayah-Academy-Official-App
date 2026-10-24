import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/candidature/nom_latin.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/identite` : prenom et nom, erreurs sous les champs.
///
/// Une question de plus, seulement pour le candidat enseignant dont le nom
/// saisi n'est pas en alphabet latin : « Votre nom en lettres latines », avec
/// une proposition de translitteration que la personne corrige ou confirme
/// (decision du directeur du 23/10/2026). La proposition n'est jamais envoyee
/// d'elle-meme : seul le texte qui reste dans ce champ, a « Continuer », part
/// au serveur apres l'inscription.
class IdentiteEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const IdentiteEtape({super.key});

  @override
  ConsumerState<IdentiteEtape> createState() => _IdentiteEtapeState();
}

class _IdentiteEtapeState extends ConsumerState<IdentiteEtape> {
  static const String _route = Routes.inscriptionIdentite;

  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  late final TextEditingController _nomLatin;

  /// Les erreurs ne s'affichent qu'apres une premiere tentative.
  bool _tente = false;

  /// La personne a ecrit dans le champ latin : la proposition ne le remplace
  /// plus.
  bool _latinModifie = false;

  @override
  void initState() {
    super.initState();
    final BrouillonInscription brouillon = ref.read(
      brouillonInscriptionProvider,
    );
    _prenom = TextEditingController(text: brouillon.prenom);
    _nom = TextEditingController(text: brouillon.nom);
    _nomLatin = TextEditingController(text: brouillon.nomLatin);
    // Un nom latin deja confirme (retour depuis le recapitulatif) est garde.
    _latinModifie = brouillon.nomLatin.isNotEmpty;
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _nomLatin.dispose();
    super.dispose();
  }

  bool get _enseignant =>
      ref.read(brouillonInscriptionProvider).usage ==
      UsageInscription.enseignant;

  /// La question de plus est posee : candidat enseignant, nom d'une autre
  /// ecriture.
  bool get _demande =>
      _enseignant && nomDemandeEcritureLatine('${_prenom.text} ${_nom.text}');

  /// Le nom change : tant que la personne n'a pas ecrit dans le champ latin, il
  /// suit la proposition.
  void _surNom() {
    if (_enseignant && !_latinModifie) {
      _nomLatin.text = proposerNomLatin('${_prenom.text} ${_nom.text}');
    }
    setState(() {});
  }

  String? _erreur(TextEditingController champ) =>
      _tente && champ.text.trim().isEmpty ? t.inscription.champRequis : null;

  String? get _erreurLatin => _tente && !nomEstLatin(_nomLatin.text)
      ? t.inscription.nomLatin.erreur
      : null;

  void _continuer() {
    if (_prenom.text.trim().isEmpty ||
        _nom.text.trim().isEmpty ||
        (_demande && !nomEstLatin(_nomLatin.text))) {
      setState(() => _tente = true);
      return;
    }
    ref
        .read(brouillonInscriptionProvider.notifier)
        .saisirIdentite(
          prenom: _prenom.text,
          nom: _nom.text,
          nomLatin: _demande ? _nomLatin.text : '',
        );
    avancerDepuis(
      context,
      _route,
      usage: ref.read(brouillonInscriptionProvider).usage,
    );
  }

  @override
  Widget build(BuildContext context) {
    exigerEtapesPrecedentes(
      context,
      ref.watch(brouillonInscriptionProvider),
      _route,
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return CoquilleEtape(
      route: _route,
      question: t.inscription.identiteQuestion,
      // K-47 : seul l'enseignant depose une piece ; le tuteur n'en entend pas
      // parler.
      explication:
          ref.watch(brouillonInscriptionProvider).usage ==
              UsageInscription.enseignant
          ? '${t.inscription.candidat.accueil} ${t.inscription.identiteRaison}'
          : null,
      libelleAction: t.commun.continuer,
      onAction: _continuer,
      onRetour: () => reculerDepuis(
        context,
        _route,
        usage: ref.read(brouillonInscriptionProvider).usage,
      ),
      enfant: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('inscription-prenom'),
              controller: _prenom,
              onChanged: (String _) => _surNom(),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.givenName],
              decoration: InputDecoration(
                labelText: t.inscription.prenom,
                errorText: _erreur(_prenom),
              ),
            ),
            Ecart.vLg,
            TextField(
              key: const Key('inscription-nom'),
              controller: _nom,
              onChanged: (String _) => _surNom(),
              onSubmitted: (String _) {
                if (!_demande) {
                  _continuer();
                }
              },
              textCapitalization: TextCapitalization.words,
              textInputAction: _demande
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: const <String>[AutofillHints.familyName],
              decoration: InputDecoration(
                labelText: t.inscription.nom,
                errorText: _erreur(_nom),
              ),
            ),
            if (_demande) ...<Widget>[
              Ecart.vXl,
              // Pourquoi on le demande, avant le champ (K-58).
              TexteSansCoupure(
                t.inscription.nomLatin.raison,
                key: const Key('inscription-nom-latin-raison'),
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
              Ecart.vSm,
              TextField(
                key: const Key('inscription-nom-latin'),
                controller: _nomLatin,
                onChanged: (String _) {
                  _latinModifie = true;
                  setState(() {});
                },
                onSubmitted: (String _) => _continuer(),
                // Un nom latin se lit de gauche a droite, quelle que soit la
                // langue de l'ecran.
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: t.inscription.nomLatin.libelle,
                  helperText: t.inscription.nomLatin.aide,
                  helperMaxLines: 3,
                  errorText: _erreurLatin,
                  errorMaxLines: 3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

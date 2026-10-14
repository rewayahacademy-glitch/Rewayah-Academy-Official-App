/// RECRUT-ECRANS (3/5) : la signature probante du contrat d'enseignant.
///
/// Le texte, la version et l'empreinte viennent du serveur
/// ([ContratCourant], contrat C-15) ; la page ne porte aucune constante de
/// version. Le texte affiche doit hasher a l'empreinte annoncee : sinon la
/// signature n'est pas proposee (controle d'affichage seulement, aucune
/// empreinte de reference n'est calculee ici). La personne tape son nom, coche
/// l'accuse, signe ; l'horodatage est celui du serveur (contrat C-16).
///
/// Etats : chargement, contenu a signer, **deja signe** (lecture seule : la
/// signature existante, la case et le nom figes, la copie telechargeable),
/// **version perimee** (le texte est recharge, le nom conserve, une nouvelle
/// signature est demandee), **nom vide** (erreur de champ, bouton inactif),
/// hors ligne, erreur, contrat introuvable, texte altere, port absent.
///
/// `ContratPage` ouvre cette page a la place de l'ancien parcours des que le
/// port est branche ; sans port, l'ancien parcours reste en place.
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/recrutement/ouvreur_lien.dart';
import '../../core/recrutement/port_signature_contrat.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/zone_saisie.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;

/// Le contrat courant et la signature existante, lus ensemble.
typedef ContratEtSignature = ({ContratCourant contrat, Signature? signature});

/// Les deux lectures de la page.
final FutureProvider<ContratEtSignature> contratEtSignatureProvider =
    FutureProvider<ContratEtSignature>((Ref ref) async {
      final ContratCourant contrat = await ref.watch(
        contratEnseignantCourantProvider.future,
      );
      final Signature? signature = await ref.watch(
        maSignatureEnseignantProvider.future,
      );
      return (contrat: contrat, signature: signature);
    }, retry: (int _, Object _) => null);

/// Vrai quand le texte hashe a l'empreinte annoncee (affichage seulement).
bool empreinteConforme(ContratCourant c) =>
    crypto.sha256.convert(utf8.encode(c.texte)).toString() ==
    c.sha256.trim().toLowerCase();

/// Une empreinte est un seul « mot » plus large que l'ecran a 320 et texte
/// 200 % : une espace sans chasse (U+200B, invisible) tous les huit signes lui
/// donne des points de coupure propres, comme `coupuresAdresse` pour une
/// adresse.
String _coupuresEmpreinte(String empreinte) =>
    empreinte.replaceAllMapped(RegExp('.{1,8}'), (Match m) => '${m[0]}\u200B');

/// L'ecran de signature du contrat d'enseignant.
class SignatureContratPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const SignatureContratPage({super.key});

  @override
  ConsumerState<SignatureContratPage> createState() =>
      _SignatureContratPageState();
}

class _SignatureContratPageState extends ConsumerState<SignatureContratPage> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _nomFige = TextEditingController();
  bool _accuse = false;
  bool _envoi = false;
  bool _tente = false;
  bool _versionPerimee = false;
  String? _erreur;
  String? _erreurNom;
  String? _info;

  @override
  void dispose() {
    _nom.dispose();
    _nomFige.dispose();
    super.dispose();
  }

  bool get _nomVide => _nom.text.trim().isEmpty;

  Future<void> _signer(ContratCourant contrat) async {
    final PortSignatureContrat? port = ref.read(portSignatureContratProvider);
    if (port == null) return;
    final r = t.recrutement.signature;
    if (_nomVide) {
      setState(() {
        _tente = true;
        _erreurNom = r.nomVide;
      });
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _erreurNom = null;
      _info = null;
    });
    String? erreur;
    String? erreurNom;
    bool perimee = false;
    try {
      await port.signerContrat(contrat.kind, contrat.version, _nom.text.trim());
    } on VersionPerimee {
      // Le texte a change pendant la lecture : on recharge, le nom reste,
      // la case est decochee (elle portait sur l'ancien texte).
      perimee = true;
    } on NomVide {
      erreurNom = r.nomVide;
    } on NomTropLong {
      erreurNom = r.nomTropLong;
    } on NonConnecte {
      erreur = r.nonConnecte;
    } on HorsLigneSignature {
      erreur = r.horsLigne;
    } on ErreurSignature {
      erreur = r.erreur;
    } on Object {
      erreur = r.erreur;
    }
    ref
      ..invalidate(contratEnseignantCourantProvider)
      ..invalidate(maSignatureEnseignantProvider)
      ..invalidate(etatDossierProvider);
    if (!mounted) return;
    setState(() {
      _envoi = false;
      _erreur = erreur;
      _erreurNom = erreurNom;
      if (perimee) {
        _versionPerimee = true;
        _accuse = false;
      }
    });
  }

  Future<void> _copie(ContratCourant contrat) async {
    final PortSignatureContrat? port = ref.read(portSignatureContratProvider);
    if (port == null) return;
    final r = t.recrutement.signature;
    try {
      final String url = await port.copieSigneeUrl(contrat.kind);
      final ResultatOuverture res = await ref.read(ouvreurLienProvider)(
        Uri.parse(url),
      );
      if (mounted) {
        setState(
          () => _info = res == ResultatOuverture.copie ? r.copieLien : null,
        );
      }
    } on Object {
      if (mounted) setState(() => _info = r.copieErreur);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.signature;
    final bool capable = ref.watch(portSignatureContratProvider) != null;
    final AsyncValue<ContratEtSignature> valeur = ref.watch(
      contratEtSignatureProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return PageShell(
      titre: r.titre,
      onRetour: () => GoRouter.of(context).go(Routes.attente),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: !capable
              ? EtatSysteme(
                  key: const ValueKey<String>('signature-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: r.titre,
                  phrase: r.indisponible,
                  dependance: dependanceSignatureContrat,
                )
              : BlocAsynchrone<ContratEtSignature>(
                  key: const ValueKey<String>('signature-bloc'),
                  valeur: valeur,
                  squelette: const Skeleton.liste(lignes: 6),
                  onReessayer: () {
                    ref
                      ..invalidate(contratEnseignantCourantProvider)
                      ..invalidate(maSignatureEnseignantProvider);
                  },
                  erreurVersEtat: (Object e, VoidCallback? reessayer) {
                    if (e is CapaciteIndisponible) {
                      return EtatSysteme(
                        key: const ValueKey<String>('signature-indisponible'),
                        nature: NatureEtat.indisponible,
                        titre: r.titre,
                        phrase: r.indisponible,
                        dependance: e.dependance,
                      );
                    }
                    if (e is ContratIntrouvable) {
                      return EtatSysteme(
                        key: const ValueKey<String>('signature-introuvable'),
                        nature: NatureEtat.echecServeur,
                        phrase: r.introuvable,
                        onAction: reessayer,
                      );
                    }
                    return horsLigne || e is HorsLigneSignature
                        ? EtatSansDonnees(
                            key: const ValueKey<String>(
                              'signature-sans-donnees',
                            ),
                            quoi: r.sansDonnees,
                            onAction: reessayer,
                          )
                        : EtatSysteme(
                            key: const ValueKey<String>('signature-erreur'),
                            nature: NatureEtat.echecServeur,
                            phrase: r.erreurLecture,
                            onAction: reessayer,
                          );
                  },
                  construire: (ContratEtSignature lu) =>
                      _contenu(lu, horsLigne),
                ),
        ),
      ),
    );
  }

  Widget _contenu(ContratEtSignature lu, bool horsLigne) {
    final r = t.recrutement.signature;
    final ContratCourant contrat = lu.contrat;
    final Signature? signature = lu.signature;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle alerte = palette.inkAlert.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    if (!empreinteConforme(contrat)) {
      return EtatSysteme(
        key: const ValueKey<String>('signature-texte-altere'),
        nature: NatureEtat.echecServeur,
        phrase: r.texteAltere,
        onAction: () => ref.invalidate(contratEnseignantCourantProvider),
      );
    }

    final bool dejaSigne =
        signature != null && signature.version == contrat.version;
    final bool ancienneVersion = signature != null && !dejaSigne;
    final String nomAffiche = dejaSigne ? signature.nomSaisi : _nom.text;

    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          r.version(version: contrat.version.replaceAll('-', '\u2011')),
          style: textes.titleSmall,
        ),
        Ecart.vXs,
        Text(
          r.empreinte(empreinte: _coupuresEmpreinte(contrat.sha256)),
          style: doux,
        ),
        Ecart.vMd,
        AppCard(
          child: SelectableText(
            contrat.texte,
            key: const ValueKey<String>('signature-texte'),
            style: textes.bodyMedium,
          ),
        ),
      ],
    );

    if (dejaSigne) {
      if (_nomFige.text != nomAffiche) _nomFige.text = nomAffiche;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              r.dejaSigne(
                date: dateDeLAppareil(signature.signeLe.toLocal()),
                version: signature.version,
              ),
              key: const ValueKey<String>('signature-deja-signe'),
              style: textes.titleMedium,
            ),
          ),
          Ecart.vXs,
          Text(r.signePar(nom: nomAffiche), style: doux),
          Ecart.vLg,
          texte,
          Ecart.vLg,
          // Lecture seule : la case et le nom restent visibles, figes.
          CaseAccordTexte(libelle: r.accuse, cochee: true, onChanged: null),
          Ecart.vMd,
          ZoneSaisie(
            controleur: _nomFige,
            cleChamp: const ValueKey<String>('signature-nom-fige'),
            libelle: r.champNom,
            lectureSeule: true,
            majuscules: TextCapitalization.words,
          ),
          Ecart.vMd,
          if (_info != null) ...<Widget>[
            Semantics(liveRegion: true, child: Text(_info!, style: doux)),
            Ecart.vMd,
          ],
          // Hors ligne, la copie ne peut pas etre preparee : le lien n'est pas
          // rendu (un bouton qui ne peut pas aboutir n'existe pas).
          if (!horsLigne)
            LienFleche(
              key: const ValueKey<String>('signature-copie'),
              libelle: r.copie,
              onPress: () => unawaited(_copie(contrat)),
            ),
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.commun.continuer,
            niveau: NiveauAction.secondaire,
            onPress: () => GoRouter.of(context).go(Routes.attente),
          ),
        ],
      );
    }

    final bool signable = !_nomVide && _accuse && !_envoi && !horsLigne;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_versionPerimee) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              r.versionPerimee,
              key: const ValueKey<String>('signature-version-perimee'),
              style: alerte,
            ),
          ),
          Ecart.vMd,
        ] else if (ancienneVersion) ...<Widget>[
          Text(
            r.nouvelleVersion(version: signature.version),
            key: const ValueKey<String>('signature-nouvelle-version'),
            style: doux,
          ),
          Ecart.vMd,
        ],
        texte,
        Ecart.vLg,
        ZoneSaisie(
          controleur: _nom,
          cleChamp: const ValueKey<String>('signature-nom'),
          libelle: r.champNom,
          aide: r.aideNom,
          majuscules: TextCapitalization.words,
          actionClavier: TextInputAction.done,
          erreur: _erreurNom ?? (_tente && _nomVide ? r.nomVide : null),
          lectureSeule: _envoi,
          onChanged: (_) => setState(() {
            _erreurNom = null;
          }),
        ),
        Ecart.vMd,
        CaseAccordTexte(
          libelle: r.accuse,
          cochee: _accuse,
          onChanged: _envoi ? null : (bool v) => setState(() => _accuse = v),
        ),
        Ecart.vMd,
        if (_erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              key: const ValueKey<String>('signature-erreur-envoi'),
              style: alerte,
            ),
          ),
          Ecart.vMd,
        ],
        ActionPrincipale(
          key: const ValueKey<String>('signature-signer'),
          libelle: r.signer,
          enCours: _envoi,
          onPress: signable ? () => unawaited(_signer(contrat)) : null,
        ),
      ],
    );
  }
}

// INVITATIONS-PERSONNELLES (lot 7, 07/11/2026), option (a) du garde-cap :
// « Copier le lien d'inscription » d'une ligne gardee pour suivi SANS adresse,
// depuis le menu « Autres gestes » de la candidature (aucun nouvel ecran).
//
// La direction saisit l'adresse que la personne utilisera. Le serveur la
// valide, l'enregistre sur la reponse importee et sur le contact de la ligne,
// et rend le code (`lien_invitation_candidat_importe`). Aucun e-mail ne part :
// la direction transmet le lien elle-meme. La copie passe par le
// presse-papiers ; si elle est refusee, le lien et le code restent affiches et
// selectionnables.
//
// Un seul bouton plein : « Preparer le lien », puis plus aucun. Super
// administrateur en double verification (le serveur reste la barriere).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/candidature/port_invitations_personnelles.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_import_formulaires/import_formulaires_page.dart'
    show EtatDoubleVerification;
import '../mfa_controleur/double_verification.dart';

/// Ouvre la feuille pour la ligne de suivi [candidatureId].
Future<void> ouvrirFeuilleLienPersonnel(
  BuildContext context, {
  required String candidatureId,
}) => AppBottomSheet.ouvrir<void>(
  context,
  titre: t.candidatsFlux.invitationsPersonnelles.lienCopie.titre,
  constructeur: (BuildContext contexte) => FeuilleLienPersonnel(
    candidatureId: candidatureId,
    onFermer: () => Navigator.of(contexte).pop(),
  ),
);

/// Vrai quand la ligne peut recevoir « Copier le lien » : gardee pour suivi,
/// en cours, sans compte et sans adresse connue.
bool ligneSansAdresse({
  required bool recue,
  required bool enCours,
  required bool courrielAObtenir,
}) => recue && enCours && courrielAObtenir;

/// La date dans une phrase : « jusqu'au samedi 21 novembre », jamais une
/// majuscule au milieu (sans effet en arabe).
String _enMinuscule(String date) =>
    date.isEmpty ? date : date[0].toLowerCase() + date.substring(1);

/// Le corps de la feuille.
class FeuilleLienPersonnel extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleLienPersonnel({
    required this.candidatureId,
    required this.onFermer,
    super.key,
  });

  /// La ligne de suivi.
  final String candidatureId;

  /// La feuille se ferme.
  final VoidCallback onFermer;

  /// La cle du champ de l'adresse.
  static const Key cleChamp = ValueKey<String>('lien-personnel-champ');

  /// La cle du bouton qui prepare le lien.
  static const Key clePreparer = ValueKey<String>('lien-personnel-preparer');

  /// La cle du lien rendu.
  static const Key cleLien = ValueKey<String>('lien-personnel-lien');

  /// La cle du code rendu.
  static const Key cleCode = ValueKey<String>('lien-personnel-code');

  /// La cle du geste « Copier le lien ».
  static const Key cleCopier = ValueKey<String>('lien-personnel-copier');

  /// La cle du retour de la copie.
  static const Key cleRetourCopie = ValueKey<String>('lien-personnel-retour');

  /// La cle du refus rendu par le serveur.
  static const Key cleRefus = ValueKey<String>('lien-personnel-refus');

  /// La cle du bandeau « non confirme ».
  static const Key cleNonConfirme = ValueKey<String>(
    'lien-personnel-non-confirme',
  );

  /// La cle du bouton qui ferme.
  static const Key cleFermer = ValueKey<String>('lien-personnel-fermer');

  @override
  ConsumerState<FeuilleLienPersonnel> createState() => _EtatFeuille();
}

class _EtatFeuille extends ConsumerState<FeuilleLienPersonnel> {
  final TextEditingController _adresse = TextEditingController();
  bool _enCours = false;
  LienPret? _pret;
  RefusLien? _refus;
  bool _nonConfirme = false;
  bool _accesRefuse = false;
  bool _doubleRequise = false;
  bool? _copie;

  @override
  void dispose() {
    _adresse.dispose();
    super.dispose();
  }

  Future<void> _preparer() async {
    if (_enCours) return;
    final PortInvitationsPersonnelles? port = ref.read(
      portInvitationsPersonnellesProvider,
    );
    if (port == null) return;
    setState(() {
      _enCours = true;
      _refus = null;
      _nonConfirme = false;
    });
    try {
      final ResultatLien r = await port.lienPour(
        candidatureId: widget.candidatureId,
        courriel: _adresse.text,
      );
      if (!mounted) return;
      setState(() {
        _enCours = false;
        switch (r) {
          case LienPret():
            _pret = r;
          case LienRefuse(:final RefusLien raison):
            _refus = raison;
        }
      });
    } on PermissionInsuffisante {
      if (!mounted) return;
      final CapacitesImportCandidatures? caps = ref
          .read(capacitesImportCandidaturesProvider)
          .value;
      setState(() {
        _enCours = false;
        _doubleRequise = caps != null && caps.doubleVerificationRequise;
        _accesRefuse = !_doubleRequise;
      });
    } on Object {
      // Reseau coupe ou panne : non confirme ; la meme adresse rend le meme
      // code (le serveur reconnait son propre geste).
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _nonConfirme = true;
      });
    }
  }

  Future<void> _monter() async {
    if (await demanderDoubleVerification(context)) {
      ref.invalidate(capacitesImportCandidaturesProvider);
      if (!mounted) return;
      setState(() => _doubleRequise = false);
    }
  }

  Future<void> _copier(String lien) async {
    try {
      await Clipboard.setData(ClipboardData(text: lien));
      if (!mounted) return;
      setState(() => _copie = true);
    } on Object {
      if (!mounted) return;
      setState(() => _copie = false);
    }
  }

  Widget _texte(String texte, {bool fort = false, bool alerte = false}) =>
      TexteSansCoupure(
        texte,
        style:
            (alerte
                    ? AppPalette.of(context).inkAlert
                    : fort
                    ? AppPalette.of(context).inkStrong
                    : AppPalette.of(context).inkMuted)
                .applyTo(
                  (fort
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.bodyMedium) ??
                      const TextStyle(),
                ),
      );

  String _libelleRefus(RefusLien r) {
    final x = t.candidatsFlux.invitationsPersonnelles.lienCopie.refus;
    return switch (r) {
      RefusLien.ligneIntrouvable => x.ligneIntrouvable,
      RefusLien.adresseConnue => x.adresseConnue,
      RefusLien.adresseRequise => x.adresseRequise,
      RefusLien.emailInvalide => x.emailInvalide,
      RefusLien.dejaInscrit => x.dejaInscrit,
      RefusLien.adresseUtilisee => x.adresseUtilisee,
      RefusLien.desinscrit => x.desinscrit,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = t.candidatsFlux.invitationsPersonnelles.lienCopie;
    final LienPret? pret = _pret;
    final RefusLien? refus = _refus;
    final List<Widget> corps = <Widget>[_texte(l.contexte), Ecart.vLg];

    if (_doubleRequise) {
      corps.add(EtatDoubleVerification(onAction: () => unawaited(_monter())));
    } else if (_accesRefuse) {
      corps.add(
        EtatSysteme(
          nature: NatureEtat.accesRefuse,
          titre: t.candidatsFlux.importFormulaires.acces.refuseTitre,
          phrase: t.candidatsFlux.importFormulaires.acces.refusePhrase,
        ),
      );
    } else if (pret == null) {
      corps.add(
        KeyedSubtree(
          key: FeuilleLienPersonnel.cleChamp,
          child: ChampEtiquete(
            libelle: l.champ,
            controller: _adresse,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      );
      if (refus != null) {
        corps
          ..add(Ecart.vSm)
          ..add(
            Semantics(
              liveRegion: true,
              child: KeyedSubtree(
                key: FeuilleLienPersonnel.cleRefus,
                child: _texte(_libelleRefus(refus), alerte: true),
              ),
            ),
          );
      }
      if (_nonConfirme) {
        corps
          ..add(Ecart.vLg)
          ..add(
            BandeauAttention(
              key: FeuilleLienPersonnel.cleNonConfirme,
              titre: t.candidatsFlux.prevenir.erreurs.titre,
              message: l.nonConfirme,
              ton: TonEtat.avertissement,
            ),
          );
      }
      corps
        ..add(Ecart.vXxl)
        ..add(
          ActionPrincipale(
            key: FeuilleLienPersonnel.clePreparer,
            libelle: _nonConfirme ? t.commun.reessayer : l.preparer,
            onPress: () => unawaited(_preparer()),
            enCours: _enCours,
          ),
        );
    } else {
      final bool? copie = _copie;
      corps.addAll(<Widget>[
        _texte(l.code, fort: true),
        Ecart.vXs,
        SelectableText(
          pret.code,
          key: FeuilleLienPersonnel.cleCode,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vLg,
        _texte(l.lien, fort: true),
        Ecart.vXs,
        SelectableText(
          pret.lien,
          key: FeuilleLienPersonnel.cleLien,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Ecart.vSm,
        _texte(
          l.echeance(
            date: _enMinuscule(dateDeLAppareil(pret.expireLe.toLocal())),
          ),
        ),
        Ecart.vLg,
        LienFleche(
          key: FeuilleLienPersonnel.cleCopier,
          libelle: l.copier,
          alignerEnFin: true,
          onPress: () => unawaited(_copier(pret.lien)),
        ),
        if (copie != null) ...<Widget>[
          Ecart.vXs,
          Semantics(
            liveRegion: true,
            child: KeyedSubtree(
              key: FeuilleLienPersonnel.cleRetourCopie,
              child: _texte(
                copie ? l.copie : l.copieEchec,
                fort: copie,
                alerte: !copie,
              ),
            ),
          ),
        ],
      ]);
    }
    corps
      ..add(Ecart.vXxl)
      ..add(
        ActionPrincipale(
          key: FeuilleLienPersonnel.cleFermer,
          libelle: t.commun.fermer,
          onPress: widget.onFermer,
          niveau: NiveauAction.secondaire,
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: corps,
    );
  }
}

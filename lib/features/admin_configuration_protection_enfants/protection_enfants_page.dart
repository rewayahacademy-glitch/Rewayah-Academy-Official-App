import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_configuration.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/conformite/representant_ue.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/protection_enfants/responsable_protection.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/zone_saisie.dart';

/// Configuration > Protection des enfants (PE, 18/10/2026) : le responsable
/// de la protection des enfants, que l'administration nomme elle-meme.
///
/// Deux reglages de `app_config` (`protection_enfants.responsable_nom` et
/// `protection_enfants.responsable_courriel`), vides par defaut. Ils sont lus
/// par l'ecran « Signaler un besoin » des enseignants ; vides, cet ecran dit
/// que la direction recoit le signalement. L'ecriture suit les policies
/// d'`app_config` (administration seulement) et un declencheur de la base
/// verifie le format ; l'ecran ne fait que prevenir (courriel plausible, nom
/// court).
///
/// Le representant dans l'Union europeenne (19/10/2026) est regle ici aussi, en
/// dessous : un reglage de `app_config` (`conformite.representant_ue`), vide
/// par defaut ; vide, les textes juridiques affichent « Rewayah Academy ». Il
/// a sa propre lecture, donc ses propres etats.
///
/// Etats : chargement (squelette), contenu (deux lignes, puis le representant),
/// vide (« Non renseigne » sur chaque ligne, cas normal), erreur de lecture
/// (avec « Reessayer »), hors ligne (meme rendu que l'erreur : la lecture et
/// l'ecriture passent par le reseau).
class ProtectionEnfantsPage extends ConsumerWidget {
  /// Cree l'ecran.
  const ProtectionEnfantsPage({super.key});

  /// La cle de la ligne du nom.
  static const Key nomKey = ValueKey<String>('protection-enfants-nom');

  /// La cle de la ligne du courriel.
  static const Key courrielKey = ValueKey<String>(
    'protection-enfants-courriel',
  );

  /// La cle de la ligne du representant dans l'Union europeenne.
  static const Key representantKey = ValueKey<String>(
    'protection-enfants-representant',
  );

  /// La cle du champ de saisie de la feuille.
  static const Key champKey = ValueKey<String>('protection-enfants-champ');

  /// La cle du bouton d'enregistrement de la feuille.
  static const Key enregistrerKey = ValueKey<String>(
    'protection-enfants-enregistrer',
  );

  /// Les onglets de Configuration, avec celui-ci en dernier.
  static int indexOnglet({required bool politiqueRevueKyc}) =>
      politiqueRevueKyc ? 4 : 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<ResponsableProtection> lecture = ref.watch(
      responsableProtectionProvider,
    );
    final AsyncValue<String> representant = ref.watch(representantUeProvider);
    final bool kyc = ref.watch(peutReglerPolitiqueKycProvider);

    return PageShell(
      titre: t.admin.protectionEnfants.titre,
      entete: SousNavigationDomaine(
        onglets: ongletsConfiguration(politiqueRevueKyc: kyc),
        indexActif: indexOnglet(politiqueRevueKyc: kyc),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.admin.protectionEnfants.intro, style: textes.bodyMedium),
          Ecart.vXl,
          switch (lecture) {
            AsyncValue<ResponsableProtection>(hasValue: true) => _Corps(
              responsable: lecture.requireValue,
            ),
            AsyncValue<ResponsableProtection>(hasError: true) => EmptyState(
              message: t.admin.protectionEnfants.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(responsableProtectionProvider),
            ),
            _ => const Skeleton.liste(lignes: 2),
          },
          Ecart.vXl,
          Semantics(
            header: true,
            child: Text(
              t.admin.protectionEnfants.representantTitre,
              style: textes.titleMedium,
            ),
          ),
          Ecart.vSm,
          switch (representant) {
            AsyncValue<String>(hasValue: true) => _LigneRepresentant(
              nom: representant.requireValue,
            ),
            AsyncValue<String>(hasError: true) => EmptyState(
              message: t.admin.protectionEnfants.representantErreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(representantUeProvider),
            ),
            _ => const Skeleton.liste(lignes: 1),
          },
        ],
      ),
    );
  }
}

class _Corps extends ConsumerWidget {
  const _Corps({required this.responsable});

  final ResponsableProtection responsable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = t.admin.protectionEnfants;
    return CarteLignes(
      lignes: <Widget>[
        SettingRow(
          key: ProtectionEnfantsPage.nomKey,
          title: l.nom,
          description: l.nomDetail,
          value: responsable.estNomme ? responsable.nom : l.nonRenseigne,
          icon: AppIcons.profil,
          onPress: () => _ouvrir(
            context,
            ref,
            cle: ClesProtectionEnfants.nom,
            titre: l.nom,
            champ: l.champNom,
            valeur: responsable.nom,
            courriel: false,
          ),
        ),
        SettingRow(
          key: ProtectionEnfantsPage.courrielKey,
          title: l.courriel,
          description: l.courrielDetail,
          value: responsable.aUnCourriel
              ? responsable.courriel
              : l.nonRenseigne,
          icon: AppIcons.envoyerMessage,
          onPress: () => _ouvrir(
            context,
            ref,
            cle: ClesProtectionEnfants.courriel,
            titre: l.courriel,
            champ: l.champCourriel,
            valeur: responsable.courriel,
            courriel: true,
          ),
        ),
      ],
    );
  }

  void _ouvrir(
    BuildContext context,
    WidgetRef ref, {
    required String cle,
    required String titre,
    required String champ,
    required String valeur,
    required bool courriel,
  }) {
    unawaited(
      AppBottomSheet.ouvrir<void>(
        context,
        titre: titre,
        constructeur: (BuildContext _) => FeuilleResponsable(
          cle: cle,
          champ: champ,
          valeurInitiale: valeur,
          courriel: courriel,
          onEcrit: () => ref.invalidate(responsableProtectionProvider),
        ),
      ),
    );
  }
}

class _LigneRepresentant extends ConsumerWidget {
  const _LigneRepresentant({required this.nom});

  final String nom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = t.admin.protectionEnfants;
    return CarteLignes(
      lignes: <Widget>[
        SettingRow(
          key: ProtectionEnfantsPage.representantKey,
          title: l.representantTitre,
          description: l.representantDetail,
          value: nom.isNotEmpty ? nom : l.nonRenseigne,
          icon: AppIcons.profil,
          onPress: () => unawaited(
            AppBottomSheet.ouvrir<void>(
              context,
              titre: l.representantTitre,
              constructeur: (BuildContext _) => FeuilleResponsable(
                cle: ClesConformite.representantUe,
                champ: l.representantChamp,
                valeurInitiale: nom,
                courriel: false,
                aide: l.representantVideAide,
                onEcrit: () => ref.invalidate(representantUeProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La feuille de saisie d'un des reglages (le responsable, son courriel, ou
/// le representant dans l'Union europeenne).
class FeuilleResponsable extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleResponsable({
    required this.cle,
    required this.champ,
    required this.valeurInitiale,
    required this.courriel,
    required this.onEcrit,
    this.aide,
    super.key,
  });

  /// La cle `app_config` a ecrire.
  final String cle;

  /// Le libelle du champ.
  final String champ;

  /// La valeur actuelle (vide si rien n'est saisi).
  final String valeurInitiale;

  /// Vrai pour le courriel : le format est verifie.
  final bool courriel;

  /// Appele apres une ecriture reussie.
  final VoidCallback onEcrit;

  /// L'aide sous le champ ; par defaut celle du responsable.
  final String? aide;

  @override
  ConsumerState<FeuilleResponsable> createState() => _FeuilleResponsableEtat();
}

class _FeuilleResponsableEtat extends ConsumerState<FeuilleResponsable> {
  late final TextEditingController _champ = TextEditingController(
    text: widget.valeurInitiale,
  );
  bool _envoi = false;
  String? _erreur;

  // Meme forme que le declencheur de la base : une adresse plausible.
  static final RegExp _forme = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final String texte = _champ.text.trim();
    if (widget.courriel && texte.isNotEmpty) {
      if (texte.length > 254 || !_forme.hasMatch(texte)) {
        setState(() => _erreur = t.admin.protectionEnfants.courrielInvalide);
        return;
      }
    } else if (!widget.courriel && texte.length > 120) {
      setState(() => _erreur = t.admin.protectionEnfants.nomTropLong);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(serviceConfigurationProvider).ecrire(widget.cle, texte);
      widget.onEcrit();
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = t.admin.protectionEnfants.erreurEcriture(
            message: _message(e),
          );
        });
      }
    }
  }

  static String _message(Object erreur) {
    final String brut = erreur.toString();
    final int deuxPoints = brut.indexOf(': ');
    return deuxPoints >= 0 && deuxPoints + 2 < brut.length
        ? brut.substring(deuxPoints + 2)
        : brut;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ZoneSaisie(
          cleChamp: ProtectionEnfantsPage.champKey,
          controleur: _champ,
          libelle: widget.champ,
          explication: widget.aide ?? t.admin.protectionEnfants.videAide,
          erreur: _erreur,
          onChanged: (String _) {
            if (_erreur != null) setState(() => _erreur = null);
          },
        ),
        Ecart.vLg,
        ActionPrincipale(
          key: ProtectionEnfantsPage.enregistrerKey,
          libelle: t.admin.protectionEnfants.enregistrer,
          enCours: _envoi,
          onPress: _envoi ? null : () => unawaited(_enregistrer()),
        ),
      ],
    );
  }
}

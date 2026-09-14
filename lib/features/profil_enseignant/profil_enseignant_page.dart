import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';

/// Profil enseignant courant, en lecture seule.
class ProfilEnseignantPage extends ConsumerWidget {
  /// Crée la page du profil enseignant.
  const ProfilEnseignantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProfilEnseignant?> profil = ref.watch(
      profilEnseignantProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return PageShell(
      titre: t.enseignant.profil.titre,
      entete: Text(t.enseignant.profil.intro),
      child: profil.hasValue && profil.requireValue != null
          ? _Contenu(profil: profil.requireValue!)
          : horsLigne
          ? EmptyState(
              message: t.enseignant.profil.horsLigne,
              invitation: t.enseignant.profil.horsLigneDetail,
              icone: AppIcons.avertissement,
              registre: RegistreVide.subi,
            )
          : profil.hasError
          ? EmptyState(
              message: t.enseignant.profil.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.enseignant.profil.reessayer,
              onAction: () => ref.invalidate(profilEnseignantProvider),
            )
          : profil.hasValue
          ? EmptyState(
              message: t.enseignant.profil.vide,
              invitation: t.enseignant.profil.videDetail,
              icone: AppIcons.profil,
              registre: RegistreVide.subi,
            )
          : Semantics(
              container: true,
              liveRegion: true,
              label: t.commun.chargement,
              child: const Skeleton.texte(lignes: 5),
            ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.profil});

  final ProfilEnseignant profil;

  @override
  Widget build(BuildContext context) {
    final Widget identite = AppCard(
      dominante: true,
      child: _EnteteProfil(profil: profil),
    );
    final Widget informations = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.profil.identite),
        _LigneProfil(
          titre: t.enseignant.profil.pays,
          valeur: _valeur(profil.pays),
          icon: AppIcons.foyer,
        ),
        _LigneProfil(
          titre: t.enseignant.profil.langues,
          valeur: profil.langues.isEmpty
              ? t.compte.nonDisponible
              : profil.langues.join(', '),
          icon: AppIcons.reglages,
        ),
        _LigneProfil(
          titre: t.enseignant.profil.capacite,
          valeur: profil.plafondHeures == null
              ? t.compte.nonDisponible
              : t.enseignant.profil.heures(nombre: '${profil.plafondHeures}'),
          icon: AppIcons.journee,
        ),
        _LigneProfil(
          titre: t.enseignant.profil.verification,
          valeur: _verification(profil.verification),
          icon: AppIcons.controleQualite,
        ),
        _LigneProfil(
          titre: t.enseignant.profil.statut,
          valeur: _statut(profil.statutCompte),
          icon: AppIcons.controleQualite,
        ),
      ],
    );

    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: identite),
          const SizedBox(width: AppSpacing.section),
          Expanded(child: informations),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[identite, Ecart.vSection, informations],
    );
  }

  String _valeur(String? valeur) {
    final String texte = valeur?.trim() ?? '';
    return texte.isEmpty ? t.compte.nonDisponible : texte;
  }

  String _verification(VerificationEnseignant? valeur) => switch (valeur) {
    VerificationEnseignant.enAttente =>
      t.enseignant.profil.verificationEnAttente,
    VerificationEnseignant.validee => t.enseignant.profil.verificationValidee,
    VerificationEnseignant.refusee => t.enseignant.profil.verificationRefusee,
    null => t.compte.nonDisponible,
  };

  String _statut(AccountStatus? valeur) => switch (valeur) {
    AccountStatus.active => t.compte.statutActif,
    AccountStatus.provisionalActive => t.compte.statutProvisoire,
    AccountStatus.pendingKyc => t.enseignant.profil.statutEnAttente,
    AccountStatus.disabled => t.enseignant.profil.statutSuspendu,
    null => t.compte.nonDisponible,
  };
}

class _EnteteProfil extends StatelessWidget {
  const _EnteteProfil({required this.profil});

  final ProfilEnseignant profil;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AvatarTile(prenom: profil.prenom),
        Ecart.hLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                profil.prenom.isEmpty ? t.compte.nonDisponible : profil.prenom,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Ecart.vXs,
              Text(
                profil.identifiant.isEmpty
                    ? t.compte.nonDisponible
                    : profil.identifiant,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LigneProfil extends StatelessWidget {
  const _LigneProfil({
    required this.titre,
    required this.valeur,
    required this.icon,
  });

  final String titre;
  final String valeur;
  final AppIcon icon;

  @override
  Widget build(BuildContext context) {
    return SettingRow(title: titre, value: valeur, icon: icon, enabled: false);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/fluidite/action_anticipee.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/avatar_compte.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';
import 'lignes_compte.dart';

/// Les informations personnelles du titulaire du compte, tous roles : le
/// tuteur (`/tuteur/compte/informations`) et l'enseignant
/// (`/enseignant/profil/informations`, COMPTE-ENSEIGNANT-IDENTITE, 12/11/2026),
/// en lecture seule.
///
/// Aucune ecriture n'existe pour le tuteur (DB-CPT-01) : pas de formulaire,
/// pas de bouton « Modifier » qui ne pourrait pas aboutir ; une phrase le dit.
/// Pas de telephone ni de ville : aucune colonne ne les porte pour le tuteur.
/// Le fuseau est celui du profil, lu par `mon_horloge()` (garde-cap,
/// 12/11/2026) : sans fuseau de profil, la ligne dit « Heure de cet
/// appareil », jamais une ville supposee (`mon_fuseau()` se repliait sur
/// Paris).
class InformationsComptePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const InformationsComptePage({super.key, this.onRetour});

  /// Le retour de l'en-tete ; par defaut, le Compte du tuteur. « Mon
  /// espace » de l'eleve adulte (EA-4) y passe son propre retour.
  final VoidCallback? onRetour;

  /// « Modifier mes informations » (EDIT-INFOS-PERSO).
  static const Key modifierKey = Key('informations.modifier');

  /// Le champ du prenom, dans la feuille.
  static const Key champPrenomKey = Key('informations.champPrenom');

  /// Le champ du nom, dans la feuille.
  static const Key champNomKey = Key('informations.champNom');

  /// « Enregistrer », dans la feuille.
  static const Key enregistrerKey = Key('informations.enregistrer');

  /// La phrase d'echec, apres un retour en arriere.
  static const Key echecKey = Key('informations.echec');

  /// « Reessayer », apres un echec.
  static const Key reessayerKey = Key('informations.reessayer');

  /// La phrase hors ligne, a la place de « Modifier ».
  static const Key horsLigneKey = Key('informations.horsLigne');

  @override
  ConsumerState<InformationsComptePage> createState() =>
      _InformationsComptePageState();
}

/// Un prenom et un nom affiches.
typedef NomsAffiches = ({String prenom, String nom});

class _InformationsComptePageState
    extends ConsumerState<InformationsComptePage> {
  /// Les noms affiches d'avance (DECISION-FLUIDITE §1), ou `null` : ceux que
  /// le serveur a rendus.
  NomsAffiches? _affiche;

  /// Les derniers noms envoyes, pour « Reessayer ».
  NomsAffiches? _essai;
  ActionAnticipee? _action;
  bool _echec = false;

  @override
  void dispose() {
    _action?.dispose();
    super.dispose();
  }

  /// Envoie [noms] : affiches tout de suite, remis comme avant si le serveur
  /// refuse ou ne repond pas, avec la phrase d'echec ; aucun message de
  /// succes.
  void _envoyer(NomsAffiches noms) {
    if (_action?.etat == EtatAnticipe.enCours) return;
    final NomsAffiches? avant = _affiche;
    final ProviderContainer conteneur = ProviderScope.containerOf(
      context,
      listen: false,
    );
    _action?.dispose();
    final ActionAnticipee action = ActionAnticipee(
      nature: NatureAction.instantanee,
      cle: 'identite:${noms.prenom}:${noms.nom}',
      envoi: (String _) => conteneur
          .read(portIdentiteTitulaireProvider)
          .modifier(prenom: noms.prenom, nom: noms.nom),
      annuler: () {
        if (!mounted) return;
        setState(() {
          _affiche = avant;
          _echec = true;
        });
      },
    );
    _action = action;
    setState(() {
      _affiche = noms;
      _essai = noms;
      _echec = false;
    });
    unawaited(
      action.tenter(
        // Les noms affiches restent : le serveur les a confirmes. Le Compte
        // (en-tete du tuteur, de l'enseignant et du Compte commun, cercle de
        // la barre) relit les siens.
        siConfirme: () {
          conteneur
            ..invalidate(identiteTitulaireProvider)
            ..invalidate(prenomDuCompteProvider)
            ..invalidate(profilEnseignantProvider);
        },
      ),
    );
  }

  Future<void> _ouvrirFeuille(NomsAffiches actuels) =>
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.compte.tuteur.pageInformations.modifier,
        constructeur: (BuildContext contexte) => FeuilleNoms(
          actuels: actuels,
          onEnregistrer: (NomsAffiches noms) {
            Navigator.of(contexte).pop();
            _envoyer(noms);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onRetour = widget.onRetour;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // EDIT-INFOS-PERSO : « Modifier » se lit sur la capacite servie, jamais
    // sur le role ; absente tant qu'elle n'est pas lue.
    final bool peutModifier =
        ref.watch(peutModifierMonIdentiteProvider).value ?? false;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<MonHorloge?> horloge = ref.watch(monHorlogeProvider);
    final String valeurFuseau = switch (horloge) {
      AsyncValue<MonHorloge?>(hasError: true) =>
        t.compte.tuteur.pageInformations.fuseauAppareil,
      AsyncValue<MonHorloge?>(hasValue: true, :final MonHorloge? value) =>
        switch (value?.moi?.fuseau) {
          final String fuseau when fuseau.trim().isNotEmpty =>
            villeDuFuseauLibelle(fuseau),
          _ => t.compte.tuteur.pageInformations.fuseauAppareil,
        },
      _ => t.compte.tuteur.pageInformations.fuseauIndisponible,
    };

    return PageShell(
      titre: t.compte.tuteur.pageInformations.titre,
      onRetour: onRetour ?? () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: BlocAsynchrone<IdentiteTitulaire>(
          valeur: ref.watch(identiteTitulaireProvider),
          squelette: const Skeleton.liste(lignes: 4),
          onReessayer: () => ref.invalidate(identiteTitulaireProvider),
          construire: (IdentiteTitulaire identite) {
            final NomsAffiches noms =
                _affiche ?? (prenom: identite.prenom, nom: identite.nom);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GroupeReglages(
                  lignes: <LigneRubrique>[
                    LigneRubrique(
                      icone: AppIcons.profil,
                      libelle: t.compte.tuteur.pageInformations.prenom,
                      valeur: _ou(noms.prenom),
                    ),
                    LigneRubrique(
                      icone: AppIcons.profil,
                      libelle: t.compte.tuteur.pageInformations.nom,
                      valeur: _ou(noms.nom),
                    ),
                    LigneRubrique(
                      icone: AppIcons.dossiers,
                      libelle: t.compte.tuteur.pageInformations.courriel,
                      valeur:
                          identite.courriel ??
                          t.compte.tuteur.identite.courrielAbsent,
                    ),
                    LigneRubrique(
                      icone: AppIcons.direction,
                      libelle: t.compte.tuteur.pageInformations.langue,
                      valeur: nomLangueCompte(langueEffective(context)),
                    ),
                    LigneRubrique(
                      icone: AppIcons.historique,
                      libelle: t.compte.tuteur.pageInformations.fuseau,
                      valeur: valeurFuseau,
                    ),
                  ],
                ),
                if (peutModifier) ...<Widget>[
                  Ecart.vLg,
                  if (horsLigne)
                    Text(
                      key: InformationsComptePage.horsLigneKey,
                      t.compte.tuteur.pageInformations.horsLigne,
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    )
                  else
                    ActionPrincipale(
                      key: InformationsComptePage.modifierKey,
                      libelle: t.compte.tuteur.pageInformations.modifier,
                      niveau: NiveauAction.secondaire,
                      onPress: () => unawaited(_ouvrirFeuille(noms)),
                    ),
                  if (_echec) ...<Widget>[
                    Ecart.vMd,
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        key: InformationsComptePage.echecKey,
                        t.compte.tuteur.pageInformations.echec,
                        style: palette.inkAlert.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                    if (!horsLigne && _essai != null)
                      LienFleche(
                        key: InformationsComptePage.reessayerKey,
                        libelle: t.commun.reessayer,
                        onPress: () => _envoyer(_essai!),
                      ),
                  ],
                ],
                Ecart.vLg,
                Text(
                  peutModifier
                      ? t.compte.tuteur.pageInformations.noteModifiable
                      : t.compte.tuteur.pageInformations.note,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _ou(String valeur) =>
      valeur.trim().isEmpty ? t.compte.nonDisponible : valeur.trim();
}

/// La feuille « Modifier mes informations » : le prenom et le nom, rien
/// d'autre (l'adresse de connexion se change avec l'academie).
class FeuilleNoms extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleNoms({
    required this.actuels,
    required this.onEnregistrer,
    super.key,
  });

  /// Les noms affiches a l'ouverture.
  final NomsAffiches actuels;

  /// Rend les noms rognes, seulement s'ils peuvent partir et ont change.
  final ValueChanged<NomsAffiches> onEnregistrer;

  @override
  State<FeuilleNoms> createState() => _FeuilleNomsState();
}

class _FeuilleNomsState extends State<FeuilleNoms> {
  late final TextEditingController _prenom = TextEditingController(
    text: widget.actuels.prenom,
  );
  late final TextEditingController _nom = TextEditingController(
    text: widget.actuels.nom,
  );
  bool _tente = false;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  String? _message(DefautNom? defaut, String vide) => switch (defaut) {
    null => null,
    DefautNom.vide => vide,
    DefautNom.tropLong => t.compte.tuteur.pageInformations.tropLong,
  };

  void _enregistrer() {
    if (defautNom(_prenom.text) != null || defautNom(_nom.text) != null) {
      setState(() => _tente = true);
      return;
    }
    final NomsAffiches noms = (
      prenom: _prenom.text.trim(),
      nom: _nom.text.trim(),
    );
    // Rien n'a change : la feuille se ferme, rien ne part (garde-cap,
    // 12/11/2026).
    if (noms.prenom == widget.actuels.prenom.trim() &&
        noms.nom == widget.actuels.nom.trim()) {
      Navigator.of(context).pop();
      return;
    }
    widget.onEnregistrer(noms);
  }

  @override
  Widget build(BuildContext context) {
    final String? erreurPrenom = _tente
        ? _message(
            defautNom(_prenom.text),
            t.compte.tuteur.pageInformations.prenomVide,
          )
        : null;
    final String? erreurNom = _tente
        ? _message(
            defautNom(_nom.text),
            t.compte.tuteur.pageInformations.nomVide,
          )
        : null;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ChampEtiquete(
            libelle: t.compte.tuteur.pageInformations.prenom,
            controller: _prenom,
            cleChamp: InformationsComptePage.champPrenomKey,
            erreur: erreurPrenom,
            obligatoire: true,
            textCapitalization: TextCapitalization.words,
            remplissage: const <String>[AutofillHints.givenName],
            actionClavier: TextInputAction.next,
            onChanged: (String _) {
              if (_tente) setState(() {});
            },
          ),
          Ecart.vMd,
          ChampEtiquete(
            libelle: t.compte.tuteur.pageInformations.nom,
            controller: _nom,
            cleChamp: InformationsComptePage.champNomKey,
            erreur: erreurNom,
            obligatoire: true,
            textCapitalization: TextCapitalization.words,
            remplissage: const <String>[AutofillHints.familyName],
            actionClavier: TextInputAction.done,
            onSubmitted: (String _) => _enregistrer(),
            onChanged: (String _) {
              if (_tente) setState(() {});
            },
          ),
          Ecart.vLg,
          ActionPrincipale(
            key: InformationsComptePage.enregistrerKey,
            libelle: t.compte.tuteur.pageInformations.enregistrer,
            onPress: _enregistrer,
          ),
        ],
      ),
    );
  }
}

/// L2-05 : « Nouvelle offre », la tache focalisee de creation d'une offre
/// vitrine (`PageParcours`, une seule etape).
///
/// Decision du directeur du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09.md`
/// §1) : l'administration cree a l'avance les creneaux de la vitrine ; ils ne
/// portent **aucun enseignant**. Cet ecran n'en choisit donc aucun.
///
/// Ce que l'ecran lit au serveur (port) et n'ecrit jamais en dur : les langues
/// de cours, le nombre de seances par semaine (le serveur refuse un autre
/// nombre de jours), les durees par defaut. L'heure est une heure pleine
/// (0 a 23), comme `offres_horaires.heure_locale`.
///
/// Refus honnetes (K-59) : le bouton reste actif, la phrase sous lui dit ce
/// qui manque (« Choisissez au moins un jour ») ou ce que le serveur a refuse ;
/// hors ligne, une phrase dit que l'offre sera creee au retour du reseau.
///
/// Etats : chargement des regles (`Skeleton`), contenu, erreur (« Reessayer »),
/// hors ligne (`EtatSansDonnees` si rien n'a pu etre lu).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/offres/offre_horaire.dart' show LangueCours, PublicOffre;
import '../../core/offres/port_offres_admin.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart' show LibellesGroupe;
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/champ_etiquete.dart' show TitreChamp;
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_parcours.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_groupes/bas_de_feuille.dart' show MessageAlerte;
import '../admin_regroupements/regroupements_libelles.dart'
    show libelleHeureMinute, nomPublic;
import '../creneaux/plages.dart' show jourCapitalise;
import 'offres_libelles.dart';

/// La page de creation. Se ferme sur `true` quand l'offre est creee.
class NouvelleOffrePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const NouvelleOffrePage({super.key});

  @override
  ConsumerState<NouvelleOffrePage> createState() => _NouvelleOffrePageEtat();
}

class _NouvelleOffrePageEtat extends ConsumerState<NouvelleOffrePage> {
  PublicOffre _public = PublicOffre.enfants;
  String? _langue;
  String _fuseau = fuseauParDefaut;
  final Set<int> _jours = <int>{};
  int _heure = heureParDefaut;
  int? _duree;
  bool _envoi = false;
  String? _message;

  void _relire() => ref.invalidate(reglesCreationOffreProvider);

  Future<void> _envoyer(ReglesCreationOffre? regles) async {
    if (_envoi) return;
    final f = t.admin.offres.formulaire;
    final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
    if (horsLigne) {
      setState(() => _message = f.horsLigne);
      return;
    }
    final String? langue = _langue ?? regles?.langues.firstOrNull?.code;
    final int? attendu = regles?.regles.seancesParSemaine;
    final String? manque = langue == null
        ? f.manqueLangue
        : _jours.isEmpty
        ? f.manqueJour
        : (attendu != null && _jours.length != attendu)
        ? LibellesGroupe.insecable(f.manqueNombre(n: '$attendu'))
        : null;
    if (manque != null) {
      setState(() => _message = manque);
      return;
    }
    setState(() {
      _envoi = true;
      _message = null;
    });
    final String? echec = await _creer(regles, langue!);
    if (!mounted) return;
    if (echec != null) {
      setState(() {
        _envoi = false;
        _message = echec;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  /// Envoie la creation et rend la phrase du refus, ou `null` quand le serveur
  /// l'a confirmee.
  ///
  /// **Une fonction a part, et la raison est une cause trouvee dans le
  /// navigateur (L2-05-reprise, D-3).** Ecrit en ligne (`String? echec;` puis
  /// `try { await port.creer(...) } catch { echec = ... }` dans `_envoyer`),
  /// le code compile par dart2js en release donnait a `echec`, apres un
  /// `await` reussi dont le resultat est ignore, la valeur d'un autre
  /// registre : le formulaire lisait un refus, restait ouvert et ne relisait
  /// pas la liste, alors que l'offre etait creee. Les tests widget (VM, et
  /// `--platform chrome`) ne le voient pas. Ici le resultat passe par un
  /// `return`, jamais par une variable affectee dans un `catch` apres un
  /// `await`.
  Future<String?> _creer(ReglesCreationOffre? regles, String langue) async {
    final PortOffresAdmin port = ref.read(portOffresAdminProvider);
    try {
      await port.creer(
        typePublic: _public.valeurSql,
        langueCode: langue,
        fuseauIana: _fuseau,
        jours: (_jours.toList()..sort()),
        heureLocale: _heure,
        dureeMinutes: _duree ?? regles?.dureeParDefaut(_public),
      );
      return null;
    } on OffreAdminRefusee catch (e) {
      return t.admin.offres.refusee(motif: e.message);
    } on Object {
      return t.admin.offres.nonConfirmee;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = t.admin.offres.formulaire;
    final AsyncValue<ReglesCreationOffre> valeur = ref.watch(
      reglesCreationOffreProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final ReglesCreationOffre? regles = valeur.value;

    return PageParcours(
      numero: 1,
      total: 1,
      question: f.question,
      explication: f.explication,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BlocAsynchrone<ReglesCreationOffre>(
            key: const ValueKey<String>('nouvelle-offre-bloc'),
            valeur: valeur,
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: _relire,
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                horsLigne
                ? EtatSansDonnees(
                    key: const ValueKey<String>('nouvelle-offre-sans-donnees'),
                    quoi: f.regles,
                    onAction: reessayer,
                  )
                : EtatSysteme(
                    key: const ValueKey<String>('nouvelle-offre-erreur'),
                    nature: NatureEtat.echecServeur,
                    phrase: f.regles,
                    onAction: reessayer,
                  ),
            construire: _champs,
          ),
          if (_message != null) ...<Widget>[
            Ecart.vXl,
            KeyedSubtree(
              key: const ValueKey<String>('nouvelle-offre-message'),
              child: MessageAlerte(_message!),
            ),
          ],
        ],
      ),
      libelleAction: f.creer,
      onAction: _envoi || regles == null
          ? null
          : () => unawaited(_envoyer(regles)),
      onRetour: _envoi ? null : () => Navigator.of(context).pop(false),
      enCours: _envoi,
    );
  }

  Widget _champs(ReglesCreationOffre regles) {
    final f = t.admin.offres.formulaire;
    final TextTheme textes = Theme.of(context).textTheme;
    final List<LangueCours> langues = regles.langues;
    final String? langue = _langue ?? langues.firstOrNull?.code;
    final int dureeDefaut = regles.dureeParDefaut(_public);
    final int duree = _duree ?? dureeDefaut;
    final List<int> durees = (<int>{dureeDefaut, 45, 60}.toList()..sort());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TitreChamp(f.public, style: textes.titleMedium, obligatoire: true),
        Ecart.vMd,
        ChoiceCardGroup(
          key: const ValueKey<String>('offre-public'),
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{_public.valeurSql}),
          options: <OptionChoix>[
            for (final PublicOffre p in PublicOffre.values)
              OptionChoix(
                cle: ValueKey<String>('offre-public-${p.valeurSql}'),
                valeur: p.valeurSql,
                libelle: nomPublic(p),
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            _public = PublicOffre.depuisSql(r.valeurs.firstOrNull);
            _duree = null;
            _message = null;
          }),
        ),
        Ecart.vXxl,
        TitreChamp(f.langue, style: textes.titleMedium, obligatoire: true),
        Ecart.vMd,
        ChoiceCardGroup(
          key: const ValueKey<String>('offre-langue'),
          autoriserSaisieLibre: false,
          valeurInitiale: langue == null
              ? null
              : ReponseChoix(valeurs: <String>{langue}),
          options: <OptionChoix>[
            for (final LangueCours l in langues)
              OptionChoix(
                cle: ValueKey<String>('offre-langue-${l.code}'),
                valeur: l.code,
                libelle: l.nom,
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            _langue = r.valeurs.firstOrNull;
            _message = null;
          }),
        ),
        Ecart.vXxl,
        TitreChamp(f.fuseau, style: textes.titleMedium, obligatoire: true),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<String>(
            key: const ValueKey<String>('offre-fuseau'),
            libelle: f.fuseau,
            valeur: _fuseau,
            entrees: <EntreeFiltre<String>>[
              for (final String z in fuseauxProposes)
                EntreeFiltre<String>(
                  valeur: z,
                  libelle: villeDuFuseauLibelle(z),
                ),
            ],
            onChoix: (String? z) => setState(() {
              _fuseau = z ?? fuseauParDefaut;
              _message = null;
            }),
          ),
        ),
        Ecart.vXxl,
        TitreChamp(f.jours, style: textes.titleMedium, obligatoire: true),
        Ecart.vXs,
        Text(
          LibellesGroupe.insecable(
            f.joursAide(n: '${regles.regles.seancesParSemaine}'),
          ),
          style: textes.bodySmall,
        ),
        Ecart.vMd,
        ChoiceCardGroup(
          key: const ValueKey<String>('offre-jours'),
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          options: <OptionChoix>[
            for (int j = 1; j <= 7; j++)
              OptionChoix(
                cle: ValueKey<String>('offre-jour-$j'),
                valeur: '$j',
                libelle: jourCapitalise(j),
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            _jours
              ..clear()
              ..addAll(r.valeurs.map(int.parse));
            _message = null;
          }),
        ),
        Ecart.vXxl,
        TitreChamp(f.heure, style: textes.titleMedium, obligatoire: true),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<int>(
            key: const ValueKey<String>('offre-heure'),
            libelle: f.heure,
            valeur: _heure,
            entrees: <EntreeFiltre<int>>[
              for (int h = 0; h < 24; h++)
                EntreeFiltre<int>(valeur: h, libelle: libelleHeureMinute(h, 0)),
            ],
            onChoix: (int? h) => setState(() {
              _heure = h ?? heureParDefaut;
              _message = null;
            }),
          ),
        ),
        Ecart.vXxl,
        TitreChamp(f.duree, style: textes.titleMedium),
        Ecart.vMd,
        ChoiceCardGroup(
          key: ValueKey<String>('offre-duree-${_public.valeurSql}'),
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{'$duree'}),
          options: <OptionChoix>[
            for (final int d in durees)
              OptionChoix(
                cle: ValueKey<String>('offre-duree-$d'),
                valeur: '$d',
                libelle: libelleDuree(d),
              ),
          ],
          onChange: (ReponseChoix r) => setState(() {
            _duree = int.tryParse(r.valeurs.firstOrNull ?? '');
            _message = null;
          }),
        ),
      ],
    );
  }
}

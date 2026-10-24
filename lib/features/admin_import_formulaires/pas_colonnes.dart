// Pas 3 de l'import des formulaires (`ADM-23`) : les colonnes.
//
// Une question : chaque colonne contient-elle bien ce que Rewayah croit ? Le
// serveur reconnait les colonnes par leur titre ; l'ecran les montre, une ligne
// par colonne, avec le titre du fichier tel quel. **Toucher une colonne** ouvre
// une seconde question, sur une page et non une fenetre : « Que contient la
// colonne N ? », en lignes qu'on touche (quinze choix : une liste, pas la grille
// des grands ecrans, faite pour deux a cinq choix). Le choix s'applique tout
// de suite et ramene a la liste. Aucune frappe.
//
// La table des libelles (« ذكر » veut dire homme...) est celle du serveur : elle
// n'est pas rendue au client, qui ne peut donc ni la montrer ni la corriger. Le
// pas le dit, et renvoie au pas « Erreurs » pour tout libelle inconnu.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/chargement_avec_delais.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'libelles_import.dart';

/// Le pas « Colonnes ».
class PasColonnes extends StatefulWidget {
  /// Cree le pas.
  const PasColonnes({
    required this.controleur,
    required this.empile,
    required this.horsLigne,
    super.key,
  });

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Vrai sur telephone.
  final bool empile;

  /// Vrai quand l'appareil est hors ligne.
  final bool horsLigne;

  /// La cle de la liste des colonnes.
  static const Key listeKey = ValueKey<String>('import-colonnes-liste');

  /// La cle de la page « Que contient la colonne N ? ».
  static const Key choixKey = ValueKey<String>('import-colonne-choix');

  @override
  State<PasColonnes> createState() => _PasColonnesEtat();
}

class _PasColonnesEtat extends State<PasColonnes> {
  int? _ouverte;

  ControleurImportCandidatures get _c => widget.controleur;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    if (_c.phase == PhaseImport.analyse) {
      return Column(
        key: const ValueKey<String>('import-analyse'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          QuestionDuPas(
            question: a.colonnes.question,
            explication: a.depot.analyseEnCours,
          ),
          Ecart.vXl,
          ChargementAvecDelais(
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: () => unawaited(_c.suivant()),
          ),
        ],
      );
    }
    return _ouverte == null ? _liste() : _choix(_ouverte!);
  }

  // --- la liste ---

  Widget _liste() {
    final a = t.admin.importFormulaires;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final List<ColonneLue> colonnes = _c.colonnes;
    final List<ChampManquant> manquants = _c.manquants;
    final bool complet = _c.colonnesCompletes;
    final bool aRelire = complet && _c.colonnesAReLire;
    final String? attention = complet
        ? null
        : _c.ambigu
        ? a.colonnes.ambigu(
            champs: listeDe(<String>[
              for (final ChampFormulaire c in _c.champsAmbigus) libelleChamp(c),
            ]),
          )
        : a.colonnes.manquants(
            champs: listeDe(<String>[
              for (final ChampManquant c in manquants) libelleManquant(c),
            ]),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(
          question: a.colonnes.question,
          explication: a.colonnes.explication,
        ),
        Ecart.vXl,
        if (attention != null) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('import-colonnes-attention'),
            titre: _c.ambigu ? a.apercu.ambiguTitre : a.apercu.colonnesATitre,
            message: attention,
          ),
          Ecart.vLg,
        ],
        CarteLignes(
          key: PasColonnes.listeKey,
          lignes: <Widget>[
            for (final ColonneLue c in colonnes)
              SettingRow(
                key: ValueKey<String>('import-colonne-${c.position}'),
                icon: c.champ == null ? AppIcons.masquer : AppIcons.succes,
                title: c.champ == null
                    ? a.colonnes.nonLue
                    : libelleChamp(c.champ!),
                description: _description(c),
                onPress: () => setState(() => _ouverte = c.position),
              ),
          ],
        ),
        Ecart.vLg,
        AppCard(
          key: const ValueKey<String>('import-colonnes-libelles'),
          entete: Semantics(
            header: true,
            child: TexteSansCoupure(
              a.colonnes.libelles.titre,
              style: textes.titleMedium,
            ),
          ),
          child: TexteSansCoupure(
            a.colonnes.libelles.texte,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vLg,
        ActionsDuPas(
          empile: widget.empile,
          libelleAction: complet && !(widget.horsLigne && aRelire)
              ? t.commun.continuer
              : null,
          onAction: () => unawaited(_c.suivant()),
          onRetour: _c.precedent,
          souscription: aRelire
              ? IndicationPas(
                  message: widget.horsLigne
                      ? a.depot.horsLigne
                      : a.colonnes.relecture,
                  discret: true,
                )
              : null,
        ),
      ],
    );
  }

  String _description(ColonneLue c) {
    final a = t.admin.importFormulaires.colonnes;
    final String titre = _c.fichier?.titreDeColonne(c.position) ?? '';
    return titre.isEmpty
        ? a.sansTitreNumero(n: c.position)
        : a.titreColonne(n: c.position, titre: titre);
  }

  // --- la seconde question ---

  Widget _choix(int position) {
    final a = t.admin.importFormulaires;
    final List<ColonneLue> colonnes = _c.colonnes;
    final ColonneLue courante = colonnes.firstWhere(
      (ColonneLue c) => c.position == position,
      orElse: () => ColonneLue(position: position),
    );
    final String titre = _c.fichier?.titreDeColonne(position) ?? '';
    final Map<ChampFormulaire, int> ailleurs = <ChampFormulaire, int>{
      for (final ColonneLue c in colonnes)
        if (c.champ != null && c.position != position) c.champ!: c.position,
    };
    return Column(
      key: PasColonnes.choixKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(
          question: a.colonnes.choisir(n: position),
          explication: titre.isEmpty ? a.colonnes.sansTitre : titre,
        ),
        Ecart.vXl,
        // Quinze choix : une liste de lignes qu'on touche, pas des cartes en
        // grille (la grille des grands ecrans est faite pour deux a cinq
        // choix). Le choix s'applique tout de suite et ramene a la liste.
        CarteLignes(
          lignes: <Widget>[
            for (final ChampFormulaire champ in ChampFormulaire.values)
              _ligneDeChoix(
                cle: ValueKey<String>('import-champ-${champ.code}'),
                titre: libelleChamp(champ),
                description: ailleurs.containsKey(champ)
                    ? '${aideChamp(champ)} ${a.colonnes.dejaAssocie(n: ailleurs[champ]!)}'
                    : aideChamp(champ),
                actuel: courante.champ == champ,
                position: position,
                champ: champ,
              ),
            _ligneDeChoix(
              cle: const ValueKey<String>('import-champ-aucun'),
              titre: a.colonnes.nePasLire,
              description: a.colonnes.nePasLireAide,
              actuel: courante.champ == null,
              position: position,
              champ: null,
            ),
          ],
        ),
        Ecart.vLg,
        ActionsDuPas(
          empile: widget.empile,
          onRetour: () => setState(() => _ouverte = null),
        ),
      ],
    );
  }

  Widget _ligneDeChoix({
    required Key cle,
    required String titre,
    required String description,
    required bool actuel,
    required int position,
    required ChampFormulaire? champ,
  }) => Semantics(
    selected: actuel,
    child: SettingRow(
      key: cle,
      title: titre,
      description: description,
      value: actuel ? t.admin.importFormulaires.colonnes.choixActuel : null,
      onPress: () {
        _c.associer(position, champ);
        setState(() => _ouverte = null);
      },
    ),
  );
}

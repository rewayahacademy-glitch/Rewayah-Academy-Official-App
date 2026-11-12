/// ESPACE-APPRENDRE (lot 5, 12/11/2026) : « Apprendre », l'espace de tout ce
/// qui touche a l'apprentissage, pour l'eleve adulte ET pour l'eleve mineur
/// (directeur, 12/11/2026 : « sinon on dirait Lire »).
///
/// Trois onglets par [SelecteurSection], dans cet ordre : Bibliotheque (ouvert
/// par defaut), Programme, Mon livret. Le changement d'onglet est local et
/// instantane (l'ecran n'attend rien : les lectures des trois onglets sont
/// lancees des l'ouverture de l'espace). L'adresse peut ouvrir un onglet :
/// `?onglet=programme`, `?onglet=livret`.
///
/// Le lecteur du Coran n'est pas ici : il s'ouvre depuis la carte « Coran » de
/// la Bibliotheque (un raccourci, jamais une copie).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/apprendre/documents_apprendre.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/mouvement/bascule_etat.dart';
import '../../core/mouvement/mouvement.dart';
import '../../core/router/etat_routeur_sur.dart';
import '../../core/session/session_controleur.dart';
import '../../core/suivi/port_suivi_pedagogique.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/controle_segmente.dart' show Segment;
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_section.dart';
import 'onglet_bibliotheque.dart';
import 'onglet_livret.dart';
import 'onglet_programme.dart';

/// Les onglets de l'espace, dans l'ordre d'affichage.
enum OngletApprendre {
  /// Les documents.
  bibliotheque,

  /// Le niveau, l'etape, le chemin, les dates de l'ecole.
  programme,

  /// Resultats, bilans, attestations (lot 8).
  livret;

  /// Lit le parametre `onglet` de l'adresse ; la Bibliotheque sinon.
  static OngletApprendre depuis(String? valeur) {
    for (final OngletApprendre o in values) {
      if (o.name == valeur) return o;
    }
    return OngletApprendre.bibliotheque;
  }
}

/// Le nom du parametre de requete qui ouvre un onglet.
const String parametreOngletApprendre = 'onglet';

/// L'espace Apprendre.
class EspaceApprendrePage extends ConsumerStatefulWidget {
  /// Cree l'espace.
  const EspaceApprendrePage({super.key});

  /// La cle du selecteur d'onglets, pour les tests.
  static const Key cleSelecteur = ValueKey<String>('apprendre-selecteur');

  @override
  ConsumerState<EspaceApprendrePage> createState() => _EtatEspace();
}

class _EtatEspace extends ConsumerState<EspaceApprendrePage> {
  OngletApprendre? _onglet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // L'onglet de l'adresse, lu une fois a l'ouverture ; ensuite le choix est
    // local, sans relire l'adresse.
    _onglet ??= OngletApprendre.depuis(
      parametreRouteurSur(context, parametreOngletApprendre),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Les lectures des trois onglets partent des l'ouverture : changer
    // d'onglet ne fait rien attendre.
    ref.watch(documentsApprendreProvider);
    final String? eleveId = ref.watch(sessionProvider).profileId;
    if (eleveId != null && ref.watch(portSuiviPedagogiqueProvider) != null) {
      ref.watch(suiviPedagogiqueProvider(eleveId));
    }
    final bool tutoiement = AppMetriques.of(context).estEnfant;
    final OngletApprendre onglet = _onglet ?? OngletApprendre.bibliotheque;
    final s = t.apprendre.sections;
    return PageShell(
      titre: t.nav.eleve.apprendre,
      encartBasDansLeCorps: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SelecteurSection<OngletApprendre>(
            key: EspaceApprendrePage.cleSelecteur,
            libelle: s.libelle,
            sections: <Segment<OngletApprendre>>[
              Segment<OngletApprendre>(
                valeur: OngletApprendre.bibliotheque,
                libelle: s.bibliotheque,
              ),
              Segment<OngletApprendre>(
                valeur: OngletApprendre.programme,
                libelle: s.programme,
              ),
              Segment<OngletApprendre>(
                valeur: OngletApprendre.livret,
                libelle: s.livret,
              ),
            ],
            valeur: onglet,
            onChange: (OngletApprendre o) => setState(() => _onglet = o),
          ),
          Ecart.vXl,
          BasculeEtat(
            etat: onglet,
            duree: Mouvement.court,
            child: switch (onglet) {
              OngletApprendre.bibliotheque => const OngletBibliotheque(),
              OngletApprendre.programme => OngletProgramme(
                tutoiement: tutoiement,
              ),
              OngletApprendre.livret => OngletLivret(tutoiement: tutoiement),
            },
          ),
        ],
      ),
    );
  }
}

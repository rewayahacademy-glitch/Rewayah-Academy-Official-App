import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/recherche/controleur_recherche.dart';
import '../../core/recherche/modeles_recherche.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/widgets/etat_systeme.dart';
import 'ecran/ecran_recherche.dart';

/// La page de la route unique `/recherche` (RECH-1, spec RECH-03 §1, §4.1).
///
/// Elle ne choisit rien : elle lit l'**espace** de la session (une capacite
/// d'interface, jamais un droit : le serveur l'intersecte avec les droits
/// reels) et l'eventuel domaine d'ouverture des parametres de l'adresse, puis
/// rend l'ecran. Une session sans espace (observation d'un agent, role
/// illisible) n'a aucune recherche et la page le dit.
class PageRecherche extends ConsumerWidget {
  /// Cree la page. [espaceDemande] et [domaineDemande] sont les noms lus dans
  /// l'adresse (`?espace=`, `?domaine=`), jamais un texte cherche.
  const PageRecherche({super.key, this.espaceDemande, this.domaineDemande});

  /// Le nom de l'espace demande (`EspaceRecherche.name`), ou `null`.
  final String? espaceDemande;

  /// Le nom du domaine d'ouverture (`DomaineRecherche.name`), ou `null`.
  final String? domaineDemande;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(sessionProvider);
    final EspaceRecherche? demande = EspaceRecherche.values
        .asNameMap()[espaceDemande];
    final EspaceRecherche? espace = espaceRecherchePour(
      session,
      demande: demande,
    );
    if (espace == null) {
      return const EtatSysteme(
        nature: NatureEtat.indisponible,
        portee: PorteeEtat.page,
      );
    }
    return EcranRecherche(
      contexte: ContexteRecherche(
        espace: espace,
        domaineCible: DomaineRecherche.values.asNameMap()[domaineDemande],
      ),
    );
  }
}

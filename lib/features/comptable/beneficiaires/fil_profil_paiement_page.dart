// Le fil « Profil de paiement » d'un beneficiaire, ouvert par « Relancer »
// (CPT-COM ; spec Finance §27.3, CPT-BR-11, R-FIN-20, R-FIN-21).
//
// **Aucune messagerie Finance** (R-FIN-21) : c'est le fil metier contextuel
// de Communications V1, lu par `PortMessagesMetier.filPourObjet(
// TypeObjetLie.profilPaiement, beneficiaireId)` et rendu par le seul fil du
// socle (`FilContextuel`, donc `FilDiscussion`) : en-tete de contexte,
// bulles, champ, « Envoye » seulement sur accuse du serveur. Aucune liste de
// conversations, aucune destination ajoutee a la coquille du Comptable : la
// page vit sous le profil, dans l'onglet « Beneficiaires » de Paiements.
//
// Le message modele §27.3 est prerempli par la page du profil comme
// brouillon du fil (`cleBrouillonFil`) : le champ le montre, rien ne part
// sans « Envoyer ».
//
// Etats : chargement, erreur (« Reessayer »), hors ligne (bandeau des
// communications, puis l'etat hors ligne si rien n'est lu), capacite
// indisponible (port neutre de production, sans « Reessayer »), fil refuse
// (paire non autorisee : rien du fil n'est rendu, R-COM-02).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/communications/capacites_communication.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/vue_etat_communication.dart';
import '../../com_messages/fil_contextuel.dart';
import '../../com_messages/port_messages_metier.dart';

/// Le chemin du fil « Profil de paiement » d'un beneficiaire. La
/// demonstration le surcharge pour rester dans sa coquille (`/demo/comptable`).
final Provider<String Function(String beneficiaireId)>
cheminFilProfilPaiementProvider = Provider<String Function(String)>(
  (Ref _) => Routes.comptableFilProfilPaiementPour,
);

/// Lit le fil « Profil de paiement » de [beneficiaireId]. Un fil rendu pour
/// un autre objet n'est pas celui demande : il est traite comme absent
/// (R-COM-02), jamais montre a sa place.
Future<FilMetier?> lireFilProfilPaiement(
  PortMessagesMetier port,
  String beneficiaireId,
) async {
  final FilMetier? fil = await port.filPourObjet(
    TypeObjetLie.profilPaiement,
    beneficiaireId,
  );
  if (fil == null) return null;
  final ObjetLie objet = fil.objet;
  return objet.type == TypeObjetLie.profilPaiement && objet.id == beneficiaireId
      ? fil
      : null;
}

/// Le fil « Profil de paiement » d'un beneficiaire, vu par le Comptable.
class FilProfilPaiementPage extends ConsumerStatefulWidget {
  /// Cree la page pour [beneficiaireId] (segment d'adresse).
  const FilProfilPaiementPage({required this.beneficiaireId, super.key});

  /// Le beneficiaire.
  final String beneficiaireId;

  @override
  ConsumerState<FilProfilPaiementPage> createState() =>
      _FilProfilPaiementPageEtat();
}

class _FilProfilPaiementPageEtat extends ConsumerState<FilProfilPaiementPage> {
  AsyncValue<FilMetier?> _fil = const AsyncValue<FilMetier?>.loading();

  PortMessagesMetier get _port => ref.read(portMessagesMetierProvider);

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void didUpdateWidget(FilProfilPaiementPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.beneficiaireId != widget.beneficiaireId) _charger();
  }

  Future<void> _charger() async {
    final String id = widget.beneficiaireId;
    setState(() => _fil = const AsyncValue<FilMetier?>.loading());
    final AsyncValue<FilMetier?> lu = await AsyncValue.guard<FilMetier?>(
      () => lireFilProfilPaiement(_port, id),
    );
    if (!mounted || widget.beneficiaireId != id) return;
    setState(() => _fil = lu);
    if (lu.value case final FilMetier fil) {
      try {
        await _port.marquerLu(fil.id);
      } on Object {
        // Le badge reste tel quel : rien n'est affirme.
      }
    }
  }

  void _retour() => retourComptable(
    context,
    Routes.comptableBeneficiairePour(widget.beneficiaireId),
  );

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PageShell(
      // D-FUS-3 : le corps pose le bandeau des Communications.
      bandeauHorsLigne: const SizedBox.shrink(),
      titre: t.comptable.beneficiaires.profil.filTitre,
      onRetour: _retour,
      defilante: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (horsLigne) ...<Widget>[
            const BandeauHorsLigneCommunication(encadre: true),
            Ecart.vLg,
          ],
          Expanded(child: _corps(horsLigne)),
        ],
      ),
    );
  }

  Widget _corps(bool horsLigne) {
    if (_fil.isLoading) {
      return const SingleChildScrollView(
        child: VueEtatCommunication(etat: EtatCommunication.chargement),
      );
    }
    if (_fil.hasError) {
      return SingleChildScrollView(
        child: VueEtatCommunication.depuisErreur(
          _fil.error!,
          horsLigne: horsLigne,
          onReessayer: _charger,
        ),
      );
    }
    final FilMetier? fil = _fil.value;
    if (fil == null) {
      // Paire non autorisee : rien du fil n'est rendu (R-COM-02).
      return const SingleChildScrollView(
        child: VueEtatCommunication(
          etat: EtatCommunication.permissionRefusee,
          dependance: 'CPT-BR-11',
        ),
      );
    }
    return FilContextuel(
      key: ValueKey<String>('fil-contextuel-${fil.id}'),
      fil: fil,
      // COM-BR-16 : fermee tant que la capacite n'est pas lue.
      ecritureOuverte:
          ref
              .watch(capacitesCommunicationProvider)
              .value
              ?.peut(CapaciteCommunication.ecrireDansFil) ??
          false,
      onEnvoyer: (String texte, String cle) =>
          _port.envoyer(fil.id, texte, cle),
      onRetour: _retour,
    );
  }
}

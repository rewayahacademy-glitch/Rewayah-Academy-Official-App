import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/amorce_agent.dart';
import '../../core/agent/session_agent.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_shell.dart';

/// `AGT-00` : le tunnel d'entree d'un agent IA (ADR-025).
///
/// **Cet ecran n'ouvre aucune session.** L'ouverture se fait au demarrage de
/// l'application, dans `main()`, parce que l'identite sous laquelle le client
/// parle a la base est une decision d'amorcage : elle se prend avant que le
/// premier ecran existe, pas apres.
///
/// Il n'a donc que deux choses a dire :
///
///   * **pourquoi une entree a echoue**, quand on y arrive avec un jeton qui
///     n'a pas ete accepte. Sans cela, un agent qui vient de cliquer sur un
///     lien tomberait sur l'ecran de connexion humaine, sans explication ;
///   * **comment entrer**, quand on y arrive sans jeton. L'adresse complete est
///     fabriquee sous les yeux du lecteur plutot que decrite : un agent copie
///     une adresse, il ne suit pas une consigne.
///
/// Le jeton reste dans l'adresse et n'est range nulle part. C'est volontaire :
/// une observation qu'on peut reprendre le lendemain dans le meme navigateur ne
/// serait plus bornee par la duree du jeton.
class AgentEntreePage extends ConsumerStatefulWidget {
  /// Cree l'ecran d'entree d'un agent.
  const AgentEntreePage({super.key});

  @override
  ConsumerState<AgentEntreePage> createState() => _AgentEntreePageEtat();
}

class _AgentEntreePageEtat extends ConsumerState<AgentEntreePage> {
  final TextEditingController _jeton = TextEditingController();

  @override
  void dispose() {
    _jeton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EchecAgent? echec = ref.watch(echecAgentProvider);
    final TextTheme textes = Theme.of(context).textTheme;
    final String saisi = _jeton.text.trim();

    return PageShell(
      titre: t.agent.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.agent.intro, style: textes.bodyMedium),
          Ecart.vXxl,

          if (echec != null) ...<Widget>[_Refus(echec: echec), Ecart.vXxl],

          // EA-HL-DOUBLE-1f : le libelle est pose au-dessus du champ, et non
          // dans le champ, ou il etait tronque a 320 px en texte x2 (K-54).
          // Il n'est lu qu'une fois : par le champ.
          ExcludeSemantics(
            child: Text(t.agent.jeton, style: textes.titleSmall),
          ),
          Ecart.vSm,
          Semantics(
            label: t.agent.jeton,
            textField: true,
            child: TextField(
              controller: _jeton,
              onChanged: (String _) => setState(() {}),
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(hintText: t.agent.jetonExemple),
            ),
          ),
          Ecart.vLg,

          // On ne navigue pas : on fabrique l'adresse a ouvrir. Une navigation
          // interne ne relancerait pas l'amorcage, et l'agent croirait etre
          // entre sans l'etre.
          if (saisi.startsWith('rag_')) ...<Widget>[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(t.agent.entrer, style: textes.titleSmall),
                  Ecart.vSm,
                  SelectableText(
                    Uri.base
                        .replace(
                          path: Routes.agentEntree,
                          queryParameters: <String, String>{
                            parametreJetonAgent: saisi,
                          },
                        )
                        .toString(),
                    style: textes.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ce qui n'a pas marche, dit en clair.
class _Refus extends StatelessWidget {
  const _Refus({required this.echec});

  final EchecAgent echec;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Le jeton refuse ne distingue jamais « inconnu », « revoque » et
    // « expire » : la base rend deja le meme message pour les trois, et le
    // client ne va pas etre plus bavard qu'elle.
    final (String titre, String detail) = switch (echec) {
      EchecAgent.jetonRefuse => (t.agent.refus, t.agent.refusDetail),
      EchecAgent.serviceIndisponible || EchecAgent.reponseIllisible => (
        t.agent.indisponible,
        t.agent.indisponibleDetail,
      ),
    };

    return AppCard(
      contourFort: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(AppIcons.avertissement.repos),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(titre, style: textes.titleSmall),
                Ecart.vXs,
                Text(detail, style: textes.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

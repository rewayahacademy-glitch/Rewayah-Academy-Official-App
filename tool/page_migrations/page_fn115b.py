"""La page du directeur pour FN-115b (remboursements et contestations, 02/11/2026).

  python3 -I tool/page_migrations/page_fn115b.py --sortie <page.html>

Consigne du pilote du 02/11 : le fichier qui contient le mot DROP est SEUL et le
directeur le colle lui-meme (le serveur Supabase demande une seconde
confirmation que l'outil de l'agent n'affiche pas) ; le pilote pose le second
fichier, puis fusionne. Ensuite seulement, le directeur ajoute trois evenements
au webhook Stripe de la production : avant la fusion, la fonction en ligne ne
les connait pas. Meme gabarit que la phase 2 (`modele_phase2.html`).
"""
import argparse
import json
import pathlib
import sys

RACINE = pathlib.Path(__file__).resolve().parents[2]
ICI = pathlib.Path(__file__).resolve().parent
PROD = 'gggmtelinlpseweouyav'
TABLEAU = f'https://supabase.com/dashboard/project/{PROD}'
DEPOT = 'https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App'
BRANCHE = 'claude/fn115b-remboursements-serveur'
FICHIER = '20261104300000_notifications_remboursements.sql'
SCENARIO = ('Scenarios FN-115b (remboursements et contestations Stripe)', 'scenarios_fn115b_remboursements.sql')
EVENEMENTS = ('charge.refunded', 'charge.dispute.created', 'charge.dispute.closed')

sys.path.insert(0, str(ICI.parent))
from envelopper_pour_editeur_sql import envelopper  # noqa: E402


def etapes() -> list[dict]:
    e: list[dict] = []

    def ajoute(section: str, titre: str, html: str, copie: str | None = None, genre: str = 'texte') -> None:
        e.append({'section': section, 'titre': titre, 'html': html, 'copie': copie, 'genre': genre})

    s = '1. La base de production : un seul fichier à coller'
    ajoute(s, 'Regarder la sauvegarde du jour',
           f'<p>Ouvrez <a href="{TABLEAU}/database/backups/scheduled" target="_blank" rel="noopener">les sauvegardes '
           'de la production</a>. Il doit y en avoir une d’aujourd’hui ou d’hier. S’il n’y en a aucune, écrivez-le-moi '
           'avant de continuer.</p>')
    sql = (RACINE / 'supabase' / 'migrations' / FICHIER).read_text()
    ajoute(s, 'Coller le fichier des notifications',
           '<p>Il ajoute trois sortes de notifications (« remboursement effectué », « contestation ouverte », '
           '« contestation close ») et la page Finance de la direction comme destination. Aucune donnée n’est '
           f'effacée.</p><p class="tech">{FICHIER} · {round(len(sql.encode()) / 1024)} Ko</p><p>Copiez, collez dans '
           f'<a href="{TABLEAU}/sql/new" target="_blank" rel="noopener">l’éditeur SQL de la production</a> '
           '(<kbd>Ctrl</kbd>+<kbd>A</kbd> puis <kbd>Ctrl</kbd>+<kbd>V</kbd>), <strong>Run</strong>. Une fenêtre '
           '« destructive operation » apparaît : cliquez sur <strong>Run this query</strong>, c’est prévu (deux règles '
           'de la table des notifications sont remplacées par des règles plus larges). Attendez « Success ». '
           'Ce fichier se colle une seule fois.</p>',
           envelopper(sql, pathlib.Path(FICHIER).stem, 1, 1), 'sql')
    ajoute(s, 'Me prévenir',
           '<p>Écrivez « fichier FN-115b collé », ou le message d’erreur avec une capture. Le pilote pose ensuite le '
           'second fichier, puis met le code en ligne. Je vous dis quand passer à l’étape 3.</p>')

    s = '2. Les contrôles automatiques : une ligne à ajouter'
    titre, fichier = SCENARIO
    bloc = (f'\n      - name: {titre}\n        shell: bash\n'
            f'        run: psql -h postgres -U postgres -v ON_ERROR_STOP=1 -f supabase/tests/{fichier}\n')
    ajoute(s, 'Ajouter le scénario FN-115b dans ci.yml',
           f'<p>Ouvrez <a href="{DEPOT}/edit/{BRANCHE}/.github/workflows/ci.yml" target="_blank" rel="noopener">le '
           'fichier ci.yml de la branche</a>. Cherchez (<kbd>Ctrl</kbd>+<kbd>F</kbd>) la ligne '
           '<code>scenarios_notifications_classes.sql</code>. Placez le curseur à la fin de cette ligne, appuyez sur '
           '<kbd>Entrée</kbd>, puis collez le texte copié ici. En haut à droite : « Commit changes… », laissez « Commit '
           f'directly to the {BRANCHE} branch », puis « Commit changes ».</p>',
           bloc, 'texte')

    s = '3. Stripe, après la mise en ligne seulement'
    ajoute(s, 'Ajouter trois événements au webhook de la production',
           '<p>Attendez mon message « FN-115b en ligne » : avant, l’application en ligne ne sait pas lire ces '
           'événements. Ouvrez <a href="https://dashboard.stripe.com/webhooks" target="_blank" rel="noopener">les '
           'webhooks de Stripe</a>, en mode réel (pas « Test mode »). Ouvrez la destination qui se termine par '
           '<code>/functions/v1/stripe-webhook</code>, puis « Edit destination » (ou « … », « Update details »). '
           'Dans les événements, ajoutez les trois ci-dessous, sans retirer ceux qui y sont déjà, puis enregistrez.</p>',
           '\n'.join(EVENEMENTS), 'texte')
    ajoute(s, 'Me prévenir',
           '<p>Écrivez « webhook FN-115b fait », avec une capture de la liste des événements de la destination.</p>')
    return e


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--sortie', required=True)
    a = p.parse_args()
    donnees = etapes()
    modele = (ICI / 'modele_phase2.html').read_text()
    for avant, apres in (
        ('<title>Mise en production Rewayah</title>', '<title>Remboursements en ligne</title>'),
        ('<h1>Mettre Rewayah en production</h1>', '<h1>Mettre les remboursements en ligne</h1>'),
        ('Comptez environ une heure et demie, surtout pour les 15 lots.',
         'Comptez environ quinze minutes, en deux moments : avant et après la mise en ligne.'),
        ('const CLE = "rewayah-phase2-2026-10-23";', 'const CLE = "rewayah-fn115b-2026-11-02";'),
    ):
        if avant not in modele:
            raise SystemExit(f'gabarit change : {avant}')
        modele = modele.replace(avant, apres)
    page = modele.replace('__NOMBRE__', str(len(donnees))).replace(
        '__DONNEES__', json.dumps(donnees, ensure_ascii=False).replace('</', '<\\/'))
    pathlib.Path(a.sortie).write_text(page)
    print(f'{a.sortie} : {len(donnees)} gestes, {len(page.encode()) // 1024} Ko')


if __name__ == '__main__':
    main()

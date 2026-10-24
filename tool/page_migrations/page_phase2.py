"""La page unique du directeur pour la phase 2 (mise en production, 23/10/2026).

  python3 -I tool/page_migrations/page_phase2.py --lots <dossier des lots> --sortie <page.html>

Une seule liste, dans l'ordre, pour tout ce que le directeur fait a la main : sauvegarde, lots de
migrations (lots_production.py), secrets des e-mails, coffre, envoi au nom des alias, SMTP et
modeles de Supabase Auth, adresses de retour, fusion vers main. Chaque geste a sa coche ; ce qui se
colle a son bouton Copier. Le secret d'envoi est tire au hasard dans le navigateur du directeur :
il ne passe jamais par la conversation.
"""
import argparse
import json
import pathlib
import re
import tomllib

RACINE = pathlib.Path(__file__).resolve().parents[2]
ICI = pathlib.Path(__file__).resolve().parent
PROD = 'gggmtelinlpseweouyav'
TABLEAU = f'https://supabase.com/dashboard/project/{PROD}'
DEPOT = 'https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App'
BRANCHE = 'claude/admiring-brown-r6ai72'
EFFACEMENT = re.compile(r'\b(delete from|drop |truncate)\b', re.IGNORECASE)


def etapes(lots: pathlib.Path) -> list[dict]:
    e: list[dict] = []

    def ajoute(section: str, titre: str, html: str, copie: str | None = None, genre: str = 'texte') -> None:
        e.append({'section': section, 'titre': titre, 'html': html, 'copie': copie, 'genre': genre})

    s = '1. Avant tout : la sauvegarde'
    ajoute(s, 'Regarder la sauvegarde du jour',
           f'<p>Ouvrez <a href="{TABLEAU}/database/backups/scheduled" target="_blank" rel="noopener">les sauvegardes de la '
           'production</a>. Il doit y en avoir une d’aujourd’hui ou d’hier. S’il n’y en a aucune, écrivez-le-moi avant de '
           'continuer : la base ne contient que 11 comptes d’essai, c’est à vous de dire si l’on continue.</p>')

    s = '2. La base de production : coller les lots, dans l’ordre'
    fichiers = sorted(lots.glob('lot*.sql'))
    for i, f in enumerate(fichiers, 1):
        sql = f.read_text()
        trouve = re.search(r'^-- (Lot \d+/\d+ : .*)$', sql, re.MULTILINE)
        detail = trouve.group(1) if trouve else sql.splitlines()[0].lstrip('- ').strip()
        effacement = ' Une fenêtre « destructive operation » peut apparaître : cliquez sur <strong>Run this query</strong>, c’est prévu.' \
            if EFFACEMENT.search(sql) else ''
        ajoute(s, f'Lot {i} sur {len(fichiers)}',
               f'<p class="tech">{detail} · {round(len(sql.encode()) / 1024)} Ko</p><p>Copiez, collez dans '
               f'<a href="{TABLEAU}/sql/new" target="_blank" rel="noopener">l’éditeur SQL de la production</a> '
               f'(<kbd>Ctrl</kbd>+<kbd>A</kbd> puis <kbd>Ctrl</kbd>+<kbd>V</kbd>), <strong>Run</strong>, attendez '
               f'« Success ».{effacement}</p>', sql, 'sql')

    s = '3. Les e-mails : les clés et les secrets'
    ajoute(s, 'Le mot de passe d’application Gmail',
           '<p>Connectez-vous au compte <code>staff@rewayahacademy.com</code>, qui porte les adresses support@, contact@, '
           'inscriptions@, invoices@ et recrutement@. Ouvrez <a href="https://myaccount.google.com/apppasswords" target="_blank" rel="noopener">'
           'les mots de passe des applications</a> (la validation en deux étapes doit être active), créez « Rewayah app » '
           'et gardez les 16 lettres affichées pour l’étape suivante. Ne les écrivez pas dans la conversation.</p>')
    ajoute(s, 'La clé Google Traduction',
           '<p>Dans <a href="https://console.cloud.google.com/apis/library/translate.googleapis.com" target="_blank" '
           'rel="noopener">Google Cloud</a> : activez « Cloud Translation API » (la facturation doit être active ; '
           'les 500 000 premiers caractères du mois sont gratuits). Puis « Identifiants », « Créer des identifiants », '
           '« Clé API » ; dans « Restrictions d’API », ne cochez que Cloud Translation API. Gardez la clé.</p>')
    ajoute(s, 'Le secret d’envoi (tiré au hasard sur cette page)',
           '<p>Ce secret relie la tâche planifiée de la base à la fonction d’envoi. Il est tiré au hasard ici, dans votre '
           'navigateur, et ne passe par personne. Copiez-le pour l’étape suivante ; il sert aussi à l’étape « coffre ».</p>'
           '<p class="tech" id="secret-visible"></p>', '@SECRET@', 'secret')
    ajoute(s, 'Poser les quatre secrets des fonctions',
           f'<p>Ouvrez <a href="{TABLEAU}/functions/secrets" target="_blank" rel="noopener">les secrets des fonctions</a>, '
           'puis « Add new secret », une ligne par secret :</p><ul>'
           '<li><code>SMTP_UTILISATEUR</code> : <code>staff@rewayahacademy.com</code></li>'
           '<li><code>SMTP_MOT_DE_PASSE</code> : les 16 lettres du mot de passe d’application</li>'
           '<li><code>GOOGLE_TRADUCTION_CLE</code> : la clé Google Traduction</li>'
           '<li><code>COURRIELS_ENVOI_SECRET</code> : le secret d’envoi tiré ci-dessus</li></ul>'
           '<p>Puis « Save ».</p>')
    url = f'https://{PROD}.supabase.co/functions/v1/courriels-envoi'
    ajoute(s, 'Le coffre de la base (deux lignes à coller)',
           f'<p>Collez dans <a href="{TABLEAU}/sql/new" target="_blank" rel="noopener">l’éditeur SQL</a>, '
           '<strong>Run</strong>. Le secret d’envoi tiré plus haut y est déjà.</p>',
           f"select vault.create_secret('{url}', 'courriels_envoi_url');\n"
           "select vault.create_secret('@SECRET@', 'courriels_envoi_secret');\n", 'sql')
    ajoute(s, 'Écrire au nom des quatre adresses',
           '<p>Dans Gmail, avec ce même compte : roue, « Voir tous les paramètres », onglet « Comptes », « Envoyer des '
           'e-mails en tant que », « Ajouter une autre adresse e-mail ». Il faut support@, contact@, inscriptions@, invoices@ et '
           'recrutement@rewayahacademy.com (case « Traiter comme un alias » cochée). Elles y sont déjà : rien à faire.</p>')

    s = '4. Les e-mails de connexion (Supabase Auth)'
    ajoute(s, 'Le serveur d’envoi',
           f'<p>Ouvrez <a href="{TABLEAU}/auth/smtp" target="_blank" rel="noopener">Authentication, SMTP Settings</a>, '
           'activez « Enable Custom SMTP » et remplissez : expéditeur <code>support@rewayahacademy.com</code>, nom '
           '<code>Rewayah Academy</code>, hôte <code>smtp.gmail.com</code>, port <code>465</code>, utilisateur et mot de '
           'passe : ceux de l’étape 3. « Save ».</p>')
    config = tomllib.loads((RACINE / 'supabase' / 'config.toml').read_text())
    noms = {'magic_link': 'Magic Link', 'confirmation': 'Confirm signup', 'invite': 'Invite user',
            'recovery': 'Reset Password', 'email_change': 'Change Email Address', 'reauthentication': 'Reauthentication'}
    for cle, onglet in noms.items():
        sujet = config['auth']['email']['template'][cle]['subject']
        html = (RACINE / 'supabase' / 'templates' / f'{cle}.html').read_text()
        ajoute(s, f'Modèle « {onglet} »',
               f'<p>Ouvrez <a href="{TABLEAU}/auth/templates" target="_blank" rel="noopener">Authentication, Email '
               f'Templates</a>, onglet <strong>{onglet}</strong>. Sujet : <code>{sujet}</code>. Dans « Message body », '
               'sélectionnez tout et collez le modèle copié ici. « Save ».</p>', html, 'texte')
    ajoute(s, 'Les adresses de retour',
           f'<p>Ouvrez <a href="{TABLEAU}/auth/url-configuration" target="_blank" rel="noopener">Authentication, URL '
           'Configuration</a>. Dans « Redirect URLs », ajoutez <code>https://app.rewayahacademy.com</code>, '
           '<code>https://app.rewayahacademy.com/**</code> et <code>https://rewayah-academy.vercel.app</code> (sans barre '
           'finale) ; gardez <code>https://rewayah-academy.vercel.app/**</code>. Puis « Site URL » : '
           '<code>https://app.rewayahacademy.com</code>. « Save ».</p>')

    s = '5. Mettre l’application en production'
    ajoute(s, 'Ouvrir la demande de fusion',
           f'<p>Ouvrez <a href="{DEPOT}/compare/main...{BRANCHE}?expand=1" target="_blank" rel="noopener">la '
           'comparaison</a>, titre « Mise en production : application, base, e-mails », puis « Create pull request ».</p>')
    ajoute(s, 'Fusionner',
           '<p>Dans l’encadré des contrôles, bouton <strong>Merge pull request</strong> puis « Confirm merge » (case '
           '« bypass rules » si GitHub la demande). Jamais « Close pull request ». Le déploiement part tout seul.</p>')
    ajoute(s, 'Me prévenir',
           '<p>Écrivez-moi <strong>« phase 2 fusionnée »</strong>. Je vérifie la base, les fonctions, l’application, '
           'puis j’envoie un vrai e-mail de chaque sorte pour contrôler qu’il arrive bien.</p>')
    return e


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--lots', required=True)
    p.add_argument('--sortie', required=True)
    a = p.parse_args()
    donnees = etapes(pathlib.Path(a.lots))
    modele = (ICI / 'modele_phase2.html').read_text()
    page = modele.replace('__NOMBRE__', str(len(donnees))).replace(
        '__DONNEES__', json.dumps(donnees, ensure_ascii=False).replace('</', '<\\/'))
    pathlib.Path(a.sortie).write_text(page)
    print(f'{a.sortie} : {len(donnees)} gestes, {len(page.encode()) // 1024} Ko')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Garde-fou PreToolUse de Rewayah Academy.

Refuse, avant exécution, ce que les règles du directeur interdisent aux agents
Claude (CLAUDE.md, docs/orchestration/COHABITATION.md). Code de sortie 2 :
l'outil n'est pas lancé et le motif est rendu à l'agent.
"""
import json
import os
import re
import subprocess
import sys

PROD = "gggmtelinlpseweouyav"

ZONES_INTERDITES = [
    (r"(^|/)supabase/", "supabase/ est la zone backend de ChatGPT (COHABITATION.md)"),
    (r"(^|/)lib/(.*/)?service_[^/]*\.dart$", "les services sont la zone de ChatGPT"),
    (r"_supabase\.dart$", "les adaptateurs *_supabase.dart sont la zone de ChatGPT"),
    (r"(^|/)\.github/", ".github/ est interdit aux agents (déploiement, CI)"),
    (r"(^|/)vercel\.json$", "vercel.json est interdit aux agents"),
    (r"(^|/)pubspec\.yaml$", "pubspec.yaml est interdit aux agents"),
    (r"(^|/)site-public/", "site-public/ est gelé (K-64)"),
    (r"(^|/)lib/features/parcours_offres/", "parcours_offres est gelé (K-64)"),
    (r"(^|/)\.claude/(settings(\.local)?\.json|hooks/)", "le garde-fou ne se modifie que sur ordre explicite du directeur"),
]

ECRITURE_SQL = re.compile(
    r"\b(insert|update|delete|merge|upsert|alter|drop|create|grant|revoke|truncate|comment\s+on|security\s+label"
    r"|call|do|copy|vacuum|reindex|cluster|refresh|lock|import|set|reset|discard|listen|notify|prepare|execute)\b",
    re.I,
)
LECTURE_SQL = re.compile(r"^\s*(select|with|explain|show|table|values)\b", re.I)

# Commandes qui écrivent un fichier désigné en argument.
ECRIVAINS = (
    r"(>>?|\btee\b|\bsed\b[^;&|\n]*\s(-[a-zA-Z]*i|--in-place)|\bperl\b[^;&|\n]*\s-[a-zA-Z]*i|\brm\b|\bmv\b|\bcp\b"
    r"|\btruncate\b|\btouch\b|\bln\b|\binstall\b|\brsync\b|\bdd\b|\bgit\s+(checkout|restore|rm|mv)\b)"
)
# Segments dont les arguments sont du texte libre, pas des chemins.
TEXTE_LIBRE = re.compile(r"^(\w+=\S*\s+)*(git\s+(commit|tag|notes|stash)|gh\s+(pr|issue)\s+(create|comment|edit)|echo\s+[^>]*$|printf\s+[^>]*$)\b")


def refuser(motif):
    print(f"Refusé par le garde-fou du projet : {motif}.", file=sys.stderr)
    sys.exit(2)


def verifier_chemin(chemin):
    chemin = (chemin or "").replace("\\", "/")
    for motif, raison in ZONES_INTERDITES:
        if re.search(motif, chemin, re.I):
            refuser(f"{chemin} : {raison}")


def segments(cmd):
    # Corps de heredoc retirés : c'est du texte, pas une commande.
    cmd = re.sub(r"<<-?\s*['\"]?(\w+)['\"]?([^\n]*)\n.*?^\s*\1\s*$", r"\2", cmd, flags=re.S | re.M)
    return [s.strip() for s in re.split(r"\n|;|&&|\|\||\|", cmd) if s.strip()]


def branche_courante(cwd):
    try:
        return subprocess.run(["git", "-C", cwd or ".", "symbolic-ref", "--short", "-q", "HEAD"],
                              capture_output=True, text=True, timeout=3).stdout.strip()
    except Exception:
        return ""


def verifier_push(seg, cwd):
    if not re.match(r"^(\w+=\S*\s+)*git(\s+-C\s+\S+|\s+-c\s+\S+)*\s+push\b", seg):
        return
    if re.search(r"(^|[\s:/+'\"])(main|master)(['\"\s]|$)", seg) or re.search(r"\s--(all|mirror)\b", seg):
        refuser("pousser sur main met en production ; seul le directeur en donne l'ordre")
    if "--force-with-lease" not in seg and re.search(r"(\s--force(\s|$|=)|\s-[a-zA-Z]*f[a-zA-Z]*(\s|$)|\s'?\+\S)", seg):
        refuser("push --force interdit (utiliser --force-with-lease, et seulement sur sa propre branche)")
    if re.search(r"(\s--delete\b|\s-d\s|\s:\S)", seg):
        refuser("suppression de branche distante interdite sans feu vert du directeur")
    # git push sans refspec explicite : la branche courante part sur son amont.
    args = [a for a in seg.split()[seg.split().index("push") + 1:] if not a.startswith("-")]
    if len(args) <= 1 and branche_courante(cwd) in {"main", "master"}:
        refuser("git push depuis main pousse sur main (production)")


def verifier_bash(cmd, cwd):
    if re.search(r"\bgit\s+(checkout|switch)\s+(main|master)\b", cmd) and re.search(r"\bgit\s+push\b", cmd):
        refuser("git push après un passage sur main pousserait sur main (production)")
    for seg in segments(cmd):
        c = " ".join(seg.split())
        if not TEXTE_LIBRE.match(c):
            for motif, raison in ZONES_INTERDITES:
                cible = motif.replace("(^|/)", r"(^|[\s'\"=/])").rstrip("$")
                if re.search(ECRIVAINS + r"[^;&|]*" + cible, c, re.I):
                    refuser(f"écriture shell dans une zone interdite : {raison}")
            if re.search(r"\bcd\s+['\"]?(\./)?(supabase|\.github|site-public|lib/features/parcours_offres)\b", c):
                refuser("se placer dans une zone interdite n'est pas permis ; lire avec un chemin depuis la racine")
        verifier_push(c, cwd)
        if re.search(r"\bgh\s+pr\s+create\b", c) and re.search(r"(--base|-B)[= ]['\"]?(main|master)\b", c):
            refuser("aucune PR vers main sans le feu vert du directeur (consigne du directeur)")
        if re.search(r"\bgh\s+(pr\s+merge|workflow\s+run|run\s+rerun|release\s+create)\b", c) or re.search(
            r"\bgh\s+api\b.*(/merge\b|/git/refs|/dispatches\b)", c
        ):
            refuser("fusion, déclenchement de workflow ou écriture de référence GitHub réservés au directeur")
        if re.search(r"\bvercel\b.*(--prod\b|--target[= ]production|\s(promote|rollback|alias|domains?|dns|rm|remove)\b|\senv\s+(add|rm|pull))", c):
            refuser("action Vercel de production interdite depuis un agent")
        if re.search(r"\bsupabase\s+(db\s+(push|reset|pull|remote)|migration\s+(up|repair|squash)|functions\s+(deploy|delete)"
                     r"|secrets\s+(set|unset)|link|projects|storage\s+(rm|cp|mv)|branches)\b", c):
            refuser("commande Supabase distante réservée à ChatGPT sous feu vert")
        if re.search(r"\bcurl\b.*(api\.supabase\.com|\.supabase\.co|api\.vercel\.com|api\.github\.com)", c) and re.search(
            r"(\s-X\s*(POST|PUT|PATCH|DELETE)|\s(-d|--data\S*|-F|--form)\s)", c
        ):
            refuser("écriture par API distante interdite depuis un agent")
        lecture = re.match(r"^(grep|rg|cat|less|head|tail|git\s+(log|show|diff|grep|blame))\b", c)
        if PROD in c and not lecture:
            refuser("aucune commande d'agent Claude ne vise le projet de production")
        if re.search(r"SUPABASE_SERVICE_ROLE|service_role_key", c, re.I) and not lecture:
            refuser("la clé service_role ne s'utilise ni ne se lit")


VERCEL_LECTURE = re.compile(r"^(get|list|search|count|aggregate|filter|read|web_fetch)_|^(git_namespaces|artifact_query)$")


def verifier_mcp(nom, entree):
    texte = json.dumps(entree, ensure_ascii=False)
    action = nom.split("__")[-1]
    if nom.startswith("mcp__Supabase__"):
        mutations = {
            "apply_migration", "deploy_edge_function", "create_edge_function_secret",
            "merge_branch", "delete_branch", "reset_branch", "rebase_branch",
            "restore_project", "pause_project", "create_project", "create_branch",
        }
        if action in mutations:
            refuser(f"Supabase {action} est réservé à ChatGPT, sous feu vert du directeur")
        if action == "execute_sql":
            q = re.sub(r"'(?:''|[^'])*'", "''", str(entree.get("query", "")))
            q = re.sub(r"--[^\n]*|/\*.*?\*/", " ", q, flags=re.S)
            if not LECTURE_SQL.match(q) or ECRITURE_SQL.search(q):
                refuser("execute_sql en écriture interdit aux agents Claude (lecture seule)")
        if PROD in texte and not re.match(r"^(get_|list_|search_|query_logs$|execute_sql$|generate_typescript_types$)", action):
            refuser("seules les lectures sont permises sur le projet de production")
    if nom.startswith("mcp__github__"):
        if action in {"merge_pull_request", "enable_pr_auto_merge", "actions_run_trigger"}:
            refuser("aucune fusion de PR ni déclenchement de workflow par un agent ; le directeur décide")
        branche = str(entree.get("branch") or "")
        if branche in {"main", "master"} and action in {"push_files", "create_or_update_file", "delete_file", "create_branch"}:
            refuser("rien vers main sans le feu vert du directeur (main = production)")
        if action == "create_pull_request" and str(entree.get("base") or "") in {"main", "master"}:
            refuser("aucune PR vers main sans le feu vert du directeur (consigne du directeur)")
    if nom.startswith("mcp__Vercel__") and not VERCEL_LECTURE.search(action):
        refuser("action Vercel en écriture réservée au directeur")


def main():
    try:
        donnees = json.load(sys.stdin.buffer)
    except Exception:
        sys.exit(0)
    nom = donnees.get("tool_name", "")
    entree = donnees.get("tool_input", {}) or {}
    cwd = donnees.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR", ".")
    if nom in {"Edit", "Write", "MultiEdit", "NotebookEdit"}:
        verifier_chemin(entree.get("file_path") or entree.get("notebook_path"))
    elif nom in {"Bash", "Monitor"}:
        verifier_bash(str(entree.get("command", "")), cwd)
    elif nom.startswith("mcp__"):
        verifier_mcp(nom, entree)
    sys.exit(0)


if __name__ == "__main__":
    main()

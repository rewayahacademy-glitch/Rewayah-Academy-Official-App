#!/usr/bin/env python3
"""Garde-fou PreToolUse de Rewayah Academy.

Refuse, avant exécution, ce que les règles du directeur interdisent aux agents
Claude (CLAUDE.md, docs/orchestration/COHABITATION.md). Code de sortie 2 :
l'outil n'est pas lancé et le motif est rendu à l'agent.
"""
import json
import re
import sys

PROD = "gggmtelinlpseweouyav"

# Zones où un agent Claude n'écrit jamais.
ZONES_INTERDITES = [
    (r"(^|/)supabase/", "supabase/ est la zone backend de ChatGPT (COHABITATION.md)"),
    (r"(^|/)lib/.*service_[^/]*\.dart$", "les services sont la zone de ChatGPT"),
    (r"_supabase\.dart$", "les adaptateurs *_supabase.dart sont la zone de ChatGPT"),
    (r"(^|/)\.github/", ".github/ est interdit aux agents (déploiement, CI)"),
    (r"(^|/)vercel\.json$", "vercel.json est interdit aux agents"),
    (r"(^|/)pubspec\.yaml$", "pubspec.yaml est interdit aux agents"),
    (r"(^|/)site-public/", "site-public/ est gelé (K-64)"),
    (r"(^|/)lib/features/parcours_offres/", "parcours_offres est gelé (K-64)"),
    (r"(^|/)\.claude/(settings\.json|hooks/)", "le garde-fou ne se modifie que sur ordre explicite du directeur"),
]

ECRITURE_SQL = re.compile(
    r"\b(insert|update|delete|alter|drop|create|grant|revoke|truncate|comment\s+on|security\s+label)\b",
    re.I,
)


def refuser(motif):
    print(f"Refusé par le garde-fou du projet : {motif}.", file=sys.stderr)
    sys.exit(2)


def verifier_chemin(chemin):
    chemin = (chemin or "").replace("\\", "/")
    for motif, raison in ZONES_INTERDITES:
        if re.search(motif, chemin):
            refuser(f"{chemin} : {raison}")


def verifier_bash(cmd):
    c = " ".join(cmd.split())
    # Écriture shell dans une zone interdite (redirection, sed -i, rm, mv, cp, tee).
    for motif, raison in ZONES_INTERDITES:
        cible = motif.replace("(^|/)", r"(^|[\s'\"=/])").rstrip("$")
        if re.search(r"(>>?|\btee\b|\bsed\s+-i|\brm\b|\bmv\b|\bcp\b|\btruncate\b)[^;&|]*" + cible, c):
            refuser(f"écriture shell dans une zone interdite : {raison}")
    if re.search(r"\bgit\b[^;&|]*\bpush\b", c):
        segment = re.search(r"\bgit\b[^;&|]*\bpush\b[^;&|]*", c).group(0)
        if re.search(r"(^|[\s:/+])(main|master)(\s|$)", segment):
            refuser("pousser sur main met en production ; seul le directeur en donne l'ordre")
        if re.search(r"(\s--force(\s|$|=)|\s-f(\s|$)|\s\+\S)", segment) and "--force-with-lease" not in segment:
            refuser("push --force interdit (utiliser --force-with-lease, et seulement sur sa propre branche)")
        if re.search(r"(\s--delete\b|\s-d\s|\s:\S)", segment):
            refuser("suppression de branche distante interdite sans feu vert du directeur")
    if re.search(r"\bvercel\b[^;&|]*--prod\b", c):
        refuser("déploiement Vercel en production interdit depuis un agent")
    if re.search(r"\bsupabase\s+(db\s+(push|reset)|migration\s+(up|repair)|functions\s+deploy|secrets\s+set|link)\b", c):
        refuser("commande Supabase distante réservée à ChatGPT sous feu vert")
    if PROD in c:
        refuser("aucune commande d'agent Claude ne vise le projet de production")
    if re.search(r"SUPABASE_SERVICE_ROLE|service_role_key", c, re.I):
        refuser("la clé service_role ne s'utilise ni ne se lit")


def verifier_mcp(nom, entree):
    texte = json.dumps(entree, ensure_ascii=False)
    if nom.startswith("mcp__Supabase__"):
        action = nom.split("__")[-1]
        mutations = {
            "apply_migration", "deploy_edge_function", "create_edge_function_secret",
            "merge_branch", "delete_branch", "reset_branch", "rebase_branch",
            "restore_project", "pause_project", "create_project", "create_branch",
        }
        if action in mutations:
            refuser(f"Supabase {action} est réservé à ChatGPT, sous feu vert du directeur")
        if action == "execute_sql" and ECRITURE_SQL.search(str(entree.get("query", ""))):
            refuser("execute_sql en écriture interdit aux agents Claude (lecture seule)")
    if nom.startswith("mcp__github__"):
        action = nom.split("__")[-1]
        if action in {"merge_pull_request", "enable_pr_auto_merge"}:
            refuser("aucune fusion de PR par un agent ; le directeur décide")
        branche = str(entree.get("base") or entree.get("branch") or "")
        if branche in {"main", "master"} and action in {
            "create_pull_request", "push_files", "create_or_update_file", "delete_file", "create_branch",
        }:
            refuser("rien vers main sans le feu vert du directeur (main = production)")
    if nom.startswith("mcp__Vercel__") and re.search(
        r"(create_deployment|request_promote|request_rollback|assign_alias|edit_project_env|create_project_env|update_project)$",
        nom,
    ):
        refuser("action Vercel de production réservée au directeur")
    if PROD in texte and nom.startswith("mcp__Supabase__") and nom.split("__")[-1] not in {
        "get_advisors", "list_tables", "list_migrations", "list_extensions", "get_project",
        "get_project_url", "search_docs", "execute_sql", "query_logs", "list_edge_functions", "get_edge_function",
    }:
        refuser("seules les lectures sont permises sur le projet de production")


def main():
    try:
        donnees = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    nom = donnees.get("tool_name", "")
    entree = donnees.get("tool_input", {}) or {}
    if nom in {"Edit", "Write", "MultiEdit", "NotebookEdit"}:
        verifier_chemin(entree.get("file_path") or entree.get("notebook_path"))
    elif nom == "Bash":
        verifier_bash(str(entree.get("command", "")))
    elif nom.startswith("mcp__"):
        verifier_mcp(nom, entree)
    sys.exit(0)


if __name__ == "__main__":
    main()

"""Agent local de Rewayah, payé par le crédit Agent SDK (pas par Claude Code).

Usage, dans PowerShell, depuis le dossier du clone :
    pip install claude-agent-sdk
    python tool\\agent_local.py

On tape une consigne, l'agent travaille, puis on tape la suite. « fin » pour sortir.
Le garde-fou du dépôt (.claude/settings.json) est chargé comme dans Claude Code.
"""
import asyncio
import os

from claude_agent_sdk import ClaudeAgentOptions, ClaudeSDKClient

DOSSIER = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

OPTIONS = ClaudeAgentOptions(
    cwd=DOSSIER,
    setting_sources=["project"],
    permission_mode="acceptEdits",
    mcp_servers={
        "playwright": {
            "type": "stdio",
            "command": "npx",
            "args": [
                "-y",
                "@playwright/mcp@0.0.41",
                "--user-data-dir",
                os.path.join(DOSSIER, ".profil-audit"),
            ],
        }
    },
)


async def principal() -> None:
    async with ClaudeSDKClient(options=OPTIONS) as client:
        while True:
            consigne = input("\nVous > ").strip()
            if consigne.lower() in {"fin", "exit", "quit"}:
                return
            if not consigne:
                continue
            await client.query(consigne)
            async for message in client.receive_response():
                for bloc in getattr(message, "content", None) or []:
                    texte = getattr(bloc, "text", None)
                    if texte:
                        print(texte)


if __name__ == "__main__":
    asyncio.run(principal())

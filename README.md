# Vorgaben für die Organisation

Dieses Repo enthält die gemeinsamen Vorgaben für alle Repos der Organisation.
Damit GitHub sie anwendet, muss es öffentlich sein. Es enthält keinen Code und
keine Geheimnisse.

- `pull_request_template.md`: die PR-Vorlage für jedes Repo ohne eigene Vorlage.
- `labels.json` und `scripts/sync-labels.sh`: die gemeinsamen PR-Labels.

## PR-Labels

Jeder PR bekommt genau eins dieser Labels:

| Label | Bedeutung | im Review-Filter |
|---|---|---|
| ✅ Bereit zum Review | fertiges Feature oder fertiger Fix | sichtbar |
| 🚑 Hotfix | dringender Fix direkt für live | sichtbar |
| 🧩 Teilschritt | Teil eines Features oder einer Aufgabe | ausgeblendet |
| ⏪ Rücksetzen | vorbereitet zum Zurückdrehen, nur im Notfall | ausgeblendet |
| 🔧 Wartung | Versions-Updates, Bots, Umbenennungen, Doku | ausgeblendet |

Aufgaben werden nicht mit Labels gebündelt, sondern mit **GitHub Projects** der Org.
Rechts im PR unter „Projects“ das passende Project wählen und dort das Feld
„Aufgabe“ setzen. Ein Project kann mehrere Aufgaben enthalten.

Entwürfe (Draft) brauchen kein Label – der Filter blendet sie ohnehin aus.

## Review-Filter

Alle offenen PRs, die ein Mensch ansehen soll, über alle Repos:

https://github.com/pulls?q=is%3Apr%20is%3Aopen%20draft%3Afalse%20org%3Awemotion-gmbh%20label%3A%22%E2%9C%85%20Bereit%20zum%20Review%22%2C%22%F0%9F%9A%91%20Hotfix%22

Alle PRs einer Aufgabe: im jeweiligen Project nach dem Feld „Aufgabe“ gruppieren oder filtern.

## Für Agenten

PRs gleich mit Labels anlegen, zum Beispiel:

```
gh pr create ... --label "🧩 Teilschritt"
gh project item-add <project-nummer> --owner <org> --url <pr-url>
```

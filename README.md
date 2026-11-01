# Vorgaben für die Organisation

Dieses Repo enthält die gemeinsamen Vorgaben für alle Repos der Organisation.
Damit GitHub sie anwendet, muss es öffentlich sein. Es enthält keinen Code und
keine Geheimnisse.

- `pull_request_template.md`: die PR-Vorlage für jedes Repo ohne eigene Vorlage.
- `labels.json` und `scripts/sync-labels.sh`: die gemeinsamen PR-Labels.

Die PR-Regeln selbst stehen im Repo [pr-regeln](https://github.com/wemotion-gmbh/pr-regeln).

## PR-Regeln in Kürze

- **Bereit** heißt: kein Entwurf. Wer noch nicht fertig ist oder wartet, legt den PR als Entwurf an
  (`gh pr ready <nr> --undo`), und sobald er fertig ist: `gh pr ready <nr>`.
- **Übergang:** Für PRs, die vor dem Stichtag T1 angelegt wurden (solange die Stichtage nicht gesetzt sind: für
  alle), gilt bis zum Stichtag T2 auch der alte Weg. Bereit sind sie dann erst, wenn sie aus dem Entwurf genommen
  wurden, ✅ Bereit zum Review tragen oder nach dem letzten Push den Kommentar „bereit“ haben. Die Labels ⛔ und 🚧
  halten sie an.
- **Kopfzeilen** ganz oben im PR-Text, am Zeilenanfang: `Merge-Stopp: <Grund>`, `Braucht: <repo>#<nr>`,
  `Paired-with: <repo> <https-Link>` (nur bei verschiedenen Branch-Namen), `Nach dem Merge: <Schritt>`.
  Jeder Stopp steht als `Merge-Stopp:`-Zeile, nie nur im Text. Trifft nichts zu, entfällt die Zeile.
- **Branch-Namen** `<art>/<thema>` mit den Arten `feat`, `fix`, `hotfix`, `chore`, `refactor`, `docs`, `test`,
  `part`, `release`, `revert`.
- Danach im PR-Text die Abschnitte `## Abhängigkeiten und Reihenfolge`, `## Worum es geht` und `## Bitte testen`.

## PR-Labels

**Art-Labels** setzt niemand von Hand. Die KI setzt sie beim Anlegen aus der Branch-Art:

| Branch-Art | Label |
|---|---|
| `hotfix` | 🚑 Hotfix |
| `part` | 🧩 Teilschritt |
| `revert` | ⏪ Rücksetzen |
| `chore`, `refactor`, `docs`, `test` | 🔧 Wartung |
| `feat`, `fix`, `release` und Freigabe-PRs | kein Art-Label |

**Migrationen, die Daten löschen**, brauchen Marcs Ja:

| Label | Bedeutung |
|---|---|
| 🔑 Marcs Ja fehlt | Eine Migration löscht Daten. Der PR wartet auf Marcs Ja im Cockpit. |
| 🔑 Marcs Ja | Marc hat zugestimmt. Dieses Label setzt die KI nur nach Marcs Ja im Cockpit. |

**Abgeschafft** sind ✅ Bereit zum Review, 🚧 Überarbeiten und ⛔ Nicht mergen. An neuen PRs sind sie ein Fehler.
Bei PRs, die vor dem Stichtag T1 angelegt wurden, zählen sie noch bis zum Stichtag T2. `labels.json` enthält sie
nicht mehr: Der Abgleich legt sie nicht neu an und lässt vorhandene stehen. Nach T2 löscht der Löschlauf sie
aus allen Repos (siehe „Labels abgleichen“).

Aufgaben werden nicht mit Labels gebündelt, sondern mit **GitHub Projects** der Org.
Rechts im PR unter „Projects“ das passende Project wählen und dort das Feld
„Aufgabe“ setzen. Ein Project kann mehrere Aufgaben enthalten.

## Labels abgleichen

```
scripts/sync-labels.sh [repo ...]                                  legt die Labels aus labels.json an oder aktualisiert sie
T2_PASSED=yes scripts/sync-labels.sh --delete-retired [repo ...]   löscht die abgeschafften Labels (erst nach T2)
```

Ohne Repo-Namen gilt der Abgleich für alle Repos, die in den letzten 90 Tagen einen Push hatten, und der Löschlauf
für alle Repos, die nicht archiviert sind. Nötig sind `gh` und für den Abgleich `node`.

Der Löschlauf braucht `T2_PASSED=yes`. Ohne diese Bestätigung endet er mit Exit 2, bevor er etwas ändert. Vor T2
würde er ✅ an PRs löschen, die nach dem alten Weg damit bereit sind. Die Bestätigung bleibt auch nach T2 nötig.
Trägt ein offener PR noch ⛔ oder 🚧, bleibt das Label in diesem Repo stehen. Das Skript nennt dann die PRs und
endet mit Exit 3. Dann den Stopp als `Merge-Stopp:`-Zeile in den PR-Text übernehmen, das Label vom PR nehmen und
das Skript noch einmal ausführen. ✅ wird immer gelöscht, es hält nichts an. Jeder andere Code als 0 und 3 heißt:
Der Lauf ist abgebrochen, etwa weil `gh` nicht angemeldet ist oder einen Fehler gemeldet hat. Ein zweiter Lauf
löscht dann nur den Rest.

`scripts/test/sync-labels-test.sh` prüft das Skript mit einem Ersatz für `gh` und ändert nichts auf GitHub.

## Review-Filter

Alle offenen PRs, die bereit sind, über alle Repos, ohne Teilschritte, Rücksetzen und Wartung und bis T2 ohne ⛔
und 🚧:

https://github.com/pulls?q=is%3Apr%20is%3Aopen%20draft%3Afalse%20org%3Awemotion-gmbh%20-label%3A%22%F0%9F%A7%A9%20Teilschritt%22%20-label%3A%22%E2%8F%AA%20R%C3%BCcksetzen%22%20-label%3A%22%F0%9F%94%A7%20Wartung%22%20-label%3A%22%E2%9B%94%20Nicht%20mergen%22%20-label%3A%22%F0%9F%9A%A7%20%C3%9Cberarbeiten%22

Bis T2 stehen darin auch alte PRs ohne ✅, die nach dem alten Weg noch nicht bereit sind.

Alle PRs einer Aufgabe: im jeweiligen Project nach dem Feld „Aufgabe“ gruppieren oder filtern.

## Für Agenten

PRs legt der Skill `pr-anlegen` aus dem Plugin `pr-regeln` an (`/plugin install pr-regeln@wemotion`). Er schreibt
die Kopfzeilen, setzt das Art-Label und prüft den PR vor dem Anlegen. Ein Project ordnest du danach zu:

```
gh project item-add <project-nummer> --owner <org> --url <pr-url>
```

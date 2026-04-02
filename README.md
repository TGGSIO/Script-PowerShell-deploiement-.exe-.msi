<div align="center">

<img src="assets/logo.svg" width="80" alt="TGG Logo" />

# Script PowerShell — Déploiement `.exe` / `.msi`

**BTS SIO SISR · 2ème année · Perpignan, France**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&labelColor=0d1525)](https://learn.microsoft.com/fr-fr/powershell/)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows&labelColor=0d1525)](https://www.microsoft.com/fr-fr/windows)
[![GitHub](https://img.shields.io/badge/GitHub-TGGSIO-ff00aa?style=for-the-badge&logo=github&labelColor=0d1525)](https://github.com/TGGSIO)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-thomas--gracia--gil-0077B5?style=for-the-badge&logo=linkedin&labelColor=0d1525)](https://www.linkedin.com/in/thomas-gracia-gil-321373304/)

</div>

---

## Présentation

Ce script PowerShell permet de **déployer automatiquement des applications** (`.exe` et `.msi`) sur un poste Windows via une interface graphique intuitive. Il détecte si les applications sont déjà installées, affiche leur statut, et permet une installation silencieuse en un clic.

Conçu dans le cadre du BTS SIO option SISR, il répond à une problématique courante en infrastructure : **automatiser le déploiement logiciel** sans passer par des outils tiers (SCCM, PDQ Deploy, etc.).

---

## Fonctionnalités

- **Interface graphique** (WinForms) — liste des installateurs avec cases à cocher
- **Détection automatique** des applications déjà installées (registre Windows + chemins d'installation)
- **Statut visuel** — les applications déjà présentes apparaissent en vert avec la mention *(Déjà installé)*
- **Installation silencieuse** — arguments automatiques selon le type (`.exe` / `.msi`)
- **Support `.msi`** via `msiexec.exe` avec `/quiet /norestart`
- **Journalisation** — chaque installation est tracée dans un fichier log horodaté (`Logs/InstallLog_YYYYMMDD_HHMMSS.txt`)
- **Boutons utilitaires** — Tout sélectionner / Inverser la sélection / Quitter
- **Détection générique** — les fichiers non reconnus sont analysés par nom pour tenter une correspondance automatique

---

## Structure du projet

```
Script-PowerShell-deploiement-.exe-.msi/
├── deploy.ps1          # Script principal
├── Logs/               # Généré automatiquement à l'exécution
│   └── InstallLog_*.txt
└── README.md
```

> Les installateurs sont à placer dans le dossier `C:\test` par défaut (modifiable ligne 4 du script).

---

## Applications reconnues par défaut

| Fichier attendu | Type | Arguments silencieux | Détection registre |
|---|---|---|---|
| `Chrome.exe` | `.exe` | `/silent /install` | `Google Chrome`, `chrome` |
| `Firefox.exe` | `.exe` | `/S` | `Mozilla Firefox`, `firefox` |
| `7Zip.msi` | `.msi` | `/quiet /norestart` (auto) | `7-Zip`, `7zip` |
| `Reader.exe` | `.exe` | `/sAll /rs /rps /msi EULA_ACCEPT=YES` | `Adobe Acrobat Reader` |

Tout autre `.exe` ou `.msi` présent dans le dossier sera **automatiquement détecté** et ajouté à la liste (avec détection générique par nom de fichier pour Steam, VLC, Firefox, Chrome, 7-Zip).

---

## Utilisation

### Prérequis

- Windows 10 / 11
- PowerShell 5.1 ou supérieur
- Droits **administrateur** (nécessaires pour l'installation de logiciels)

### Lancement

1. Placer les installateurs dans `C:\test` (ou modifier `$installerFolder` dans le script)
2. Clic droit sur `deploy.ps1` → **Exécuter avec PowerShell**
3. Ou via terminal :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\deploy.ps1
```

### Interface

1. La fenêtre s'ouvre avec la liste des installateurs détectés
2. Les applications déjà installées apparaissent en **vert**
3. Cocher/décocher les applications souhaitées
4. Cliquer sur **Installer les applications sélectionnées**
5. Un message de confirmation s'affiche à la fin

---

## Journalisation

Chaque exécution génère un fichier log dans le sous-dossier `Logs/` :

```
[2026-04-02 11:00:00][INFO] Installation de : Chrome.exe
[2026-04-02 11:00:15][INFO] Installation réussie pour : Chrome.exe
[2026-04-02 11:00:16][ERROR] Erreur lors de l'installation de : Reader.exe. Détails: ...
```

Les niveaux disponibles sont `INFO`, `WARNING` et `ERROR`.

---

## Personnalisation

### Changer le dossier source

```powershell
# Ligne 4 de deploy.ps1
$installerFolder = "C:\MonDossier\Installateurs"
```

### Ajouter un installateur connu

Dans le tableau `$installersKnown`, ajouter une entrée :

```powershell
@{ Path = Join-Path $installerFolder "MonApp.exe"; Type = "exe"; Args = "/S"; Names = @("Mon Application", "monapp") }
```

### Ajouter une détection générique

Dans le hashtable `$genericAppNames` :

```powershell
"notepad" = @("Notepad++", "notepad++")
```

---

## Auteur

**Thomas Gracia Gil**  
Étudiant BTS SIO SISR — Lycée Jean Lurçat, Perpignan  
[LinkedIn](https://www.linkedin.com/in/thomas-gracia-gil-321373304/) · [GitHub](https://github.com/TGGSIO)

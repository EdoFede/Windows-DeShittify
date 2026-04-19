*Italiano | [English](README.md)*

# Windows De-Shittify

Strumenti PowerShell per ripulire un'installazione pulita di Windows 11. Rimuove bloatware, spazzatura OEM, telemetria, pubblicita e notifiche indesiderate.

---

## Prerequisiti

### 1. Avviare PowerShell come Amministratore

Fare clic destro sul menu Start e selezionare **Terminale (Amministratore)** o **Windows PowerShell (Amministratore)**.

### 2. Consentire l'esecuzione degli script

Eseguire questo comando per consentire l'esecuzione di script scaricati localmente:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

---

## Ottenere gli script

Selezionare una cartella di installazione (esempio: C:\Tools)

### Opzione A: Clonare con Git

Se Git non e installato, scaricarlo da: https://git-scm.com/install/windows (le opzioni predefinite vanno bene).

Clonare il repository:
```powershell
git clone https://github.com/EdoFede/Windows-DeShittify.git
cd Windows-DeShittify
```

Per aggiornare gli script in seguito:
```powershell
cd Windows-DeShittify
git pull
```

### Opzione B: Download manuale

Scaricare l'ultima release da: https://github.com/EdoFede/Windows-DeShittify/releases/latest

Estrarre lo ZIP e aprire la cartella in PowerShell.

> **Nota:** le release vengono pubblicate manualmente e potrebbero non riflettere le ultime modifiche del branch `main`. Per la versione piu aggiornata, usare il metodo Git clone.

---

## Esecuzione automatica

Eseguire `ApplyAll.ps1` per avviare tutti i passaggi di pulizia in sequenza (modifiche al registro, rimozione pacchetti, rimozione programmi):
```powershell
.\ApplyAll.ps1
```

Equivale a eseguire manualmente ogni singolo script, uno dopo l'altro.

---

## Esecuzione manuale

| Script | Descrizione |
|---|---|
| `Apply-RegistryTweaks.ps1` | Applica modifiche al registro per disabilitare telemetria, pubblicita, Cortana, sincronizzazione OneDrive e notifiche UI |
| `Check-AppxPackages.ps1` | Scansiona i pacchetti Appx installati confrontandoli con le liste e riporta quali sono presenti |
| `Remove-AppxPackages.ps1` | Disinstalla i pacchetti Appx corrispondenti alle liste (bloatware, app OEM, ecc.) |
| `Remove-Programs.ps1` | Disinstalla programmi non rimovibili tramite Appx (es. OneDrive, WinZip) |

---

### Apply-RegistryTweaks.ps1

Applica modifiche al registro dai file `.reg.csv` nella directory `RegLists/`. Ogni file usa un formato separato da pipe:

```
Azione | Chiave | Valore | Tipo | Dati
```

Azioni supportate:
- **ADD** — crea o aggiorna un valore nel registro (richiede tutti e 5 i campi)
- **DELETE** — rimuove un valore o un'intera chiave del registro (richiede Azione + Chiave, opzionalmente Valore)

Le righe che iniziano con `#` sono commenti e vengono ignorate.

**Esempio di file lista:**
```
# Disabilita raccolta dati telemetria
ADD | HKLM\Software\Policies\Microsoft\Windows\DataCollection | AllowTelemetry | REG_DWORD | 0

# Rimuovi un valore specifico
DELETE | HKCU\Software\SomeApp | UnwantedSetting
```

Per impostazione predefinita, lo script mostra un'anteprima di tutte le modifiche e chiede conferma prima di applicarle.

**Parametri:**

| Parametro | Descrizione |
|---|---|
| `-ListFiles` | Usa solo file lista specifici invece di tutti (es. `disable-telemetry.reg.csv`) |
| `-Exclude` | Esclude le voci in cui chiave+valore corrisponde a una regex |
| `-Force` | Salta la richiesta di conferma |

**Esempi:**
```powershell
# Applica solo le modifiche per la telemetria
.\Apply-RegistryTweaks.ps1 -ListFiles disable-telemetry.reg.csv

# Applica tutto tranne le modifiche relative a OneDrive
.\Apply-RegistryTweaks.ps1 -Exclude "OneDrive"

# Applica tutto senza conferma
.\Apply-RegistryTweaks.ps1 -Force
```

**File lista inclusi:**

| File | Descrizione | Voci |
|---|---|---|
| `disable-telemetry.reg.csv` | Telemetria, CEIP, raccolta dati, ID pubblicita, SmartScreen | 8 |
| `disable-ads-suggestions.reg.csv` | Content delivery, app suggerite, spotlight schermata di blocco, contenuti in abbonamento | 19 |
| `disable-cortana-search.reg.csv` | Cortana, ricerca Bing, barra di ricerca, cronologia dispositivo | 6 |
| `disable-onedrive.reg.csv` | Sincronizzazione OneDrive, rete a consumo, notifiche sincronizzazione | 4 |
| `disable-ui-nags.reg.csv` | Sticker aiuto Edge, barra Persone, download automatico Store | 3 |

---

### Check-AppxPackages.ps1

Scansiona i pacchetti Appx installati confrontandoli con le liste e riporta quali sono presenti nel sistema. Utile per verificare quale bloatware e installato prima di rimuovere qualcosa.

Le liste vengono caricate da file `.txt` nella directory `AppLists/`, un pattern per riga. I pattern usano corrispondenza con caratteri jolly (es. `*Bing*`). Le righe che iniziano con `#` sono commenti e vengono ignorate.

**Esempio di file lista:**
```
# Bloatware
*3DBuilder*
*Advertising.Xaml*
*MinecraftUWP*
```

**Parametri:**

| Parametro | Descrizione |
|---|---|
| `-ListFiles` | Usa solo file lista specifici invece di tutti (es. `bloatware.txt,oem.txt`) |

**Esempi:**
```powershell
# Controlla tutte le liste
.\Check-AppxPackages.ps1

# Controlla solo il bloatware
.\Check-AppxPackages.ps1 -ListFiles bloatware.txt
```

**File lista inclusi:**

| File | Descrizione | Pattern |
|---|---|---|
| `3rd-party.txt` | App di terze parti (Amazon, Spotify, Facebook, Toshiba, Realtek, giochi...) | 17 |
| `bloatware.txt` | Spazzatura preinstallata, pubblicita, widget, 3D viewer, Bing, Game Assist... | 19 |
| `microsoft-apps.txt` | Prodotti Microsoft autonomi (Office, Teams, Xbox, Zune, YourPhone...) | 10 |
| `windows-apps.txt` | App integrate di Windows (Foto, Fotocamera, Sveglie, Hub Feedback...) | 7 |

---

### Remove-AppxPackages.ps1

Disinstalla i pacchetti Appx corrispondenti ai pattern dagli stessi file lista in `AppLists/` (vedi [Check-AppxPackages.ps1](#check-appxpackagesps1) per il formato delle liste).

Per impostazione predefinita, lo script rimuove i pacchetti per tutti gli utenti e rimuove i pacchetti provisioned (impedendo la reinstallazione per i nuovi utenti). Mostra un'anteprima e chiede conferma prima di procedere.

**Parametri:**

| Parametro | Descrizione |
|---|---|
| `-ListFiles` | Usa solo file lista specifici invece di tutti (es. `bloatware.txt,oem.txt`) |
| `-Exclude` | Esclude i pattern corrispondenti a una regex dalla rimozione |
| `-CurrentUserOnly` | Rimuove solo per l'utente corrente, salta i pacchetti provisioned |
| `-Force` | Salta la richiesta di conferma |

**Esempi:**
```powershell
# Rimuovi solo il bloatware
.\Remove-AppxPackages.ps1 -ListFiles bloatware.txt

# Rimuovi tutto tranne Foto e Fotocamera
.\Remove-AppxPackages.ps1 -Exclude "Photos|Camera"

# Rimuovi solo per l'utente corrente, escludendo Xbox
.\Remove-AppxPackages.ps1 -CurrentUserOnly -Exclude "Xbox"

# Rimuovi tutto senza conferma
.\Remove-AppxPackages.ps1 -Force
```

---

### Remove-Programs.ps1

Disinstalla programmi non rimovibili tramite Appx (es. OneDrive, WinZip). Legge i file `.prog.csv` dalla directory `ProgLists/` usando un formato separato da pipe:

```
Metodo | Nome/Comando
```

Metodi supportati:

| Metodo | Descrizione |
|---|---|
| `WINGET` | Disinstalla tramite `winget uninstall` |
| `PACKAGE` | Disinstalla tramite `Get-Package` / `Uninstall-Package` (PackageManagement) |
| `CIM` | Disinstalla tramite CIM/WMI `Win32_Product` (supporta caratteri jolly) |
| `CUSTOM` | Esegue il comando fornito cosi com'e |

Le righe che iniziano con `#` sono commenti e vengono ignorate.

**Esempio di file lista:**
```
# OneDrive
WINGET | Microsoft.OneDrive
```

Per impostazione predefinita, lo script mostra un'anteprima e chiede conferma prima di procedere.

**Parametri:**

| Parametro | Descrizione |
|---|---|
| `-ListFiles` | Usa solo file lista specifici invece di tutti (es. `microsoft.prog.csv`) |
| `-Exclude` | Esclude le voci corrispondenti a una regex dalla rimozione |
| `-Force` | Salta la richiesta di conferma |

**Esempi:**
```powershell
# Rimuovi solo i programmi Microsoft
.\Remove-Programs.ps1 -ListFiles microsoft.prog.csv

# Rimuovi tutto tranne OneDrive
.\Remove-Programs.ps1 -Exclude "OneDrive"

# Rimuovi tutto senza conferma
.\Remove-Programs.ps1 -Force
```

**File lista inclusi:**

| File | Descrizione | Voci |
|---|---|---|
| `microsoft.prog.csv` | Programmi Microsoft (OneDrive) | 1 |

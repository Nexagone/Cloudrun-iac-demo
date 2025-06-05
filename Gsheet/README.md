# Intégration Google Sheets avec Cloud Run

Ce guide explique comment mettre en place l'intégration entre Google Sheets et Cloud Run dans deux scénarios différents :
1. Google Sheets récupère des données depuis Cloud Run
2. Cloud Run écrit des données dans Google Sheets

## Scénario 1 : Google Sheets récupère des données depuis Cloud Run

Dans ce scénario, Google Sheets utilise Apps Script pour appeler une API hébergée sur Cloud Run et afficher les données dans une feuille de calcul.

### Prérequis
- Une API déployée sur Cloud Run avec accès public (`allow_public_access = true`)
- Un endpoint API qui renvoie les données au format JSON
- Un compte Google avec accès à Google Sheets

### Étapes de configuration

1. **Créer une nouvelle Google Sheet**
   - Ouvrez [Google Sheets](https://sheets.google.com)
   - Créez une nouvelle feuille de calcul

2. **Ajouter le script Apps Script**
   - Dans Google Sheets, allez dans `Extensions > Apps Script`
   - Copiez le code suivant dans l'éditeur :

```javascript
function fetchDataFromAPI() {
  var url = "https://votre-cloud-run-url.run.app/api/data";
  
  var options = {
    method: 'GET',
    muteHttpExceptions: true
  };
  
  try {
    var response = UrlFetchApp.fetch(url, options);
    var data = JSON.parse(response.getContentText());
    
    // Obtenir les en-têtes à partir des clés du premier objet
    var headers = Object.keys(data[0]);
    
    // Créer le tableau formaté avec les en-têtes
    var formattedData = [headers];
    
    // Ajouter les données
    data.forEach(row => {
      var rowValues = headers.map(header => row[header]);
      formattedData.push(rowValues);
    });

    // Calculer les dimensions
    var numRows = formattedData.length;
    var numCols = headers.length;

    // Sélectionner la feuille active
    var sheet = SpreadsheetApp.getActiveSheet();
    
    // Effacer et écrire les données
    sheet.clear();
    sheet.getRange(1, 1, numRows, numCols).setValues(formattedData);
    
    // Mettre en forme les en-têtes
    var headerRange = sheet.getRange(1, 1, 1, numCols);
    headerRange.setFontWeight("bold");
    headerRange.setBackground("#f3f3f3");
    
    // Ajuster la largeur des colonnes
    sheet.autoResizeColumns(1, numCols);
    
  } catch (error) {
    Logger.log('Erreur: ' + error.toString());
    var sheet = SpreadsheetApp.getActiveSheet();
    sheet.getRange(1, 1).setValue('Erreur: ' + error.toString());
  }
}

// Fonction pour configurer une mise à jour automatique
function createTimeTrigger() {
  var triggers = ScriptApp.getProjectTriggers();
  for (var i = 0; i < triggers.length; i++) {
    ScriptApp.deleteTrigger(triggers[i]);
  }
  
  ScriptApp.newTrigger('fetchDataFromAPI')
      .timeBased()
      .everyHours(1)
      .create();
}

// Fonction pour test manuel
function testFetch() {
  fetchDataFromAPI();
}
```

3. **Configurer le script**
   - Remplacez `votre-cloud-run-url.run.app/api/data` par l'URL de votre API
   - Sauvegardez le script (Ctrl/Cmd + S)
   - Exécutez la fonction `testFetch()` pour tester
   - Si besoin, exécutez `createTimeTrigger()` pour configurer une mise à jour automatique

## Scénario 2 : Cloud Run écrit dans Google Sheets

Dans ce scénario, votre service Cloud Run écrit directement des données dans une Google Sheet.

### Prérequis
- Un projet Google Cloud avec l'API Google Sheets activée
- Une Google Sheet créée et son ID (disponible dans l'URL)
- Les permissions IAM appropriées

### Étapes de configuration

1. **Activer l'API Google Sheets**
   ```bash
   gcloud services enable sheets.googleapis.com
   ```

2. **Créer un Service Account**
   ```bash
   gcloud iam service-accounts create sheets-writer \
     --display-name="Service Account pour écrire dans Google Sheets"
   ```

3. **Générer une clé JSON pour le Service Account**
   ```bash
   gcloud iam service-accounts keys create credentials.json \
     --iam-account=sheets-writer@${PROJECT_ID}.iam.gserviceaccount.com
   ```

4. **Stocker les credentials dans Secret Manager**
   ```bash
   gcloud secrets create google-sheets-credentials \
     --replication-policy="automatic" \
     --data-file=credentials.json
   ```

5. **Donner accès au Service Account**
   - Ouvrez votre Google Sheet
   - Cliquez sur "Partager"
   - Ajoutez l'email du service account avec les droits d'édition

6. **Mettre à jour les variables d'environnement dans terraform.tfvars**
   ```hcl
   environment_variables = {
     "GOOGLE_SHEETS_CREDENTIALS" = "projects/${var.project_id}/secrets/google-sheets-credentials"
     "GOOGLE_SHEETS_SPREADSHEET_ID" = "votre-spreadsheet-id"
   }
   ```

7. **Exemple de code Python pour écrire dans Google Sheets**
   ```python
   from google.oauth2 import service_account
   from googleapiclient.discovery import build
   import os
   import json

   def get_sheets_service():
       credentials_json = json.loads(os.environ['GOOGLE_SHEETS_CREDENTIALS'])
       credentials = service_account.Credentials.from_service_account_info(
           credentials_json,
           scopes=['https://www.googleapis.com/auth/spreadsheets']
       )
       return build('sheets', 'v4', credentials=credentials)

   def write_to_sheet(data):
       service = get_sheets_service()
       spreadsheet_id = os.environ['GOOGLE_SHEETS_SPREADSHEET_ID']
       
       # Préparer les données
       values = [list(data[0].keys())]  # En-têtes
       values.extend([list(item.values()) for item in data])
       
       body = {
           'values': values
       }
       
       # Écrire les données
       result = service.spreadsheets().values().update(
           spreadsheetId=spreadsheet_id,
           range='Sheet1!A1',  # Ajustez selon vos besoins
           valueInputOption='RAW',
           body=body
       ).execute()
       
       return result
   ```

### Notes importantes

- **Sécurité** : Ne stockez jamais les credentials directement dans votre code ou dans Git
- **Permissions** : Utilisez le principe du moindre privilège pour les permissions IAM
- **Rate Limiting** : Respectez les quotas de l'API Google Sheets
- **Monitoring** : Mettez en place une surveillance des appels API pour détecter les erreurs

### Dépendances requises

Pour le code Python :
```requirements.txt
google-auth==2.x.x
google-auth-oauthlib==1.x.x
google-auth-httplib2==0.1.x
google-api-python-client==2.x.x
``` 
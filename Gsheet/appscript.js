function fetchDataFromAPI() {
    var url = "https://cloudrun-centralizer-dev-dummy-data-api-299207869063.europe-west1.run.app/api/users";

    var options = {
        method: 'GET',
        muteHttpExceptions: true
    };

    try {
        var response = UrlFetchApp.fetch(url, options);
        var data = JSON.parse(response.getContentText());

        // Vérification que nous avons des données
        if (!data || !Array.isArray(data)) {
            throw new Error('Les données reçues ne sont pas un tableau');
        }

        // Obtenir les en-têtes à partir des clés du premier objet
        var headers = Object.keys(data[0]);

        // Créer le tableau formaté avec les en-têtes en première ligne
        var formattedData = [headers];  // Première ligne = en-têtes

        // Ajouter les données
        data.forEach(row => {
            // Pour chaque ligne, on prend les valeurs dans le même ordre que les en-têtes
            var rowValues = headers.map(header => row[header]);
            formattedData.push(rowValues);
        });

        // Calculer les dimensions
        var numRows = formattedData.length;
        var numCols = headers.length;

        // Sélectionner la feuille active
        var sheet = SpreadsheetApp.getActiveSheet();

        // Effacer les données existantes
        sheet.clear();

        // Écrire les données
        if (numRows > 0 && numCols > 0) {
            // Écrire toutes les données
            sheet.getRange(1, 1, numRows, numCols).setValues(formattedData);

            // Mettre en forme les en-têtes
            var headerRange = sheet.getRange(1, 1, 1, numCols);
            headerRange.setFontWeight("bold");
            headerRange.setBackground("#f3f3f3");
        }

        // Ajuster automatiquement la largeur des colonnes
        sheet.autoResizeColumns(1, numCols);

    } catch (error) {
        Logger.log('Erreur: ' + error.toString());
        var sheet = SpreadsheetApp.getActiveSheet();
        sheet.getRange(1, 1).setValue('Erreur lors de la récupération des données: ' + error.toString());
    }
}

// Fonction pour créer un déclencheur qui s'exécute toutes les heures
function createTimeTrigger() {
    // Supprimer les déclencheurs existants pour éviter les doublons
    var triggers = ScriptApp.getProjectTriggers();
    for (var i = 0; i < triggers.length; i++) {
        ScriptApp.deleteTrigger(triggers[i]);
    }

    // Créer un nouveau déclencheur
    ScriptApp.newTrigger('fetchDataFromAPI')
        .timeBased()
        .everyHours(1)
        .create();
}

// Fonction pour tester manuellement
function testFetch() {
    fetchDataFromAPI();
}
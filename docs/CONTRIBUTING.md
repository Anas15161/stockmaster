# Guide de Contribution

Merci de vouloir contribuer à StockMaster ! Voici les règles à suivre.

## Processus de Contribution

1.  **Forkez** le projet.
2.  **Créez une branche** pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`).
3.  **Commitez** vos changements (`git commit -m 'Add some AmazingFeature'`).
    *   *Format :* Soyez clair et concis (ex: "Fix login bug", "Add CSV export").
4.  **Pushez** vers la branche (`git push origin feature/AmazingFeature`).
5.  **Ouvrez une Pull Request**.

## Standards de Code

- **Langage :** Dart (Flutter).
- **Linter :** Le projet utilise `flutter_lints`. Assurez-vous qu'il n'y a pas d'erreurs d'analyse avant de soumettre (`flutter analyze`).
- **Formatage :** Utilisez `dart format .` pour respecter le style standard.
- **Architecture :** Respectez strictement le modèle MVVM.
    - Pas de logique métier dans les Widgets (`views/`).
    - Pas de code UI dans les Models ou DatabaseHelpers.
- **Nommage :**
    - Classes : `UpperCamelCase`
    - Variables/Méthodes : `lowerCamelCase`
    - Fichiers : `snake_case.dart`

## Tests
- Ajoutez des tests unitaires pour la logique métier complexe (`test/`).
- Vérifiez que l'application compile (`flutter build`).

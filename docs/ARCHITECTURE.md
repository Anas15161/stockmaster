# Architecture du Projet StockMaster

## 1. Vue d'ensemble
StockMaster suit l'architecture **MVVM (Model-View-ViewModel)**. Ce modèle sépare clairement l'interface utilisateur (View), la logique métier et l'état (ViewModel), et les données (Model).

### Diagramme de Flux de Données
```mermaid
graph TD
    User[Utilisateur] --> View[View (UI Widgets)]
    View -->|Action/Event| VM[ViewModel (Provider)]
    VM -->|Notify Listeners| View
    VM -->|CRUD Ops| Service[Services (DatabaseHelper)]
    Service -->|SQL Query| DB[(SQLite Database)]
    DB -->|Result| Service
    Service -->|Data Model| VM
```

## 2. Composants Clés

### A. View (Présentation)
- **Localisation :** `lib/views/`
- **Responsabilité :** Afficher les données et capturer les interactions utilisateur.
- **Technologie :** Flutter Widgets (`Scaffold`, `ListView`, `Form`, etc.).
- **Logique :** Aucune logique métier complexe. Délègue les actions aux ViewModels.

### B. ViewModel (État & Logique)
- **Localisation :** `lib/viewmodels/`
- **Responsabilité :**
    - Gérer l'état de l'application (ex: chargement, liste de produits, utilisateur connecté).
    - Contenir la logique métier (ex: calcul du total, vérification des permissions).
    - Communiquer avec les Services.
- **Technologie :** `ChangeNotifier` (Provider).

### C. Model (Données)
- **Localisation :** `lib/models/`
- **Responsabilité :** Définir la structure des données.
- **Entités Principales :**
    - `User` : Utilisateur et rôle.
    - `Product` : Article en stock.
    - `StockMovement` : Historique des entrées/sorties.

### D. Services (Accès aux Données)
- **Localisation :** `lib/services/`
- **Responsabilité :** Gestion de la persistance des données.
- **Composant Clé :** `DatabaseHelper` (Singleton) gère la connexion SQLite brute.

## 3. Gestion de l'État
Nous utilisons le package **Provider** pour l'injection de dépendances et la gestion d'état.
- `AuthViewModel` : Gère la session utilisateur.
- `StockViewModel` : Gère les produits et mouvements.
- `ThemeViewModel` : Gère le mode sombre/clair.
- `LanguageViewModel` : Gère l'internationalisation.

## 4. Sécurité
- **Mots de passe :** Hachés avec SHA-256 avant stockage.
- **Contrôle d'accès (RBAC) :** Système de permissions dynamique stocké en base de données (`role_permissions`). L'UI s'adapte en fonction de `hasPermission()`.

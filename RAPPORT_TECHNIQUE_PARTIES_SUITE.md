# SUITE DU RAPPORT : PARTIES TECHNIQUES ET RÉALISATION

---

## 6. CONCEPTION TECHNIQUE & ARCHITECTURE

Cette section détaille les choix technologiques et structurels qui garantissent la robustesse, la maintenabilité et l'évolutivité de l'application StockMaster.

### 6.1 Architecture Logicielle (MVVM)
Pour assurer une séparation claire entre l'interface utilisateur et la logique métier, nous avons adopté le modèle d'architecture **MVVM (Model-View-ViewModel)**. Ce choix est particulièrement adapté au développement avec Flutter.

*   **Model (Modèle)** : Représente les données pures de l'application (ex: `User`, `Product`, `StockMovement`). Il ne contient aucune logique d'interface.
*   **View (Vue)** : Correspond aux écrans de l'application (`lib/views`). Les vues sont "passives" : elles se contentent d'afficher les données et de transmettre les actions de l'utilisateur au ViewModel.
*   **ViewModel** : Agit comme un médiateur. Il contient la logique métier, interroge la base de données via les Services, et notifie la Vue lorsque les données changent (via `ChangeNotifier` et `Provider`).

**Avantages pour le projet :**
*   Facilite les tests unitaires de la logique métier.
*   Permet de modifier l'interface graphique sans impacter le traitement des données.

### 6.2 Stack Technologique
*   **Framework :** **Flutter** (Langage Dart). Choisi pour sa capacité à générer des applications natives performantes (Android, iOS, Desktop) à partir d'une base de code unique.
*   **Base de Données :** **SQLite** (via le package `sqflite`). Une base de données relationnelle locale idéale pour une application autonome (offline-first), garantissant la persistance des données sans besoin de connexion internet permanente.
*   **Gestion d'État :** **Provider**. Une solution recommandée par Google pour l'injection de dépendances et la gestion réactive de l'état de l'application.
*   **Sécurité :** Bibliothèque `crypto` pour le hachage SHA-256 des mots de passe.

### 6.3 Modélisation des Données (Base de Données)
La base de données `stockmaster.db` est structurée autour de tables relationnelles clés :

1.  **Users** : Stocke les informations d'authentification (`username`, `email`, `passwordHash`) et le `role` (Admin/Employé).
2.  **Products** : Contient le catalogue (`name`, `sku`, `price`, `quantity`, `imagePath`).
3.  **Movements** : Table d'historique assurant la traçabilité. Chaque entrée ou sortie crée une ligne avec la date, le type (`IN`/`OUT`), la quantité et le motif.
4.  **Tables de Référence** : `categories`, `roles` et `role_permissions` pour normaliser les données et gérer dynamiquement les droits d'accès.

*[Insérer ici votre Diagramme Entité-Association ou Capture du schéma SQL]*

---

## 7. RÉALISATION & DÉVELOPPEMENT

### 7.1 Structure du Projet
Le code source est organisé selon les conventions Flutter pour une lisibilité maximale :

*   `lib/models/` : Classes de données (`user.dart`, `product.dart`...).
*   `lib/views/` : Écrans de l'application (Login, Dashboard, Settings).
*   `lib/viewmodels/` : Logique de gestion d'état (`auth_viewmodel.dart`, `stock_viewmodel.dart`).
*   `lib/services/` : Gestionnaires de données (`database_helper.dart` pour SQL, `import_service.dart` pour CSV).
*   `lib/utils/` : Constantes, thèmes et traductions.

### 7.2 Implémentation des Fonctionnalités Clés

#### A. Authentification Sécurisée
Nous avons développé un système complet comprenant l'inscription, la connexion et la récupération de mot de passe.
*   *Point technique :* Le mot de passe n'est jamais stocké en clair. Il est haché via l'algorithme SHA-256 avant insertion en base. À la connexion, le hash de la saisie est comparé au hash stocké.

#### B. Gestion de Stock et Scanner
La gestion des produits permet le CRUD complet (Création, Lecture, Mise à jour, Suppression).
*   *Innovation :* Intégration de la caméra du mobile (`mobile_scanner`) pour scanner les codes-barres (EAN/QR) et retrouver instantanément un produit, facilitant les inventaires.

#### C. Système de Permissions (RBAC)
L'application adapte son interface selon le rôle de l'utilisateur connecté.
*   **Admin :** Accès total, y compris à la gestion des utilisateurs et aux configurations avancées.
*   **Employé :** Accès restreint aux opérations de stock (Entrées/Sorties) et consultation, sans pouvoir modifier les paramètres critiques ou supprimer l'historique.
*   *Réalisation :* Utilisation de directives conditionnelles dans les Vues (`if (viewModel.isAdmin) ...`) basées sur les permissions stockées en base.

### 7.3 Difficultés Rencontrées et Solutions
1.  **Complexité de l'Import CSV :**
    *   *Problème :* Gérer les différents formats de fichiers et encodages.
    *   *Solution :* Utilisation d'un service dédié (`ImportService`) avec détection automatique des séparateurs et gestion des erreurs ligne par ligne.
2.  **Mode Sombre (Dark Mode) :**
    *   *Problème :* Assurer une lisibilité parfaite sur tous les écrans en changeant de thème.
    *   *Solution :* Centralisation des couleurs dans `AppColors` et utilisation de `ThemeViewModel` pour notifier instantanément toute l'application du changement de mode.

---

## 8. TESTS ET VALIDATION

### 8.1 Scénarios de Test
Pour valider le bon fonctionnement de l'application, plusieurs scénarios critiques ont été testés :

| Scénario | Résultat Attendu | Résultat Obtenu |
| :--- | :--- | :--- |
| **Création Compte** | Le nouvel utilisateur est créé avec le rôle "Employé". | **OK** |
| **Alerte Stock** | Une icône d'alerte apparaît si Quantité < Stock Min. | **OK** |
| **Mouvement Stock** | Le stock total est mis à jour et une ligne d'historique est créée. | **OK** |
| **Sécurité Admin** | Un employé ne voit pas le menu "Utilisateurs". | **OK** |

### 8.2 Compatibilité
L'application a été testée avec succès sur :
*   Émulateur Android (Pixel 6 API 33).
*   Environnement Desktop Windows (pour le développement et l'administration).
Le design "Responsive" s'adapte correctement aux différentes tailles d'écran.

---

## 9. CONCLUSION & PERSPECTIVES

### 9.1 Bilan du Projet
Le projet StockMaster répond pleinement au cahier des charges initial. Nous avons livré une application fonctionnelle, esthétique et sécurisée permettant une gestion autonome des stocks.
Ce développement nous a permis de consolider nos compétences en architecture Flutter avancée (MVVM, Provider) et en gestion de bases de données embarquées.

### 9.2 Perspectives d'Évolution (V2.0)
Pour aller plus loin, plusieurs axes d'amélioration sont envisagés :
1.  **Synchronisation Cloud :** Migrer vers une architecture API REST ou Firebase pour permettre à plusieurs appareils de partager le même stock en temps réel.
2.  **Version Web :** Déployer l'application sur un navigateur pour faciliter l'accès depuis n'importe quel poste de travail sans installation.
3.  **Notifications Push :** Envoyer des alertes sur le mobile du gérant lorsqu'un produit arrive en rupture de stock critique.

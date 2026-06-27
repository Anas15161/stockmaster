# Catalogue des Widgets par Page

Ce document liste les principaux widgets utilisés sur chaque écran clé de l'application, facilitant la compréhension de la structure UI.

## 1. Login Screen (`lib/views/login_screen.dart`)
- **Structure :** `Scaffold` > `Stack`.
- **Fond :** `CustomClipper` (forme courbée bleue), `Container` (dégradé).
- **Formulaire :** `Form`, `Card` (conteneur blanc avec ombre), `SingleChildScrollView`.
- **Champs :** `TextFormField` (avec décoration personnalisée `OutlineInputBorder`), `Icon`.
- **Actions :** `ElevatedButton` (Login), `OutlinedButton` (Create Account), `TextButton` (Forgot Password).
- **Feedback :** `SnackBar` (erreurs), `CircularProgressIndicator` (chargement).

## 2. Sign Up Screen (`lib/views/signup_screen.dart`)
- **Structure :** `Scaffold` > `Center` > `SingleChildScrollView`.
- **Layout :** `ConstrainedBox` (limite largeur max), `Column`.
- **Formulaire :** `Form` avec validation (`validator`).
- **Champs :** 4x `TextFormField` (Username, Email, Password, Confirm).
- **Interactivité :** `IconButton` (visibilité mot de passe).

## 3. Main Screen / Dashboard (`lib/views/dashboard_screen.dart`)
- **Navigation :** Intégré dans `MainScreen` (gestionnaire de navigation).
- **Stats :** `GridView` ou `Row` de `Card` (Total Stock, Low Stock).
- **Graphique :** `LineChart` (via package `fl_chart`) ou placeholder visuel.
- **Liste Récente :** `ListView.builder` affichant des `ListTile` pour les derniers mouvements.

## 4. Products Screen (`lib/views/products_screen.dart`)
- **Liste :** `GridView.builder` (mode grille) ou `ListView` (mode liste).
- **Item Produit :** `Card`, `Column`, `Image.file` (ou asset/network), `Text` (Prix, Nom), `Chip` (Catégorie).
- **Actions :** `FloatingActionButton` (Ajout), `PopupMenuButton` (Tri/Filtre), `SearchDelegate` (Recherche).

## 5. Product Detail & Add (`lib/views/product_detail_screen.dart`, `add_product_screen.dart`)
- **Formulaire Ajout :** `Form`, `TextFormField`, `DropdownButtonFormField` (Catégorie/Fournisseur).
- **Image :** `GestureDetector` + `ImagePicker` (Sélection image).
- **Détail :** `SingleChildScrollView`, `Card` (Info stock), `Row` (Boutons action Entrée/Sortie).

## 6. Settings Screen (`lib/views/settings_screen.dart`)
- **Structure :** `Scaffold`, `SingleChildScrollView`.
- **Profil :** `Container` (Header), `CircleAvatar`, `Column` (Nom/Rôle).
- **Menu :** `ListTile` avec `leading` (Icon) et `trailing` (Chevron).
- **Logique d'affichage :** Utilise `if (authViewModel.hasPermission(...))` pour masquer/afficher les tuiles.

## 7. Users & Roles (`lib/views/settings/users_roles_screen.dart`)
- **Onglets :** `DefaultTabController` / `TabBar` (Users vs Roles).
- **Liste Users :** `ListView`, `Card`, `ListTile`.
- **Dialogues :** `showDialog` > `AlertDialog` pour création/édition.
- **Permissions :** `CheckboxListTile` dans une liste déroulante pour assigner les droits.

## 8. Reports (`lib/views/settings/reports_settings_screen.dart`)
- **Tabs :** `TabBar` (Stock Status, Top Sales, Losses).
- **Tableaux :** `DataTable` / `DataRow` / `DataCell`.
- **Filtres :** `DateRangePicker`, `DropdownButton`.

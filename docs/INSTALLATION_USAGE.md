# Installation et Guide d'Utilisation

## Installation

### Prérequis
- **Flutter SDK** (version stable récente)
- **Dart SDK**
- **IDE :** VS Code ou Android Studio
- **Système :** Windows, macOS, ou Linux (pour le développement). Android/iOS pour le déploiement mobile.

### Configuration Locale
1.  **Cloner le dépôt :**
    ```bash
    git clone https://github.com/votre-repo/StockMaster.git
    cd StockMaster
    ```

2.  **Installer les dépendances :**
    ```bash
    flutter pub get
    ```

3.  **Lancer l'application :**
    ```bash
    flutter run
    ```
    *Note : La base de données SQLite `stockmaster.db` sera créée automatiquement au premier lancement.*

## Guide d'Utilisation

### 1. Authentification
- **Login :** Utilisez vos identifiants.
    - *Compte Admin par défaut :* `admin` / `admin123`
    - *Compte Employé par défaut :* `employee` / `employee123`
- **Inscription :** Cliquez sur "Create Account" sur l'écran de login.
- **Mot de passe oublié :** Cliquez sur "Forgot Password?" pour réinitialiser (simulation).

### 2. Dashboard (Tableau de Bord)
- Vue d'ensemble des statistiques clés (Valeur du stock, Alertes stock bas).
- Graphique des mouvements récents.

### 3. Gestion des Produits
- **Ajouter :** Bouton `+` -> Remplir le formulaire (Nom, SKU, Prix...). Image optionnelle.
- **Modifier/Supprimer :** Appui long ou clic sur un produit dans la liste.
- **Scanner :** Utilisez l'icône QR Code pour scanner un code-barre (Mobile uniquement).

### 4. Entrées / Sorties de Stock
- Depuis la liste des produits, sélectionnez un article.
- Choisissez **"Entrée Stock"** (Réapprovisionnement) ou **"Sortie Stock"** (Vente/Perte).
- L'historique est enregistré automatiquement.

### 5. Paramètres (Rôles & Permissions)
- **Admin seulement :**
    - Allez dans `Settings` -> `Users & Roles`.
    - Ajoutez des rôles ou modifiez les permissions (ex: donner accès aux rapports à un employé).
    - Gérez les comptes utilisateurs.

### 6. Rapports
- Visualisez l'état du stock, les meilleures ventes et les pertes.
- Export PDF/Excel disponible.

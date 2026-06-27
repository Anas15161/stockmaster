# API & Schéma de Données (SQLite)

Puisque StockMaster fonctionne localement, l'"API" correspond à la couche d'accès aux données via `DatabaseHelper`.

## 1. Schéma de Base de Données

### Table `users`
| Colonne | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Identifiant unique |
| `username` | TEXT UNIQUE | Nom d'utilisateur (Login) |
| `email` | TEXT | Email de contact et récupération |
| `passwordHash` | TEXT | Hachage SHA-256 du mot de passe |
| `role` | TEXT | Rôle ('admin', 'employee') |

### Table `products`
| Colonne | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Identifiant unique |
| `name` | TEXT | Nom du produit |
| `sku` | TEXT | Code barre / Référence unique |
| `category` | TEXT | Catégorie du produit |
| `quantity` | INTEGER | Stock actuel |
| `costPrice` | REAL | Prix d'achat |
| `sellingPrice` | REAL | Prix de vente |
| `supplier` | TEXT | Fournisseur |
| `images` | TEXT | Chemin ou URL de l'image |

### Table `movements`
| Colonne | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Identifiant unique |
| `productId` | INTEGER | Référence au produit |
| `type` | TEXT | 'IN' (Entrée) ou 'OUT' (Sortie) |
| `quantity` | INTEGER | Quantité mouvementée |
| `date` | TEXT | Date ISO-8601 |
| `reason` | TEXT | Motif (ex: 'Vente', 'Réappro') |
| `userId` | TEXT | Auteur du mouvement |

### Table `role_permissions`
| Colonne | Type | Description |
|---|---|---|
| `role_name` | TEXT | Nom du rôle (FK) |
| `permission` | TEXT | Clé de permission (ex: 'view_reports') |

## 2. Méthodes Clés (DatabaseHelper)

Ces méthodes sont asynchrones (`Future`) et retournent généralement des Modèles ou des entiers (IDs).

### Authentification & Utilisateurs
- `getUserByUsername(String username)`: Récupère un utilisateur.
- `getUserByEmail(String email)`: Récupère un utilisateur par email.
- `createUser(User user, String password)`: Crée un compte.
- `getPermissionsForRole(String role)`: Retourne la liste des droits.

### Gestion de Stock
- `readAllProducts()`: Liste tous les produits.
- `createProduct(Product product)`: Ajoute un produit.
- `logMovement(StockMovement movement)`: Enregistre une transaction.
- `getTopSellingProducts()`: Calcule les meilleures ventes (Agrégation SQL).

### Configuration
- `updateRolePermissions(String role, List<String> perms)`: Met à jour les droits d'accès.

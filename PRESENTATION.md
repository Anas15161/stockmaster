# 📱 StockMaster : Gestion Fluide des Produits
### Projet de Développement Mobile

---

## 👥 Équipe & Contexte
**Réalisé par :**
* Anas HADDOU
* Alae Eddine MEHDI

**Encadré par :**
* M. Samir BARA (PhD, MCH)

**Contexte :**
* 2ème année Génie Informatique (2GInf) - EMG
* Année universitaire : 2025/2026

---

## ❓ La Problématique
**Le constat actuel dans les petites structures :**
* 📝 **Méthodes artisanales** : Cahiers papier ou Excel complexes.
* ❌ **Erreurs fréquentes** : Saisies incorrectes, oublis.
* 📉 **Manque de visibilité** : Pas de suivi en temps réel.
* ⚠️ **Ruptures de stock** : Anticipation difficile.

> *Besoin d'un outil simple, mobile et fiable.*

---

## 💡 La Solution : StockMaster
Une application mobile dédiée à la **gestion de stock** pour les commerces de proximité (boutiques, garages, ateliers).

**Objectifs clés :**
1.  **Centraliser** les informations produits.
2.  **Digitaliser** le suivi des stocks (Entrées/Sorties).
3.  **Simplifier** la gestion quotidienne (UX intuitive).
4.  **Sécuriser** les données (Accès par rôles).

---

## 🚀 Fonctionnalités Principales (1/2)

### 🔐 Authentification & Sécurité
* Connexion / Inscription sécurisée.
* Hachage des mots de passe (**SHA-256**).
* Gestion des rôles (**RBAC**) :
    * 👑 **Admin** : Contrôle total (Produits, Utilisateurs, Stats).
    * 👤 **Employé** : Consultation et mouvements de stock uniquement.

### 📦 Gestion du Catalogue (CRUD)
* Fiches produits complètes (Photo, SKU, Prix, Qté).
* Catégorisation intelligente.
* Indicateurs visuels de stock (Vert/Orange/Rouge).

---

## 🚀 Fonctionnalités Principales (2/2)

### 📸 Scanner Intelligent
* Utilisation de la caméra du smartphone.
* Scan de **Code-barres / QR Codes**.
* Accès instantané à la fiche produit.

### 📊 Tableau de Bord & Rapports
* **Dashboard** : Valorisation du stock, alertes "Stock Critique".
* **Historique** : Traçabilité complète des mouvements (Qui/Quoi/Quand).
* **Exports** : Génération de rapports **PDF** et **CSV**.

---

## 🛠 Architecture Technique

**Architecture : MVVM (Model-View-ViewModel)**
* Séparation claire entre l'interface (Vue) et la logique métier.
* Code maintenable et évolutif.

**Stack Technologique :**
* **Framework** : 💙 Flutter (Dart)
* **Base de données** : 🗄️ SQLite (Mode Offline-first)
* **Gestion d'état** : Provider
* **Sécurité** : Crypto (SHA-256)

---

## 📱 Expérience Utilisateur (UX/UI)

* **Design Moderne** : Interface épurée et intuitive.
* **Mode Sombre** : Support natif du Dark Mode.
* **Responsive** : Adapté aux différentes tailles d'écrans.
* **Feedback visuel** : Codes couleurs pour l'état des stocks.

---

## 🔮 Perspectives d'Évolution (V2)

1.  ☁️ **Synchronisation Cloud** : Accès multi-appareils en temps réel (Firebase/API).
2.  🌍 **Version Web** : Gestion depuis un navigateur PC.
3.  🔔 **Notifications Push** : Alertes de stock critique à distance.
4.  🛒 **Modules de Vente** : Facturation et encaissement simplifiés.

---

## 🏁 Conclusion

**StockMaster** répond au besoin de modernisation des petites structures avec une solution :
* ✅ **Simple**
* ✅ **Autonome**
* ✅ **Efficace**

*Merci de votre attention !*

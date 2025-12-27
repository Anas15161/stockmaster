# stockmaster

A new Flutter project.

## Getting Started
🚀 Comment quelqu’un utilise ton projet
1️⃣ Cloner le projet
git clone https://github.com/ton-repo/projet.git
cd projet

2️⃣ Installer Flutter (une seule fois)
flutter doctor


(Il installe ou vérifie Android SDK, émulateur, etc.)

3️⃣ Récupérer les dépendances
flutter pub get


👉 Cette commande recrée :

.dart_tool/

.pub-cache/

.flutter-plugins-dependencies

(tous ignorés par Git, donc normal 👍)

4️⃣ Lancer le projet
flutter run


Ou via Android Studio / VS Code ▶️

🏗️ Les dossiers ignorés sont recréés automatiquement

Par exemple :

/build/ → recréé au build

.idea/ → recréé par IntelliJ

.vscode/ → recréé par VS Code

android/app/debug → généré à la compilation

👉 Aucun problème s’ils ne sont pas dans Git

📄 Conseil important : README.md

Ajoute un README.md avec :

## Installation
flutter pub get
flutter run


Ça évite toute confusion pour les autres développeurs.

✅ En résumé

Ton .gitignore est bon

Git ignore uniquement des fichiers non essentiels

Toute personne peut :

Cloner

flutter pub get

flutter run

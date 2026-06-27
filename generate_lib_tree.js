const fs = require('fs');
const path = require('path');

// CONFIGURATION
const ROOT_DIR = './lib';
const OUTPUT_FILE = './stockmaster_docs/lib_tree.json';
const IGNORED = ['.git', '.dart_tool', 'build', 'node_modules', '.idea', 'generated', 'freezed'];

// DÉTECTION DES CATÉGORIES (Pour le code couleur)
function detectCategory(name, isDir) {
    const n = name.toLowerCase();
    
    // Priorité aux dossiers explicites
    if (n.includes('model') || n === 'data') return 'models';
    if (n.includes('view') && !n.includes('model')) return 'views';
    if (n.includes('screen') || n.includes('page') || n.includes('widget')) return 'views';
    if (n.includes('viewmodel') || n.includes('bloc') || n.includes('provider') || n.includes('logic')) return 'viewmodels';
    if (n.includes('service') || n.includes('repo') || n.includes('api') || n.includes('db')) return 'services';
    if (n.includes('util') || n.includes('helper') || n.includes('config') || n.includes('constant') || n.includes('theme')) return 'utils';
    
    // Fichiers .dart spécifiques
    if (!isDir && n.endsWith('.dart')) {
        if (n.includes('model')) return 'models';
        if (n.includes('screen')) return 'views';
        if (n.includes('viewmodel')) return 'viewmodels';
        if (n.includes('service')) return 'services';
    }
    
    return 'other';
}

function scanDir(dir) {
    const stats = fs.statSync(dir);
    const name = path.basename(dir);
    const isDir = stats.isDirectory();
    const category = detectCategory(name, isDir);

    const node = {
        name: name,
        path: dir.replace(/\\/g, '/'), // Normalisation path Windows
        type: isDir ? 'folder' : 'file',
        category: category,
        size: stats.size
    };

    if (isDir) {
        try {
            const items = fs.readdirSync(dir);
            const children = items
                .filter(item => !IGNORED.includes(item))
                .map(item => scanDir(path.join(dir, item)))
                .filter(n => n !== null); // Filtrer les retours null si on en mettait

            // Trier : Dossiers d'abord, puis fichiers
            children.sort((a, b) => {
                if (a.type === b.type) return a.name.localeCompare(b.name);
                return a.type === 'folder' ? -1 : 1;
            });

            if (children.length > 0) node.children = children;
        } catch (e) {
            console.warn(`⚠️ Accès refusé ou erreur sur ${dir}: ${e.message}`);
        }
    } else {
        // On garde seulement les .dart et .yaml pour cleaner le graphe
        if (!name.endsWith('.dart') && !name.endsWith('.yaml')) return null;
    }

    return node;
}

console.log(`🔍 Scanning de l'architecture dans ${ROOT_DIR}...`);

if (!fs.existsSync(ROOT_DIR)) {
    console.error(`❌ Erreur : Le dossier ${ROOT_DIR} n'existe pas.`);
    process.exit(1);
}

const tree = scanDir(ROOT_DIR);
// Force la racine
tree.name = "lib/";
tree.type = "root";
tree.category = "root";

fs.writeFileSync(OUTPUT_FILE, JSON.stringify(tree, null, 2));
console.log(`✅ Génération terminée ! Fichier : ${OUTPUT_FILE}`);
console.log(`👉 Lancez maintenant un serveur local (ex: 'npx serve') et ouvrez lib_architecture.html`);
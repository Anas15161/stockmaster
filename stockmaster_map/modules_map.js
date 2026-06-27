const width = window.innerWidth * 0.7;
const height = window.innerHeight - 70;

const svg = d3.select("#mindmap").append("svg")
    .attr("width", "100%")
    .attr("height", "100%")
    .call(d3.zoom().on("zoom", (e) => g.attr("transform", e.transform)));

const g = svg.append("g");

// Données embarquées (pas de dépendance fichier externe pour plus de robustesse)
const data = {
    "name": "StockMaster",
    "icon": "fa-cube",
    "color": "#fff",
    "children": [
        {
            "name": "Produits",
            "icon": "fa-box",
            "color": "#38bdf8",
            "desc": "Cœur du système : catalogue exhaustif et gestion dynamique.",
            "bullets": ["CRUD complet", "Suivi stock critique", "Scan intégré"],
            "children": [
                { "name": "Inventaire", "icon": "fa-list", "desc": "Vue tabulaire et grid des stocks." },
                { "name": "Détails", "icon": "fa-search-plus", "desc": "Métadonnées et historique produit." },
                { "name": "Catégories", "icon": "fa-tags", "desc": "Classification modulaire." }
            ]
        },
        {
            "name": "Flux Logistique",
            "icon": "fa-truck-loading",
            "color": "#4ade80",
            "desc": "Gestion des mouvements de stock entrées et sorties.",
            "bullets": ["Audit Log", "Validation QR", "Traçabilité Admin"],
            "children": [
                { "name": "Entrées", "icon": "fa-arrow-down", "desc": "Réception marchandises." },
                { "name": "Sorties", "icon": "fa-arrow-up", "desc": "Ventes et déstockage." },
                { "name": "Historique", "icon": "fa-history", "desc": "Journal des mouvements." }
            ]
        },
        {
            "name": "Intelligence",
            "icon": "fa-chart-pie",
            "color": "#fb923c",
            "desc": "Analyses et rapports automatisés.",
            "bullets": ["Graphiques tendances", "Top ventes", "Exports PDF/Excel"],
            "children": [
                { "name": "Dashboard", "icon": "fa-tachometer-alt", "desc": "KPIs en temps réel." },
                { "name": "Export PDF", "icon": "fa-file-pdf", "desc": "Rapports imprimables." },
                { "name": "Stats", "icon": "fa-chart-line", "desc": "Analyses financières." }
            ]
        },
        {
            "name": "Configuration",
            "icon": "fa-cog",
            "color": "#c084fc",
            "desc": "Paramètres système et sécurité.",
            "bullets": ["Gestion RBAC", "Dark Mode", "Internationalisation"],
            "children": [
                { "name": "Rôles", "icon": "fa-user-shield", "desc": "Permissions Admin/User." },
                { "name": "Apparence", "icon": "fa-paint-brush", "desc": "Thèmes et Langues." }
            ]
        }
    ]
};

// Layout Tree
const root = d3.hierarchy(data);
const tree = d3.tree().size([height - 100, width - 200]);
tree(root);

// Liens
const links = g.selectAll(".link")
    .data(root.links())
    .join("path")
    .attr("class", "link")
    .attr("d", d3.linkHorizontal().x(d => d.y).y(d => d.x));

// Nœuds
const nodes = g.selectAll(".node")
    .data(root.descendants())
    .join("g")
    .attr("class", "node")
    .attr("transform", d => `translate(${d.y + 50},${d.x + 50})`)
    .on("click", (e, d) => updatePanel(d.data));

nodes.append("circle")
    .attr("r", d => d.depth === 0 ? 12 : 8)
    .attr("fill", d => d.data.color)
    .attr("stroke", d => d.data.color)
    .style("filter", d => `drop-shadow(0 0 5px ${d.data.color})`);

nodes.append("text")
    .attr("dy", ".35em")
    .attr("x", d => d.children ? -15 : 15)
    .attr("text-anchor", d => d.children ? "end" : "start")
    .text(d => d.data.name);

// Initialisation
updatePanel(data);
centerView();

function updatePanel(nodeData) {
    document.getElementById('nodeTitle').innerText = nodeData.name;
    document.getElementById('nodeDesc').innerText = nodeData.desc || "Description détaillée du module et de ses fonctionnalités.";
    document.getElementById('mockupTitle').innerText = nodeData.name;
    document.getElementById('nodeType').innerText = nodeData.children ? "Module Principal" : "Fonctionnalité";
    
    // Update Bullets
    const list = document.getElementById('nodeBullets');
    list.innerHTML = "";
    const items = nodeData.bullets || ["Optimisation mobile", "Sécurisation SQL", "Fluidité UI"];
    items.forEach(txt => {
        const li = document.createElement('li');
        li.innerText = txt;
        list.appendChild(li);
    });

    // Update Mockup Visual (Fake UI code-based)
    const body = document.getElementById('mockupContent');
    body.innerHTML = `
        <div style="width:100%; height:15px; background:rgba(255,255,255,0.1); border-radius:10px;"></div>
        <div style="width:80%; height:15px; background:rgba(255,255,255,0.1); border-radius:10px;"></div>
        <div style="display:flex; gap:10px; margin-top:10px;">
            <div style="flex:1; height:80px; background:${nodeData.color}; opacity:0.2; border-radius:15px; border:1px solid ${nodeData.color}; display:flex; align-items:center; justify-content:center; font-size:2rem;">
                <i class="fas ${nodeData.icon}"></i>
            </div>
            <div style="flex:1; height:80px; background:rgba(255,255,255,0.05); border-radius:15px;"></div>
        </div>
        <div style="width:100%; height:40px; background:${nodeData.color}; opacity:0.5; border-radius:10px; margin-top:auto;"></div>
    `;
}

function centerView() {
    svg.transition().duration(750).call(
        d3.zoom().transform,
        d3.zoomIdentity.translate(50, 50).scale(0.9)
    );
}

function resetView() {
    centerView();
}

// Recherche
document.getElementById('searchInput').addEventListener('input', (e) => {
    const q = e.target.value.toLowerCase();
    nodes.selectAll("circle")
        .attr("r", d => d.data.name.toLowerCase().includes(q) && q.length > 1 ? 15 : (d.depth === 0 ? 12 : 8))
        .style("stroke-width", d => d.data.name.toLowerCase().includes(q) && q.length > 1 ? "4px" : "2px");
});
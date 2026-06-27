// CONFIGURATION
const width = window.innerWidth;
const height = window.innerHeight;
const nodeWidth = 220;  // Espace horizontal entre les niveaux
const nodeHeight = 40;  // Hauteur verticale par noeud (espacement)
const duration = 500;   // Vitesse animation

// ICONS (Unicode FontAwesome)
const ICONS = {
    folderOpen: '\uf07c',
    folderClosed: '\uf07b',
    file: '\uf15b',
    dart: '\uf121', // Code icon
    chevronRight: '\uf054',
    chevronDown: '\uf078'
};

// COULEURS (Doit matcher CSS)
const COLORS = {
    models: '#4ade80',
    views: '#60a5fa',
    viewmodels: '#fb923c',
    services: '#c084fc',
    utils: '#f87171',
    other: '#94a3b8',
    root: '#ffffff'
};

// INIT ZOOM
const zoom = d3.zoom().scaleExtent([0.1, 3]).on("zoom", (e) => {
    svgGroup.attr("transform", e.transform);
});

const svg = d3.select("#chart").append("svg")
    .attr("width", width)
    .attr("height", height)
    .call(zoom)
    .on("dblclick.zoom", null); // Désactiver double click zoom

const svgGroup = svg.append("g")
    .attr("transform", "translate(100, " + (height/2) + ")");

// ARBRE SETUP
// nodeSize([height, width]) -> Notez l'inversion pour un arbre horizontal
const treeMap = d3.tree().nodeSize([nodeHeight, nodeWidth]);

let root, i = 0;

// CHARGEMENT DATA
fetch('lib_tree.json')
    .then(response => {
        if(!response.ok) throw new Error("HTTP error " + response.status);
        return response.json();
    })
    .then(data => {
        root = d3.hierarchy(data, d => d.children);
        root.x0 = height / 2;
        root.y0 = 0;

        // Optionnel : Fermer tout sauf le premier niveau au démarrage
        if (root.children) {
             root.children.forEach(d => {
                 // Garder ouvert views/models/etc mais fermer leurs sous-dossiers
                 if(d.children) d.children.forEach(collapse);
             });
        }

        update(root);
    })
    .catch(err => {
        console.error(err);
        document.getElementById('chart').innerHTML = `<div style="color:white;text-align:center;padding-top:100px;">
            <h2>⚠️ Impossible de charger les données</h2>
            <p>Assurez-vous d'avoir lancé le serveur local : <br><code>npx serve</code> ou <code>python -m http.server</code></p>
            <p style="opacity:0.6; font-size:12px;">Erreur: ${err.message}</p>
        </div>`;
    });

function collapse(d) {
    if (d.children) {
        d._children = d.children;
        d._children.forEach(collapse);
        d.children = null;
    }
}

// UPDATE FUNCTION
function update(source) {
    const treeData = treeMap(root);
    const nodes = treeData.descendants();
    const links = treeData.links();

    // Normalisation positions
    nodes.forEach(d => d.y = d.depth * nodeWidth);

    // ****************** NOEUDS ******************
    const node = svgGroup.selectAll('g.node')
        .data(nodes, d => d.id || (d.id = ++i));

    // --- ENTER ---
    const nodeEnter = node.enter().append('g')
        .attr('class', 'node')
        .attr("transform", d => `translate(${source.y0},${source.x0})`)
        .on('click', click)
        .on('mouseover', showTooltip)
        .on('mouseout', hideTooltip);

    // 1. Background Pill (Rect)
    nodeEnter.append('rect')
        .attr('width', d => getTextWidth(d.data.name) + 50) // Auto-width
        .attr('height', 30)
        .attr('x', 0)
        .attr('y', -15)
        .attr('rx', 6)
        .style('fill', '#1e293b')
        .style('stroke', d => getCategoryColor(d.data.category));

    // 2. Icon (Main)
    nodeEnter.append('text')
        .attr('class', 'icon')
        .attr('x', 10)
        .attr('y', 5) // Centrage vertical approx
        .style('fill', d => getCategoryColor(d.data.category))
        .text(d => getIcon(d));

    // 3. Label Text
    nodeEnter.append('text')
        .attr('class', 'label')
        .attr('dy', 4)
        .attr('x', 35)
        .text(d => d.data.name);

    // 4. Chevron (Expand/Collapse) - Seulement si enfants potentiels
    nodeEnter.append('text')
        .attr('class', 'chevron')
        .attr('x', -15)
        .attr('y', 3)
        .text(ICONS.chevronRight)
        .style('opacity', d => (d.children || d._children) ? 1 : 0);

    // --- UPDATE ---
    const nodeUpdate = nodeEnter.merge(node);

    // Transition position
    nodeUpdate.transition().duration(duration)
        .attr("transform", d => `translate(${d.y},${d.x})`);

    // Rotation Chevron
    nodeUpdate.select('text.chevron')
        .transition().duration(duration)
        .attr("transform", d => d.children ? "rotate(90 -15 0)" : "rotate(0 -15 0)");

    // Couleur dynamique (active state)
    nodeUpdate.select('rect')
        .style('stroke', d => getCategoryColor(d.data.category))
        .style('fill', d => d.children ? '#283648' : '#1e293b'); // Plus clair si ouvert

    // --- EXIT ---
    const nodeExit = node.exit().transition().duration(duration)
        .attr("transform", d => `translate(${source.y},${source.x})`)
        .remove();

    nodeExit.select('rect').attr('width', 0);
    nodeExit.select('text').style('opacity', 1e-6);

    // ****************** LIENS (Curved) ******************
    const link = svgGroup.selectAll('path.link')
        .data(links, d => d.target.id);

    // Link Generator (Cubic Bezier Horizontal)
    const diagonal = d3.linkHorizontal()
        .x(d => d.y)
        .y(d => d.x);

    const linkEnter = link.enter().insert('path', "g")
        .attr("class", "link")
        .attr('d', d => {
            const o = {x: source.x0, y: source.y0};
            return diagonal({source: o, target: o});
        })
        .style("stroke", d => getCategoryColor(d.target.data.category));

    const linkUpdate = linkEnter.merge(link);

    linkUpdate.transition().duration(duration)
        .attr('d', diagonal);

    link.exit().transition().duration(duration)
        .attr('d', d => {
            const o = {x: source.x, y: source.y};
            return diagonal({source: o, target: o});
        })
        .remove();

    // Sauvegarde positions pour transition
    nodes.forEach(d => {
        d.x0 = d.x;
        d.y0 = d.y;
    });
}

// --- UTILS ---

function click(event, d) {
    // Toggle children
    if (d.children) {
        d._children = d.children;
        d.children = null;
    } else {
        d.children = d._children;
        d._children = null;
    }
    update(d);
}

function getIcon(d) {
    if (d.data.type === 'folder') {
        // Dossier ouvert ou fermé
        return d.children ? ICONS.folderOpen : ICONS.folderClosed;
    }
    // Fichier
    if (d.data.name.endsWith('.dart')) return ICONS.dart;
    return ICONS.file;
}

function getCategoryColor(cat) {
    return COLORS[cat] || COLORS.other;
}

// Estimation largeur texte pour le rectangle background
function getTextWidth(text) {
    const canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
    const context = canvas.getContext("2d");
    context.font = "13px 'Fira Code'";
    const metrics = context.measureText(text);
    return metrics.width;
}

// Tooltip Logic
const tooltip = document.getElementById('tooltip');
function showTooltip(e, d) {
    const size = d.data.size ? `<br><span style="opacity:0.7">Size: ${(d.data.size/1024).toFixed(1)} KB</span>` : '';
    
    tooltip.innerHTML = `
        <strong style="color:${getCategoryColor(d.data.category)}">${d.data.name}</strong>
        <div style="margin-top:4px; font-size:10px; color:#94a3b8;">${d.data.path}</div>
        ${size}
    `;
    tooltip.style.opacity = 1;
    tooltip.style.left = (e.pageX + 15) + 'px';
    tooltip.style.top = (e.pageY - 15) + 'px';
}

function hideTooltip() {
    tooltip.style.opacity = 0;
}

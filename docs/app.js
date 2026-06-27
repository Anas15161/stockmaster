let reportData = null;

// --- CONFIG ---
const CATEGORY_COLORS = {
    layout: '#3b82f6',
    navigation: '#8b5cf6',
    inputs: '#10b981',
    feedback: '#f59e0b',
    text_media: '#64748b',
    async: '#ec4899',
    styling: '#6366f1',
    state_management: '#06b6d4',
    custom: '#ef4444'
};

document.addEventListener('DOMContentLoaded', () => {
    fetch('widgets_report.json')
        .then(res => res.json())
        .then(data => {
            reportData = data;
            initDashboard();
            renderSidebar();
        })
        .catch(err => {
            console.error(err);
            document.querySelector('.content').innerHTML = `<h2 style="padding:40px; color:#ef4444;">Erreur: Impossible de charger widgets_report.json. Assurez-vous d'avoir lancé le serveur web.</h2>`;
        });

    // Search Filter
    document.getElementById('pageSearch').addEventListener('input', (e) => {
        renderSidebar(e.target.value);
    });
});

function initDashboard() {
    // Top Stats
    document.getElementById('statPages').innerText = reportData.globalStats.pagesCount;
    document.getElementById('statWidgets').innerText = reportData.globalStats.totalWidgetsDetected;
    document.getElementById('statCategories').innerText = Object.keys(reportData.globalStats.widgetsByCategory).length;

    // Charts
    renderCharts();
}

function renderSidebar(filter = '') {
    const list = document.getElementById('pageList');
    list.innerHTML = `
        <div class="nav-item active" onclick="showDashboard()">
            <span><i class="fas fa-home"></i> Dashboard</span>
        </div>
    `;

    reportData.pages
        .filter(p => p.name.toLowerCase().includes(filter.toLowerCase()))
        .forEach(page => {
            const item = document.createElement('div');
            item.className = 'nav-item';
            item.innerHTML = `
                <span><i class="far fa-file-code"></i> ${page.name}</span>
                <span class="badge">${page.totalWidgetsCount}</span>
            `;
            item.onclick = () => showPageDetail(page, item);
            list.appendChild(item);
        });
}

function showDashboard() {
    document.querySelectorAll('.view').forEach(el => el.classList.remove('active'));
    document.getElementById('dashboardView').classList.add('active');
    
    // Reset Sidebar Active
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
    document.querySelector('.nav-item').classList.add('active');
    
    document.getElementById('headerTitle').innerText = "Dashboard";
    document.getElementById('headerBadges').innerHTML = '';
}

function showPageDetail(page, navItem) {
    document.querySelectorAll('.view').forEach(el => el.classList.remove('active'));
    document.getElementById('pageDetailView').classList.add('active');

    // Sidebar Active State
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
    navItem.classList.add('active');

    // Header
    document.getElementById('headerTitle').innerText = page.name;
    document.getElementById('headerBadges').innerHTML = `<span style="font-family:monospace; color:#94a3b8; font-size:0.8rem;">${page.path}</span>`;

    // Page Stats
    document.getElementById('pTotal').innerText = page.totalWidgetsCount;
    document.getElementById('pDistinct').innerText = page.totalWidgetsDistinct;
    
    const complexity = page.totalWidgetsCount > 50 ? 'High' : (page.totalWidgetsCount > 20 ? 'Medium' : 'Low');
    const compEl = document.getElementById('pComplexity');
    compEl.innerText = complexity;
    compEl.style.color = complexity === 'High' ? '#ef4444' : (complexity === 'Medium' ? '#f59e0b' : '#10b981');

    // Group by Category
    const byCat = {};
    page.widgets.forEach(w => {
        if(!byCat[w.category]) byCat[w.category] = [];
        byCat[w.category].push(w);
    });

    const container = document.getElementById('widgetsContainer');
    container.innerHTML = '';

    Object.keys(byCat).forEach(cat => {
        const section = document.createElement('div');
        section.className = 'cat-section';
        section.innerHTML = `<h3 class="cat-title"><span class="cat-badge ${cat}">${cat}</span> ${byCat[cat].length} Widgets</h3>`;
        
        const grid = document.createElement('div');
        grid.className = 'widgets-grid';

        byCat[cat].forEach(w => {
            const card = document.createElement('div');
            card.className = 'widget-card';
            
            let codeBlocks = '';
            w.sampleLines.forEach(sample => {
                codeBlocks += `<div class="w-code"><pre><code class="language-dart">${escapeHtml(sample.code)}</code></pre></div>`;
            });

            card.innerHTML = `
                <div class="w-header">
                    <span class="w-name">${w.name}</span>
                    <span class="w-count">x${w.count}</span>
                </div>
                ${codeBlocks}
            `;
            grid.appendChild(card);
        });

        section.appendChild(grid);
        container.appendChild(section);
    });

    // Re-run Prism highlight
    Prism.highlightAll();
}

function renderCharts() {
    const ctxCat = document.getElementById('categoryChart').getContext('2d');
    const catLabels = Object.keys(reportData.globalStats.widgetsByCategory);
    const catData = Object.values(reportData.globalStats.widgetsByCategory);
    
    new Chart(ctxCat, {
        type: 'doughnut',
        data: {
            labels: catLabels,
            datasets: [{
                data: catData,
                backgroundColor: catLabels.map(c => CATEGORY_COLORS[c] || '#64748b'),
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'right', labels: { color: '#94a3b8' } }
            }
        }
    });

    const ctxTop = document.getElementById('topWidgetsChart').getContext('2d');
    const topData = reportData.globalStats.topWidgets;
    
    new Chart(ctxTop, {
        type: 'bar',
        data: {
            labels: topData.map(d => d.name),
            datasets: [{
                label: 'Occurrences',
                data: topData.map(d => d.count),
                backgroundColor: '#42affa',
                borderRadius: 4
            }]
        },
        options: {
            scales: {
                y: { grid: { color: '#334155' }, ticks: { color: '#94a3b8' } },
                x: { grid: { display: false }, ticks: { color: '#94a3b8' } }
            },
            plugins: { legend: { display: false } }
        }
    });
}

function escapeHtml(text) {
    return text.replace(/&/g, "&amp;")
               .replace(/</g, "&lt;")
               .replace(/>/g, "&gt;")
               .replace(/"/g, "&quot;")
               .replace(/'/g, "&#039;");
}

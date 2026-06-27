// --- STATE ---
let scenario = null;
let currentStep = 0;
let autoPlay = false;
let autoPlayInterval = null;

// --- DOM ---
const dom = {
    title: document.getElementById('stepTitle'),
    subtitle: document.getElementById('stepSubtitle'),
    desc: document.getElementById('stepDesc'),
    bullets: document.getElementById('stepBullets'),
    kpiLabel: document.getElementById('kpiLabel'),
    kpiVal: document.getElementById('kpiVal'),
    img: document.getElementById('screenImg'),
    timeline: document.getElementById('timelineDots'),
    progress: document.getElementById('progressBar'),
    contentBox: document.querySelector('.content-box'),
    btnPrev: document.getElementById('btnPrev'),
    btnNext: document.getElementById('btnNext'),
    stepLabel: document.getElementById('stepLabel')
};

// --- INIT ---
document.addEventListener('DOMContentLoaded', () => {
    loadScenario();
    
    // Keyboard
    document.addEventListener('keydown', (e) => {
        if(e.key === 'ArrowRight') nextStep();
        if(e.key === 'ArrowLeft') prevStep();
    });

    // Auto Play Toggle
    document.getElementById('autoToggle').addEventListener('change', (e) => {
        autoPlay = e.target.checked;
        if(autoPlay) startAutoPlay();
        else stopAutoPlay();
    });
});

async function loadScenario() {
    try {
        const res = await fetch('assets/scenario.json');
        scenario = await res.json();
        
        // Init Timeline
        scenario.steps.forEach((step, i) => {
            const dot = document.createElement('div');
            dot.className = 'step-dot';
            dot.innerText = i + 1;
            dot.onclick = () => goToStep(i);
            dom.timeline.appendChild(dot);
        });

        renderStep(0);
    } catch (e) {
        console.error("Erreur chargement JSON", e);
        document.body.innerHTML = "<h1 style='text-align:center; margin-top:50px;'>Erreur: Lancez le serveur local (python/npx)</h1>";
    }
}

// --- RENDER ---
function renderStep(index) {
    if(!scenario) return;
    
    // Bounds
    if(index < 0) index = 0;
    if(index >= scenario.steps.length) {
        showSummary();
        return;
    }

    currentStep = index;
    const step = scenario.steps[index];

    // Anim Out
    dom.contentBox.classList.remove('visible');
    dom.img.style.opacity = 0;

    setTimeout(() => {
        // Content Update
        dom.stepLabel.innerText = `ÉTAPE ${index + 1} / ${scenario.steps.length}`;
        dom.title.innerText = step.title;
        dom.subtitle.innerText = step.subtitle;
        dom.desc.innerText = step.desc;
        dom.img.src = step.screenshot;

        // Bullets
        dom.bullets.innerHTML = '';
        step.bullets.forEach(b => {
            const li = document.createElement('li');
            li.innerHTML = `<i class="fas fa-check-circle"></i> ${b}`;
            dom.bullets.appendChild(li);
        });

        // KPI
        dom.kpiLabel.innerText = step.kpi.label;
        dom.kpiVal.innerText = step.kpi.value;
        animateValue(dom.kpiVal, step.kpi.value);

        // Timeline Update
        const dots = document.querySelectorAll('.step-dot');
        dots.forEach((d, i) => {
            d.classList.toggle('active', i === index);
            d.classList.toggle('done', i < index);
        });
        const progressPct = (index / (scenario.steps.length - 1)) * 100;
        dom.progress.style.width = `${progressPct}%`;

        // Buttons
        dom.btnPrev.disabled = index === 0;
        dom.btnNext.innerHTML = index === scenario.steps.length - 1 ? 'Terminer <i class="fas fa-flag-checkered"></i>' : 'Suivant <i class="fas fa-arrow-right"></i>';

        // Anim In
        dom.contentBox.classList.add('visible');
        dom.img.style.opacity = 1;

    }, 300);
}

// --- ACTIONS ---
function nextStep() {
    renderStep(currentStep + 1);
    resetAutoPlay();
}

function prevStep() {
    renderStep(currentStep - 1);
    resetAutoPlay();
}

function goToStep(i) {
    renderStep(i);
    resetAutoPlay();
}

// --- AUTO PLAY ---
function startAutoPlay() {
    if(autoPlayInterval) clearInterval(autoPlayInterval);
    autoPlayInterval = setInterval(() => {
        if(currentStep < scenario.steps.length - 1) nextStep();
        else stopAutoPlay();
    }, 4000);
}

function stopAutoPlay() {
    if(autoPlayInterval) clearInterval(autoPlayInterval);
    autoPlayInterval = null;
    document.getElementById('autoToggle').checked = false;
    autoPlay = false;
}

function resetAutoPlay() {
    if(autoPlay) startAutoPlay();
}

// --- SUMMARY ---
function showSummary() {
    const overlay = document.getElementById('summary-overlay');
    overlay.classList.add('visible');
    
    // Confettis (simple JS)
    createConfetti();
}

function closeSummary() {
    document.getElementById('summary-overlay').classList.remove('visible');
    goToStep(0);
}

function animateValue(obj, valStr) {
    // Simple effet flash
    obj.style.transform = "scale(1.5)";
    setTimeout(() => obj.style.transform = "scale(1)", 200);
}

function createConfetti() {
    // Basic effect placeholder
}

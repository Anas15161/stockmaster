// --- CONFIGURATION ---
const SCREENS = [
    { src: '../login.jpeg', title: "Authentification", desc: "Connexion sécurisée (SHA-256)" },
    { src: '../Tableau_de_bord.png', title: "Dashboard", desc: "Vue synthétique temps réel" },
    { src: '../products_list.png', title: "Catalogue", desc: "Liste produits avec indicateurs stock" },
    { src: '../prodcut_details.png', title: "Détails Produit", desc: "Fiche complète & Actions" },
    { src: '../add_product.png', title: "Saisie", desc: "Formulaire d'ajout & modification" },
    { src: '../codescanner.png', title: "Scanner", desc: "Lecture code-barres caméra" },
    { src: '../transactions_history.png', title: "Historique", desc: "Traçabilité complète (Logs)" },
    { src: '../rapport&stistics.png', title: "Rapports", desc: "Statistiques & Export PDF/CSV" },
    { src: '../admin_setting.png', title: "Administration", desc: "Gestion des utilisateurs & Rôles" }
];

const container = document.getElementById('carousel3D');
const thumbsContainer = document.getElementById('thumbsContainer');

let cellCount = SCREENS.length;
let selectedIndex = 0;
let theta = 360 / cellCount;
let radius = Math.round( (280 / 2) / Math.tan( Math.PI / cellCount ) ) + 40; 

let currentRotation = 0; // Rotation absolue en degrés

// --- INITIALIZATION ---
function init() {
    container.innerHTML = '';
    thumbsContainer.innerHTML = '';

    SCREENS.forEach((screen, index) => {
        // Slide 3D
        const elm = document.createElement('div');
        elm.className = 'carousel-item';
        // Positionnement initial
        const angle = theta * index;
        elm.style.transform = `rotateY(${angle}deg) translateZ(${radius}px)`;
        
        elm.innerHTML = `
            <div class="phone-frame"></div>
            <img src="${screen.src}" alt="${screen.title}" onerror="this.src='https://via.placeholder.com/280x560?text=Image+Not+Found'">
            <div class="screen-info">
                <h3>${screen.title}</h3>
                <p>${screen.desc}</p>
            </div>
        `;
        container.appendChild(elm);

        // Thumbnail
        const thumb = document.createElement('img');
        thumb.src = screen.src;
        thumb.className = 'thumb';
        thumb.onclick = () => goToSlide(index);
        thumbsContainer.appendChild(thumb);
    });

    rotateTo(0);
}

// --- CORE LOGIC ---

function rotateTo(index) {
    selectedIndex = index;
    
    // Calcul de l'angle cible : on inverse l'index pour que la rotation soit naturelle
    // Pour aller à l'item 1 (30deg), on doit tourner le conteneur de -30deg.
    const angle = theta * index * -1;
    container.style.transform = `translateZ(-${radius}px) rotateY(${angle}deg)`;

    // Update classes
    const items = document.querySelectorAll('.carousel-item');
    items.forEach((item, i) => {
        if (i === selectedIndex) item.classList.add('active');
        else item.classList.remove('active');
    });

    const thumbs = document.querySelectorAll('.thumb');
    thumbs.forEach((t, i) => {
        if (i === selectedIndex) t.classList.add('active');
        else t.classList.remove('active');
    });
}

function nextSlide() {
    selectedIndex++;
    if (selectedIndex >= cellCount) selectedIndex = 0;
    rotateTo(selectedIndex);
}

function prevSlide() {
    selectedIndex--;
    if (selectedIndex < 0) selectedIndex = cellCount - 1;
    rotateTo(selectedIndex);
}

function goToSlide(index) {
    rotateTo(index);
}

// --- MODES ---
function setMode(mode) {
    const btns = document.querySelectorAll('.btn-mode');
    btns.forEach(b => b.classList.remove('active'));
    
    if(mode === 'carousel') {
        btns[0].classList.add('active');
        // Mode aéré : on ajoute de l'espace (+100px)
        radius = Math.round( (280 / 2) / Math.tan( Math.PI / cellCount ) ) + 100;
    } 
    else if(mode === 'cube') {
        btns[1].classList.add('active');
        // Mode Compact : Rayon minimal pour que les bords se touchent presque (+20px marge)
        // CORRECTION : On utilise bien cellCount ici, pas 4
        radius = Math.round( (280 / 2) / Math.tan( Math.PI / cellCount ) ) + 20; 
    }

    // Ré-appliquer le radius aux éléments
    const items = document.querySelectorAll('.carousel-item');
    items.forEach((item, i) => {
        const angle = theta * i;
        item.style.transform = `rotateY(${angle}deg) translateZ(${radius}px)`;
    });
    
    // Ré-appliquer la rotation globale
    rotateTo(selectedIndex);
}

// --- CONTROLS ---
document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowLeft') prevSlide();
    if (e.key === 'ArrowRight') nextSlide();
});

let autoRotateInterval = null;
function toggleAutoRotate() {
    if (autoRotateInterval) {
        clearInterval(autoRotateInterval);
        autoRotateInterval = null;
        document.querySelectorAll('.btn-mode')[2].classList.remove('active');
    } else {
        nextSlide();
        autoRotateInterval = setInterval(nextSlide, 3000);
        document.querySelectorAll('.btn-mode')[2].classList.add('active');
    }
}

// Drag & Swipe
let startX = 0;
let isDragging = false;

container.addEventListener('mousedown', (e) => {
    startX = e.pageX;
    isDragging = true;
    container.style.transition = 'none';
});

window.addEventListener('mouseup', (e) => {
    if(!isDragging) return;
    isDragging = false;
    container.style.transition = 'transform 0.8s cubic-bezier(0.2, 0.8, 0.2, 1)';
    const diff = e.pageX - startX;
    
    if (Math.abs(diff) > 50) {
        if (diff > 0) prevSlide();
        else nextSlide();
    } else {
        rotateTo(selectedIndex); // Re-centrer
    }
});

container.addEventListener('mousemove', (e) => {
    if(!isDragging) return;
    const diff = e.pageX - startX;
    // Preview
    const currentBaseAngle = theta * selectedIndex * -1;
    const dragAngle = diff / 5;
    container.style.transform = `translateZ(-${radius}px) rotateY(${currentBaseAngle + dragAngle}deg)`;
});

init();
setTimeout(() => container.classList.add('intro-anim'), 100);
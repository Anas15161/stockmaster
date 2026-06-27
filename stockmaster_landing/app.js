// --- CONFIGURATION ---
const SCREENSHOTS_URL = 'assets/screenshots.json';
const carouselTrack = document.getElementById('carouselTrack');
const modal = document.getElementById('imageModal');
const modalImg = document.getElementById('modalImg');

// --- INIT ---
document.addEventListener('DOMContentLoaded', () => {
    loadScreenshots();
    setupIntersectionObserver();
    initHeroParallax();
    // Animation de compteur (si présents)
    setupCounters();
});

// --- HERO PARALLAX EFFECT (3D TILT) ---
function initHeroParallax() {
    const heroSection = document.getElementById('hero');
    const visual = document.getElementById('heroVisual');
    const phone = document.getElementById('phoneMockup');
    const badge1 = document.querySelector('.badge-1');
    const badge2 = document.querySelector('.badge-2');

    if(!visual || !phone) return;

    heroSection.addEventListener('mousemove', (e) => {
        const { offsetWidth: width, offsetHeight: height } = heroSection;
        let { offsetX: x, offsetY: y } = e;

        if (e.target !== heroSection) {
            x = x + e.target.offsetLeft; 
            y = y + e.target.offsetTop;
        }

        const moveX = (x / width - 0.5) * 2; 
        const moveY = (y / height - 0.5) * 2;

        const rotateY = moveX * 15; 
        const rotateX = moveY * -15;

        phone.style.transform = `rotateY(${rotateY}deg) rotateX(${rotateX}deg)`;

        if(badge1) badge1.style.transform = `translateZ(80px) translateX(${moveX * -40}px) translateY(${moveY * -20}px)`;
        if(badge2) badge2.style.transform = `translateZ(60px) translateX(${moveX * -50}px) translateY(${moveY * -15}px)`;
    });

    heroSection.addEventListener('mouseleave', () => {
        phone.style.transform = `rotateY(-12deg) rotateX(8deg)`;
        if(badge1) badge1.style.transform = `translateZ(60px)`;
        if(badge2) badge2.style.transform = `translateZ(60px)`;
    });
}

// --- LOAD DATA ---
async function loadScreenshots() {
    try {
        const response = await fetch(SCREENSHOTS_URL);
        const screens = await response.json();
        
        screens.forEach((screen) => {
            const item = document.createElement('div');
            item.className = 'carousel-item';
            item.style.minWidth = '300px'; 
            item.style.height = '600px'; // Un peu plus grand
            item.onclick = () => openModal(screen.file);
            item.innerHTML = `
                <img src="${screen.file}" alt="${screen.title}" style="width:100%; height:100%; object-fit:cover; transition:transform 0.5s;">
                <div style="position:absolute; bottom:0; left:0; right:0; padding:30px 20px; background:linear-gradient(to top, rgba(2,6,23,0.95), transparent); color:white;">
                    <h4 style="margin-bottom:5px; font-size:1.1rem;">${screen.title}</h4>
                    <small style="opacity:0.7;">${screen.desc}</small>
                </div>
            `;
            // Hover scale
            item.onmouseenter = () => item.querySelector('img').style.transform = 'scale(1.1)';
            item.onmouseleave = () => item.querySelector('img').style.transform = 'scale(1)';

            carouselTrack.appendChild(item);
        });
    } catch (error) {
        console.warn('JSON Load Error', error);
        carouselTrack.innerHTML = '<p style="color:white; text-align:center; width:100%; opacity:0.6;">Chargement des images... (lancez le serveur local)</p>';
    }
}

// --- MODAL ---
function openModal(src) {
    modal.style.display = 'flex';
    setTimeout(() => modal.style.opacity = '1', 10);
    modalImg.src = src;
    document.body.style.overflow = 'hidden';
}
function closeModal() {
    modal.style.opacity = '0';
    setTimeout(() => modal.style.display = 'none', 300);
    document.body.style.overflow = 'auto';
}
modal.onclick = (e) => { if(e.target === modal) closeModal(); };
document.addEventListener('keydown', (e) => { if(e.key === 'Escape') closeModal(); });

// --- OBSERVER (SCROLL ANIMATIONS) ---
function setupIntersectionObserver() {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });

    // Cible tous les éléments animables
    const elements = document.querySelectorAll('.reveal, .bento-card, .target-card, .feature-card, .timeline-item, .iso-container');
    elements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(40px)';
        el.style.transition = 'all 0.8s cubic-bezier(0.2, 0.8, 0.2, 1)'; // Easing plus moderne
        observer.observe(el);
    });
}

function setupCounters() {
    // Si on voulait remettre des compteurs, le code serait ici.
    // Pour cette version texte riche, ils sont moins prioritaires mais supportés si besoin.
}

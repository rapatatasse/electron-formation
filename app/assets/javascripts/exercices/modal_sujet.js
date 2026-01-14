class ModalSujetManager {
    constructor() {
        this.modal = document.getElementById('sujetModal');
        this.closeBtn = document.getElementById('closeModal');
        this.infoBtn = document.getElementById('infobtn');
        this.sujetText = document.getElementById('sujetText');
        this.corrigeDropdown = document.getElementById('corrigeDropdown');
        
        this.currentBackground = 'fond1.jpg';
        
        this.init();
    }
    
    init() {
        this.infoBtn.addEventListener('click', () => this.openModal());
        
        this.closeBtn.addEventListener('click', () => this.closeModal());
        
        this.modal.addEventListener('click', (e) => {
            if (e.target === this.modal) {
                this.closeModal();
            }
        });
        
        this.detectCurrentBackground();
    }
    
    detectCurrentBackground() {
        const backgroundImg = document.querySelector('.background-image');
        if (backgroundImg && backgroundImg.src) {
            const src = backgroundImg.src;
            const filename = src.split('/').pop();
            this.currentBackground = filename;
        }
        
        const urlParams = new URLSearchParams(window.location.search);
        const fondParam = urlParams.get('fond');
        if (fondParam) {
            this.currentBackground = `fond${fondParam}.jpg`;
        }
    }
    
    openModal() {
        this.detectCurrentBackground();
        this.loadSujetData();
        this.modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
    
    closeModal() {
        this.modal.classList.remove('active');
        document.body.style.overflow = 'auto';
    }
    
    loadSujetData() {
        if (!SUJET_CORRIGE || !SUJET_CORRIGE[this.currentBackground]) {
            this.sujetText.textContent = 'Aucun sujet disponible pour ce fond.';
            this.corrigeDropdown.innerHTML = '<p style="color: #95a5a6;">Aucun corrigé disponible.</p>';
            return;
        }
        
        const data = SUJET_CORRIGE[this.currentBackground][0];
        
        this.sujetText.textContent = data.Sujet || 'Sujet non défini';
        
        this.corrigeDropdown.innerHTML = '';
        
        if (data.Corrige && data.Corrige.length > 0) {
            const corrigeDiv = document.createElement('div');
            corrigeDiv.className = 'corrige-item';
            
            const header = document.createElement('div');
            header.className = 'corrige-header';
            header.innerHTML = `
                <span>Afficher les corrections (${data.Corrige.length})</span>
                <span class="corrige-arrow">▼</span>
            `;
            
            const body = document.createElement('div');
            body.className = 'corrige-body';
            
            const content = document.createElement('div');
            content.className = 'corrige-content';
            
            data.Corrige.forEach((corrigeItem, index) => {
                const [text, imageName] = corrigeItem;
                
                const correctionSection = document.createElement('div');
                correctionSection.className = 'correction-section';
                
                const correctionTitle = document.createElement('h4');
                correctionTitle.className = 'correction-title';
                correctionTitle.textContent = `${index + 1} Correction`;
                correctionSection.appendChild(correctionTitle);
                
                const textElement = document.createElement('p');
                textElement.className = 'corrige-text';
                textElement.textContent = text;
                correctionSection.appendChild(textElement);
                
                if (imageName) {
                    const img = document.createElement('img');
                    img.className = 'corrige-image';
                    img.src = `ImagesCorrige/${imageName}`;
                    img.alt = `${index + 1} Correction`;
                    img.onerror = () => {
                        img.src = `ImagesPourFond/${imageName}`;
                        img.onerror = () => {
                            img.style.display = 'none';
                        };
                    };
                    correctionSection.appendChild(img);
                }
                
                content.appendChild(correctionSection);
            });
            
            body.appendChild(content);
            corrigeDiv.appendChild(header);
            corrigeDiv.appendChild(body);
            
            header.addEventListener('click', () => {
                corrigeDiv.classList.toggle('active');
            });
            
            this.corrigeDropdown.appendChild(corrigeDiv);
        } else {
            this.corrigeDropdown.innerHTML = '<p style="color: #95a5a6;">Aucun corrigé disponible.</p>';
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new ModalSujetManager();
});

// Fonction helper pour gérer les chemins des assets Rails
function assetUrl(path) {
    // Si c'est une data URL, la retourner directement
    if (path.startsWith('data:')) {
        return path;
    }
    
    // Récupérer les chemins depuis l'attribut data-asset-paths
    const backgroundArea = document.getElementById('backgroundArea');
    if (!backgroundArea) {
        console.warn('⚠️ backgroundArea non trouvé');
        return path;
    }
    
    const assetPathsJson = backgroundArea.getAttribute('data-asset-paths');
    if (!assetPathsJson) {
        console.warn('⚠️ data-asset-paths non trouvé');
        return path;
    }
    
    try {
        const assetPaths = JSON.parse(assetPathsJson);
        console.log('📦 Asset paths loaded:', assetPaths);
        
        // Déterminer le type de ressource
        if (path.includes('ImageFond/fond')) {
            // Format: "ImageFond/fond1.jpg"
            const match = path.match(/fond(\d+)\./);
            console.log('🔍 Searching for fond, path:', path, 'match:', match);
            if (match) {
                const id = parseInt(match[1]);
                console.log('🔍 Looking for fond id:', id, 'in', assetPaths.fonds);
                const found = assetPaths.fonds.find(f => f.id === id);
                if (found) {
                    console.log('✅ Asset fond trouvé:', path, '->', found.path);
                    return found.path;
                } else {
                    console.warn('⚠️ Fond id', id, 'not found in mapping');
                }
            } else {
                console.warn('⚠️ Regex did not match for path:', path);
            }
        } else if (path.includes('ImagesZ1/image')) {
            const match = path.match(/image\((\d+)\)/);
            if (match) {
                const id = parseInt(match[1]);
                const found = assetPaths.z1.find(f => f.id === id);
                if (found) {
                    console.log('✅ Asset Z1 trouvé:', path, '->', found.path);
                    return found.path;
                }
            }
        } else if (path.includes('ImagesZ2/image')) {
            const match = path.match(/image\((\d+)(bis)?\)/);
            if (match) {
                const id = match[1];
                const isBis = match[2] === 'bis';
                if (isBis) {
                    const key = `${id}bis`;
                    const found = (assetPaths.z2bis || []).find(f => f.key === key);
                    if (found) {
                        console.log('✅ Asset Z2 bis trouvé:', path, '->', found.path);
                        return found.path;
                    }
                } else {
                    const numericId = parseInt(id);
                    const found = assetPaths.z2.find(f => f.id === numericId);
                    if (found) {
                        console.log('✅ Asset Z2 trouvé:', path, '->', found.path);
                        return found.path;
                    }
                }
            }
        } else if (path.includes('ImagesZ3/image')) {
            const match = path.match(/image\((\d+)\)/);
            if (match) {
                const id = parseInt(match[1]);
                const found = assetPaths.z3.find(f => f.id === id);
                if (found) {
                    console.log('✅ Asset Z3 trouvé:', path, '->', found.path);
                    return found.path;
                }
            }
        } else if (path.includes('ImagesPourFond/')) {
            // Format: "ImagesPourFond/31_touret.png"
            const filename = path.split('ImagesPourFond/')[1];
            if (filename && assetPaths.pourFond && assetPaths.pourFond[filename]) {
                console.log('✅ Asset PourFond trouvé:', path, '->', assetPaths.pourFond[filename]);
                return assetPaths.pourFond[filename];
            }
        }
        
        console.warn('⚠️ Asset non trouvé dans le mapping:', path);
        return path;
    } catch (e) {
        console.error('❌ Erreur parsing data-asset-paths:', e);
        return path;
    }
}

class DragDropManager {
    constructor() {
        this.draggedElement = null;
        this.originalParent = null;
        this.originalPosition = { x: 0, y: 0 };
        this.images = [];
        this.backgroundArea = document.getElementById('backgroundArea');
        this.resetBtn = document.getElementById('resetBtn');
        this.resetConnecteurBtn = document.getElementById('resetConnecteurBtn');
        this.flipModeBtn = document.getElementById('flipModeBtn');
        this.flipModeBtnHautBas = document.getElementById('flipModeBtnHautBas');
        this.backgroundScale = 1; // Ratio d'échelle de l'image de fond
        
        // Système de connecteurs entre images
        this.connectorMode = false;
        this.disconnectorMode = false;
        this.firstSelectedImage = null;
        this.connectors = [];
        
        // Mode retournement horizontal
        this.flipMode = false;
        
        // Mode retournement vertical
        this.flipModeHautBas = false;
        
        // Gestion des fonds d'écran
        this.currentBackgroundIndex = 1;
        this.maxBackgroundIndex = 1;
        this.backgroundImage = document.querySelector('.background-image');
        this.prevBgBtn = document.getElementById('prevBgBtn');
        this.nextBgBtn = document.getElementById('nextBgBtn');
        
        // Variables pour le tactile
        this.isTouchDragging = false;
        this.touchOffset = { x: 0, y: 0 };
        
        // Système d'attachement parent-enfant (zone2 sur zone1)
        this.attachments = new Map(); // Map<imageEnfant, {parent: imageParent, offsetX: number, offsetY: number}>
        
        this.init();
    }
    

    async init() {
        // Vérifier si un fond est spécifié dans l'URL
        const urlParams = new URLSearchParams(window.location.search);
        const fondParam = urlParams.get('fond');
        if (fondParam) {
            this.currentBackgroundIndex = parseInt(fondParam);
            this.backgroundImage.src = assetUrl(`ImageFond/fond${this.currentBackgroundIndex}.jpg`);
        }
        
        await this.detectAvailableBackgrounds();
        this.calculateBackgroundScale();
        this.loadImages();
        this.setupEventListeners();
        
        // Nettoyer les pointer-events au cas où
        this.cleanupPointerEvents();
    }
    
    cleanupPointerEvents() {
        // S'assurer que toutes les images draggables ont pointer-events activé
        const draggableImages = document.querySelectorAll('.draggable-image');
        draggableImages.forEach(img => {
            if (!img.classList.contains('positioned-image')) {
                img.style.pointerEvents = 'auto';
            }
        });
    }
    
    async detectAvailableBackgrounds() {
        // Détecter combien de fonds d'écran sont disponibles
        let index = 1;
        let foundMax = false;
        
        while (!foundMax && index <= 20) { // Limite à 20 pour éviter une boucle infinie
            const exists = await this.imageExists(`ImageFond/fond${index}.jpg`);
            if (exists) {
                this.maxBackgroundIndex = index;
                index++;
            } else {
                foundMax = true;
            }
        }
        
        console.log(`📁 ${this.maxBackgroundIndex} fond(s) d'écran détecté(s)`);
    }

    calculateBackgroundScale() {
        // Attendre que l'image de fond soit chargée pour calculer son ratio
        const backgroundImg = document.querySelector('.background-image');
        
        if (backgroundImg.complete) {
            this.computeScale(backgroundImg);
        } else {
            backgroundImg.addEventListener('load', () => {
                this.computeScale(backgroundImg);
            });
        }
    }

    computeScale(img) {
        // Dimensions naturelles de l'image
        const naturalWidth = img.naturalWidth;
        const naturalHeight = img.naturalHeight;
        
        // Dimensions affichées de l'image
        const displayedHeight = img.offsetHeight;
        const displayedWidth = img.offsetWidth;
        
        // Calculer le ratio d'échelle (l'image de fond utilise height: 100%)
        this.backgroundScale = displayedHeight / naturalHeight;
        
        console.log(`📐 Ratio d'échelle de l'image de fond: ${this.backgroundScale.toFixed(4)}`);
        console.log(`   Dimensions naturelles: ${naturalWidth}x${naturalHeight}px`);
        console.log(`   Dimensions affichées: ${displayedWidth}x${displayedHeight}px`);
    }

    async loadImages() {
        // Charger les images depuis les dossiers ImagesZ1, Z2 et Z3
        const zones = ['ImagesZ1', 'ImagesZ2', 'ImagesZ3'];
        
        for (let i = 0; i < zones.length; i++) {
            const zoneContainer = document.querySelector(`[data-zone="${i + 1}"]`);
            
            try {
                // Pour cette démo, nous allons créer des images d'exemple
                // En production, vous pourriez utiliser une API pour lister les fichiers
                await this.loadImagesFromFolder(zones[i], i + 1, zoneContainer);
            } catch (error) {
                console.log(`Pas d'images trouvées dans ${zones[i]}`);
            }
        }
    }


    async loadImagesFromFolder(folderName, zoneNumber, container) {
        const foundImages = [];
        const colorliaison = [['image(1)',"#26ff4eff"], ['image(2)', '#ce9803ff'], ['image(3)', '#0599efff'], ['image(4)', '#477a73ff'], ['image(5)', '#cc9f0aec'], ['image(6)', '#07b029ec']];
        // Essayer de détecter automatiquement les images avec des noms courants
        const commonPatterns = folderName === 'ImagesZ2'
            ? ['image(1)', 'image(2)', 'image(3)', 'image(4)', 'image(5)', 'image(6)', 'image(7)', 'image(8)', 'image(9)']
            : [
                // Noms avec parenthèses (comme "image(1).png")
                'image(1)', 'image(2)', 'image(3)', 'image(4)', 'image(5)', 'image(6)', 'image(7)', 'image(8)', 'image(9)'
            ];
        
        const extensions = ['png'];
        
        // Tester toutes les combinaisons
        for (const pattern of commonPatterns) {
            for (const ext of extensions) {
                const imagePath = `${folderName}/${pattern}.${ext}`;
                if (await this.imageExists(imagePath)) {
                    // Trouver la couleur associée à cette image
                    const colorEntry = colorliaison.find(entry => entry[0] === pattern);
                    const color = colorEntry ? colorEntry[1] : '#27ae60'; // Couleur par défaut
                    foundImages.push({path: imagePath, color: color});
                }
            }
        }

        // Si aucune image trouvée, créer des images d'exemple SAUF pour la Zone 3
        if (foundImages.length === 0) {
            if (zoneNumber !== 3) {
                this.createExampleImages(folderName, zoneNumber, container);
                console.log(`Aucune image trouvée dans ${folderName}. Images d'exemple créées.`);

            } else {
                console.log(`Aucune image trouvée dans ${folderName}. Zone 3 reste vide.`);
            }
        } else {
            foundImages.forEach(imageData => {
                this.createDraggableImage(imageData.path, container, zoneNumber, '', imageData.color);
            });
            console.log(`✅ ${foundImages.length} image(s) chargée(s) depuis ${folderName}:`, foundImages.map(img => img.path));
        }
    }

    imageExists(imagePath) {
        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => resolve(true);
            img.onerror = () => resolve(false);
            img.src = assetUrl(imagePath);
        });
    }

    createExampleImages(folderName, zoneNumber, container) {
        // Créer des images d'exemple colorées pour la démonstration
        const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD'];
        
        for (let i = 1; i <= 3; i++) {
            const canvas = document.createElement('canvas');
            canvas.width = 100;
            canvas.height = 100;
            const ctx = canvas.getContext('2d');
            
            // Dessiner un carré coloré avec du texte
            ctx.fillStyle = colors[(zoneNumber - 1) * 2 + (i - 1)] || colors[0];
            ctx.fillRect(0, 0, 100, 100);
            
            ctx.fillStyle = 'white';
            ctx.font = '16px Arial';
            ctx.textAlign = 'center';
            ctx.fillText(`Z${zoneNumber}-${i}`, 50, 55);
            
            // Convertir le canvas en image
            const dataURL = canvas.toDataURL();
            this.createDraggableImage(dataURL, container, zoneNumber, `Zone${zoneNumber}_Image${i}`);
        }
    }

    createDraggableImage(src, container, zoneNumber, altText = '', connectorColor = '#27ae60') {
        const img = document.createElement('img');
        // Si c'est une data URL, l'utiliser directement, sinon passer par assetUrl
        img.src = src.startsWith('data:') ? src : assetUrl(src);
        img.alt = altText || `Image Zone ${zoneNumber}`;
        img.className = 'draggable-image';
        img.draggable = true;

        img.dataset.sourcePath = src;
        
        // Stocker les informations de la zone d'origine
        img.dataset.originalZone = zoneNumber;
        img.dataset.imageId = `img_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        img.dataset.isOriginal = 'true'; // Marquer comme image originale
        img.dataset.connectorColor = connectorColor; // Stocker la couleur du connecteur
        
        // Attendre le chargement de l'image pour stocker ses dimensions naturelles
        img.addEventListener('load', () => {
            img.dataset.naturalWidth = img.naturalWidth;
            img.dataset.naturalHeight = img.naturalHeight;
        });
        
        container.appendChild(img);
        this.images.push(img);
        
        this.setupImageEventListeners(img);
    }
    
    duplicateImage(originalImg) {
        // Créer une copie de l'image
        const img = document.createElement('img');
        img.src = originalImg.src;
        img.alt = originalImg.alt;
        img.className = 'draggable-image';
        img.draggable = true;
        
        // Copier les données importantes
        img.dataset.originalZone = originalImg.dataset.originalZone;
        img.dataset.imageId = `img_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        img.dataset.naturalWidth = originalImg.dataset.naturalWidth;
        img.dataset.naturalHeight = originalImg.dataset.naturalHeight;
        img.dataset.isOriginal = 'false'; // Marquer comme copie
        img.dataset.connectorColor = originalImg.dataset.connectorColor || '#27ae60'; // Copier la couleur du connecteur
        img.dataset.sourcePath = originalImg.dataset.sourcePath;
        
        // Ajouter à la liste et configurer les événements
        this.images.push(img);
        this.setupImageEventListeners(img);
        
        console.log('📋 Image dupliquée');
        return img;
    }

    setupImageEventListeners(img) {
        // Événements de drag
        img.addEventListener('dragstart', (e) => this.handleDragStart(e));
        img.addEventListener('dragend', (e) => this.handleDragEnd(e));
        
        // Événements de souris pour le drag personnalisé
        img.addEventListener('mousedown', (e) => this.handleMouseDown(e));
        
        // Événements tactiles pour écrans tactiles
        img.addEventListener('touchstart', (e) => this.handleTouchStart(e), { passive: false });
        img.addEventListener('touchmove', (e) => this.handleTouchMove(e), { passive: false });
        img.addEventListener('touchend', (e) => this.handleTouchEnd(e), { passive: false });
        
        // Événement de clic pour le mode retournement
        img.addEventListener('click', (e) => this.handleImageClick(e));
    }

    setupEventListeners() {
        // Événements pour la zone de fond
        this.backgroundArea.addEventListener('dragover', (e) => this.handleDragOver(e));
        this.backgroundArea.addEventListener('drop', (e) => this.handleDrop(e));
        
        // Événements pour toutes les zones en bas
        document.querySelectorAll('.zone').forEach((zone, index) => {
            zone.addEventListener('dragover', (e) => this.handleZoneDragOver(e));
            zone.addEventListener('drop', (e) => this.handleZoneDrop(e));
            zone.addEventListener('dragleave', (e) => this.handleZoneDragLeave(e));
        });
        
        // Événements pour les zone-images également
        document.querySelectorAll('.zone-images').forEach((zoneImages) => {
            zoneImages.addEventListener('dragover', (e) => {
                e.preventDefault();
                e.stopPropagation();
                e.dataTransfer.dropEffect = 'move';
            });
            zoneImages.addEventListener('drop', (e) => {
                e.preventDefault();
                e.stopPropagation();
                if (this.draggedElement) {
                    this.moveImageToZone(this.draggedElement, zoneImages);
                }
            });
        });
        
        // Bouton reset
        this.resetBtn.addEventListener('click', () => {
            window.location.reload();
        });
        
        // Bouton reset connecteur
        this.resetConnecteurBtn.addEventListener('click', () => {
            if (window.businessLogicManager) {
                window.businessLogicManager.resetConnecteurs();
            }
        });
        
        // Bouton mode retournement horizontal - souris ET tactile
        const toggleFlipH = (e) => {
            e.preventDefault();
            this.flipMode = !this.flipMode;
            if (this.flipMode) {
                this.flipModeBtn.classList.add('active');
                this.flipModeHautBas = false;
                this.flipModeBtnHautBas.classList.remove('active');
            } else {
                this.flipModeBtn.classList.remove('active');
            }
            e.stopPropagation();
        };
        this.flipModeBtn.addEventListener('click', toggleFlipH);
        this.flipModeBtn.addEventListener('touchstart', toggleFlipH, { passive: false });
        
        // Bouton mode retournement vertical - souris ET tactile
        const toggleFlipV = (e) => {
            e.preventDefault();
            this.flipModeHautBas = !this.flipModeHautBas;
            if (this.flipModeHautBas) {
                this.flipModeBtnHautBas.classList.add('active');
                this.flipMode = false;
                this.flipModeBtn.classList.remove('active');
            } else {
                this.flipModeBtnHautBas.classList.remove('active');
            }
            e.stopPropagation();
        };
        this.flipModeBtnHautBas.addEventListener('click', toggleFlipV);
        this.flipModeBtnHautBas.addEventListener('touchstart', toggleFlipV, { passive: false });
        
        // Désactiver les modes retournement si on clique/touche ailleurs que sur une image
        const deactivateFlipModes = (e) => {
            const isImage = e.target.classList.contains('draggable-image');
            const isFlipButton = e.target.closest('#flipModeBtn') || e.target.closest('#flipModeBtnHautBas');
            if (!isImage && !isFlipButton) {
                this.flipMode = false;
                this.flipModeBtn.classList.remove('active');
                this.flipModeHautBas = false;
                this.flipModeBtnHautBas.classList.remove('active');
            }
        };
        document.addEventListener('click', (e) => {
            if (!this.flipMode && !this.flipModeHautBas) return;
            deactivateFlipModes(e);
        });
        document.addEventListener('touchstart', (e) => {
            if (!this.flipMode && !this.flipModeHautBas) return;
            deactivateFlipModes(e);
        }, { passive: true });
        

        
        // Événements globaux pour le drag à la souris
        document.addEventListener('mousemove', (e) => this.handleMouseMove(e));
        document.addEventListener('mouseup', (e) => this.handleMouseUp(e));
        
        // Sécurité : réinitialiser le drag si la souris quitte la fenêtre
        document.addEventListener('mouseleave', (e) => {
            if (this.isDragging && this.draggedElement) {
                this.draggedElement.classList.remove('dragging');
                this.draggedElement.style.pointerEvents = 'auto';
                this.draggedElement.draggable = true; // Réactiver le drag natif
                this.isDragging = false;
                this.hasStartedMoving = false;
                this.draggedElement = null;
            }
        });
        
        // Plus besoin de touche Échap pour les modes
        
        // Recalculer le ratio lors du redimensionnement de la fenêtre
        window.addEventListener('resize', () => {
            this.calculateBackgroundScale();
            this.updateAllImagesScale();
        });
    }

    updateAllImagesScale() {
        // Mettre à jour la taille de toutes les images déjà placées sur le fond
        const imagesOnBackground = this.backgroundArea.querySelectorAll('.draggable-image');
        imagesOnBackground.forEach(img => {
            const naturalWidth = parseFloat(img.dataset.naturalWidth) || img.naturalWidth;
            const naturalHeight = parseFloat(img.dataset.naturalHeight) || img.naturalHeight;
            
            const scaledWidth = naturalWidth * this.backgroundScale;
            const scaledHeight = naturalHeight * this.backgroundScale;
            
            img.style.width = scaledWidth + 'px';
            img.style.height = scaledHeight + 'px';
        });
    }

    handleDragStart(e) {
        this.draggedElement = e.target;
        this.originalParent = e.target.parentNode;
        
        if (e.target.parentNode.classList.contains('zone-images')) {
            // L'image vient d'une zone, stocker sa position relative
            this.originalPosition = { x: 0, y: 0 };
        } else {
            // L'image est dans la zone de fond, stocker sa position absolue
            this.originalPosition = {
                x: parseInt(e.target.style.left) || 0,
                y: parseInt(e.target.style.top) || 0
            };
        }
        
        e.target.classList.add('dragging');
        e.dataTransfer.effectAllowed = 'move';
    }

    handleDragEnd(e) {
        e.target.classList.remove('dragging');
        
        // Vérifier si l'image zone2 doit être attachée à une image zone1
        if (e.target.dataset.originalZone === '2' && e.target.parentNode === this.backgroundArea) {
            this.checkAndAttachToImage(e.target);
        }
        
        this.draggedElement = null;
        this.originalParent = null;
    }

    handleDragOver(e) {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
    }

    handleDrop(e) {
        e.preventDefault();
        
        if (!this.draggedElement) return;
        
        // Calculer les dimensions mises à l'échelle de l'image
        const naturalWidth = parseFloat(this.draggedElement.dataset.naturalWidth) || this.draggedElement.naturalWidth;
        const naturalHeight = parseFloat(this.draggedElement.dataset.naturalHeight) || this.draggedElement.naturalHeight;
        const scaledWidth = naturalWidth * this.backgroundScale;
        const scaledHeight = naturalHeight * this.backgroundScale;
        
        // Calculer la position relative à la zone de fond
        const rect = this.backgroundArea.getBoundingClientRect();
        const x = e.clientX - rect.left - (scaledWidth / 2); // Centrer l'image
        const y = e.clientY - rect.top - (scaledHeight / 2);
        
        // S'assurer que l'image reste dans les limites
        const maxX = rect.width - scaledWidth;
        const maxY = rect.height - scaledHeight;
        
        const finalX = Math.max(0, Math.min(x, maxX));
        const finalY = Math.max(0, Math.min(y, maxY));
        
        // Vérifier si l'image vient d'une zone (nouveau placement)
        const isNewPlacement = this.draggedElement.parentNode.classList.contains('zone-images');
        const isFromZone2 = this.draggedElement.dataset.originalZone === '2';
        
        if (isNewPlacement) {
            if (isFromZone2) {
                const sourcePath = this.draggedElement.dataset.sourcePath || '';
                const match = sourcePath.match(/ImagesZ2\/image\((1|2)\)\.png$/);
                if (match) {
                    const id = match[1];

                    // image(n) à l'endroit du drop
                    const droppedImg = this.duplicateImage(this.draggedElement);
                    this.moveImageToBackground(droppedImg, finalX, finalY);

                    // image(nbis) centrée en haut
                    const bisImg = document.createElement('img');
                    bisImg.src = assetUrl(`ImagesZ2/image(${id}bis).png`);
                    bisImg.alt = this.draggedElement.alt;
                    bisImg.className = 'draggable-image';
                    bisImg.draggable = true;
                    bisImg.dataset.originalZone = this.draggedElement.dataset.originalZone;
                    bisImg.dataset.imageId = `img_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
                    bisImg.dataset.isOriginal = 'false';
                    bisImg.dataset.connectorColor = this.draggedElement.dataset.connectorColor || '#27ae60';
                    bisImg.dataset.sourcePath = `ImagesZ2/image(${id}bis).png`;
                    bisImg.dataset.naturalWidth = this.draggedElement.dataset.naturalWidth;
                    bisImg.dataset.naturalHeight = this.draggedElement.dataset.naturalHeight;

                    this.images.push(bisImg);
                    this.setupImageEventListeners(bisImg);

                    const bgRect = this.backgroundArea.getBoundingClientRect();
                    const naturalWidthBis = parseFloat(bisImg.dataset.naturalWidth) || 100;
                    const scaledWidthBis = naturalWidthBis * this.backgroundScale;
                    const xCopy = (bgRect.width / 2) - (scaledWidthBis / 2);
                    const yCopy = 70;
                    this.moveImageToBackground(bisImg, xCopy, yCopy);

                    console.log('[VAT DROP]', {
                        drop: {left: finalX, top: finalY, el: droppedImg},
                        copie: {left: xCopy, top: yCopy, el: bisImg}
                    });
                    this.createConnectorBetweenImages(droppedImg, bisImg);
                } else {
                    // fallback: comportement historique (2 duplications)
                    const droppedImg = this.duplicateImage(this.draggedElement);
                    this.moveImageToBackground(droppedImg, finalX, finalY);
                    const duplicatedImg = this.duplicateImage(this.draggedElement);
                    const bgRect = this.backgroundArea.getBoundingClientRect();
                    const xCopy = (bgRect.width / 2) - (duplicatedImg.offsetWidth / 2 || 50);
                    const yCopy = 70;
                    this.moveImageToBackground(duplicatedImg, xCopy, yCopy);
                    this.createConnectorBetweenImages(droppedImg, duplicatedImg);
                }
            } else {
                // Cas classique autres images (zones 1 et 3) :
                // dupliquer l'image et placer la copie sur le fond
                const droppedImg = this.duplicateImage(this.draggedElement);
                this.moveImageToBackground(droppedImg, finalX, finalY);
            }
        }
       
    };

    handleZoneDragOver(e) {
        e.preventDefault();
        e.stopPropagation();
        e.currentTarget.classList.add('drag-over');
        e.dataTransfer.dropEffect = 'move';
    }

    handleZoneDragLeave(e) {
        e.currentTarget.classList.remove('drag-over');
    }

    handleZoneDrop(e) {
        e.preventDefault();
        e.stopPropagation();
        e.currentTarget.classList.remove('drag-over');
        
        if (!this.draggedElement) return;
        
        const zoneImages = e.currentTarget.querySelector('.zone-images');
        this.moveImageToZone(this.draggedElement, zoneImages);
    }

    // Gestion du clic/toucher sur une image pour retournement
    handleImageClick(e) {
        if (!this.flipMode && !this.flipModeHautBas) return;
        
        const img = e.target;
        const isZone1 = img.dataset.originalZone === '1';
        const parent = img.parentNode;
        const isOnBackground = parent.classList.contains('background-area') || 
                               parent.classList.contains('connecteur-multiple-container');
        
        if (!isZone1 || !isOnBackground) return;
        
        if (this.flipMode) {
            const currentFlip = img.dataset.flipped === 'true';
            if (currentFlip) {
                img.style.transform = img.dataset.originalTransform || 'none';
                img.dataset.flipped = 'false';
            } else {
                const originalTransform = img.style.transform || 'none';
                img.dataset.originalTransform = originalTransform;
                if (originalTransform === 'none' || originalTransform === '') {
                    img.style.transform = 'scaleX(-1)';
                } else {
                    img.style.transform = originalTransform + ' scaleX(-1)';
                }
                img.dataset.flipped = 'true';
            }
        } else if (this.flipModeHautBas) {
            const currentFlipV = img.dataset.flippedV === 'true';
            if (currentFlipV) {
                img.style.transform = img.dataset.originalTransformV || 'none';
                img.dataset.flippedV = 'false';
            } else {
                const originalTransform = img.style.transform || 'none';
                img.dataset.originalTransformV = originalTransform;
                if (originalTransform === 'none' || originalTransform === '') {
                    img.style.transform = 'scaleY(-1)';
                } else {
                    img.style.transform = originalTransform + ' scaleY(-1)';
                }
                img.dataset.flippedV = 'true';
            }
        }
        
        e.stopPropagation();
    }

    handleMouseDown(e) {
        console.log('🖱️ MOUSEDOWN détecté', e.button);
        if (e.button !== 0) return; // Seulement le clic gauche
        
        // Seulement si l'image est déjà sur le fond ou dans un connecteur multiple
        const parent = e.target.parentNode;
        const isOnBackground = parent.classList.contains('background-area') || 
                               parent.classList.contains('connecteur-multiple-container');
        console.log('📍 Image sur fond ?', isOnBackground, 'Parent:', parent.className);
        if (!isOnBackground) return;
        
        this.draggedElement = e.target;
        this.originalParent = e.target.parentNode;
        this.originalPosition = {
            x: parseInt(e.target.style.left) || 0,
            y: parseInt(e.target.style.top) || 0
        };
        
        this.isDragging = true;
        this.hasStartedMoving = false; // Flag pour savoir si on a commencé à bouger
        this.dragOffset = {
            x: e.clientX - parseInt(e.target.style.left || 0),
            y: e.clientY - parseInt(e.target.style.top || 0)
        };
        
        console.log('✅ DRAG ACTIVÉ - isDragging:', this.isDragging, 'Offset:', this.dragOffset);
        
        e.target.classList.add('dragging');
        // S'assurer que pointer-events est activé au début
        e.target.style.pointerEvents = 'auto';
        
        // IMPORTANT : Désactiver le drag natif pendant qu'on utilise le drag souris
        e.target.draggable = false;
        
        e.preventDefault();
        e.stopPropagation();
    }

    handleMouseMove(e) {
        if (!this.isDragging || !this.draggedElement) {
            if (this.isDragging) console.log('⚠️ MOUSEMOVE: isDragging=true mais pas de draggedElement');
            return;
        }
        
        // Marquer qu'on a commencé à bouger et désactiver pointer-events
        if (!this.hasStartedMoving) {
            console.log('🚀 PREMIER MOUVEMENT détecté');
            this.hasStartedMoving = true;
            this.draggedElement.style.pointerEvents = 'none';
        }
        
        const rect = this.backgroundArea.getBoundingClientRect();
        const x = e.clientX - this.dragOffset.x;
        const y = e.clientY - this.dragOffset.y;
        
        // Obtenir les dimensions actuelles de l'image
        const imgWidth = this.draggedElement.offsetWidth;
        const imgHeight = this.draggedElement.offsetHeight;
        
        // Limiter aux bordures de la zone de fond
        const maxX = rect.width - imgWidth;
        const maxY = rect.height - imgHeight;
        
        const finalX = Math.max(0, Math.min(x, maxX));
        const finalY = Math.max(0, Math.min(y, maxY));
        
        console.log('📍 MOVE: Position calculée:', finalX.toFixed(0), finalY.toFixed(0));
        
        this.draggedElement.style.left = finalX + 'px';
        this.draggedElement.style.top = finalY + 'px';
        
        // Déplacer les images enfants attachées à cette image
        this.moveAttachedChildren(this.draggedElement);
        
        // NOUVEAU : Détecter les points d'accroche si c'est un VAT (zone 2)
        const isVat = this.draggedElement.getAttribute('data-original-zone') === '2';
        if (isVat && window.businessLogicManager) {
            this.detectNearbyAttachPoint(this.draggedElement, finalX, finalY);
        }
        
        // Mettre à jour les connecteurs liés à cette image
        this.updateAllConnectors();
    }

    handleMouseUp(e) {
        console.log('🖱️ MOUSEUP détecté - isDragging:', this.isDragging);
        if (!this.isDragging) return;
        
        this.isDragging = false;
        this.hasStartedMoving = false; // Réinitialiser le flag
        
        if (this.draggedElement) {
            // NOUVEAU : Si c'est un VAT et qu'il y a un point d'accroche proche, accrocher
            const isVat = this.draggedElement.getAttribute('data-original-zone') === '2';
            if (isVat && this.nearbyAttachPoint) {
                this.attachVatToConnector(this.draggedElement, this.nearbyAttachPoint);
                this.nearbyAttachPoint = null;
            }
            
            // Vérifier si l'image zone2 est déposée sur une image zone1
            if (this.draggedElement.dataset.originalZone === '2') {
                this.checkAndAttachToImage(this.draggedElement);
            }
            
            // Nettoyer la bordure rouge
            if (this.draggedElement.style.border) {
                this.draggedElement.style.border = '';
            }
            
            this.draggedElement.classList.remove('dragging');
            // Réactiver pointer-events
            this.draggedElement.style.pointerEvents = 'auto';
            // Réactiver le drag natif
            this.draggedElement.draggable = true;
            console.log('✅ DRAG TERMINÉ - pointer-events et draggable réactivés');
            
            // Vérifier si la souris est au-dessus d'une zone
            const elementAtPoint = document.elementFromPoint(e.clientX, e.clientY);
            const zone = elementAtPoint?.closest('.zone');
            
            if (zone) {
                console.log('📦 Image déposée dans une zone');
                // Trouver le conteneur zone-images de cette zone
                const zoneImages = zone.querySelector('.zone-images');
                if (zoneImages) {
                    // Déposer l'image dans la zone
                    this.moveImageToZone(this.draggedElement, zoneImages);
                }
            }
        }
        this.draggedElement = null;
    }
    
    // ========== GESTION DU TACTILE ==========
    
    handleTouchStart(e) {
        const img = e.target;
        const touch = e.touches[0];
        this.touchStartPos = { x: touch.clientX, y: touch.clientY };
        
        // Si l'image est dans une zone, préparer pour le drag vers le fond
        if (img.parentNode.classList.contains('zone-images')) {
            this.draggedElement = img;
            this.originalParent = img.parentNode;
            this.isTouchDragging = true;
            
            const rect = img.getBoundingClientRect();
            this.touchOffset = {
                x: touch.clientX - rect.left,
                y: touch.clientY - rect.top
            };
            
            img.classList.add('dragging');
            e.preventDefault();
        }
        // Si l'image est déjà sur le fond
        else if (img.parentNode.classList.contains('background-area') || img.parentNode.classList.contains('connecteur-multiple-container')) {
            this.draggedElement = img;
            this.originalParent = img.parentNode;
            this.isTouchDragging = true;
            
            const touch = e.touches[0];
            this.touchOffset = {
                x: touch.clientX - parseInt(img.style.left || 0),
                y: touch.clientY - parseInt(img.style.top || 0)
            };
            
            img.classList.add('dragging');
            img.style.pointerEvents = 'none';
            e.preventDefault();
        }
    }
    
    handleTouchMove(e) {
        if (!this.isTouchDragging || !this.draggedElement) return;
        
        const touch = e.touches[0];
        const img = this.draggedElement;
        
        // Si l'image vient d'une zone et n'est pas encore sur le fond
        if (this.originalParent.classList.contains('zone-images') && img.parentNode.classList.contains('zone-images')) {
            // Ne rien faire pendant le mouvement, on attend le touchEnd pour dupliquer
            // Juste afficher un feedback visuel si nécessaire
        }
        // Si l'image est déjà sur le fond, la déplacer
        else if (img.parentNode.classList.contains('background-area') || img.parentNode.classList.contains('connecteur-multiple-container')) {
            const bgRect = this.backgroundArea.getBoundingClientRect();
            const x = touch.clientX - this.touchOffset.x;
            const y = touch.clientY - this.touchOffset.y;
            
            const imgWidth = img.offsetWidth;
            const imgHeight = img.offsetHeight;
            
            const maxX = bgRect.width - imgWidth;
            const maxY = bgRect.height - imgHeight;
            
            const finalX = Math.max(0, Math.min(x, maxX));
            const finalY = Math.max(0, Math.min(y, maxY));
            
            img.style.left = finalX + 'px';
            img.style.top = finalY + 'px';
            
            // Déplacer les images enfants attachées à cette image
            this.moveAttachedChildren(img);
            
            // Si c'est un VAT (zone 2), détecter les points d'accroche comme à la souris
            const isVat = img.getAttribute('data-original-zone') === '2';
            if (isVat && window.businessLogicManager) {
                this.detectNearbyAttachPoint(img, finalX, finalY);
            }
            
            // Mettre à jour les connecteurs
            this.updateAllConnectors();
        }
        
        e.preventDefault();
    }
    
    handleTouchEnd(e) {
        // Détecter un tap pour le mode retournement
        if (this.isTouchDragging && (this.flipMode || this.flipModeHautBas)) {
            const touch = e.changedTouches[0];
            const dx = Math.abs(touch.clientX - (this.touchStartPos?.x || 0));
            const dy = Math.abs(touch.clientY - (this.touchStartPos?.y || 0));
            if (dx < 10 && dy < 10) {
                this.handleImageClick(e);
            }
        }
        
        if (!this.isTouchDragging) return;
        
        this.isTouchDragging = false;
        
        if (this.draggedElement) {
            const touch = e.changedTouches[0];
            const img = this.draggedElement;
            
            // Si l'image vient d'une zone et n'a pas encore été placée sur le fond
            if (this.originalParent.classList.contains('zone-images') && img.parentNode.classList.contains('zone-images')) {
                // Calculer les dimensions mises à l'échelle
                const naturalWidth = parseFloat(img.dataset.naturalWidth) || img.naturalWidth;
                const naturalHeight = parseFloat(img.dataset.naturalHeight) || img.naturalHeight;
                const scaledWidth = naturalWidth * this.backgroundScale;
                const scaledHeight = naturalHeight * this.backgroundScale;
                
                // Calculer la position relative à la zone de fond
                const bgRect = this.backgroundArea.getBoundingClientRect();
                const x = touch.clientX - bgRect.left - (scaledWidth / 2);
                const y = touch.clientY - bgRect.top - (scaledHeight / 2);
                
                // Limiter aux bordures
                const maxX = bgRect.width - scaledWidth;
                const maxY = bgRect.height - scaledHeight;
                const finalX = Math.max(0, Math.min(x, maxX));
                const finalY = Math.max(0, Math.min(y, maxY));
                
                // Vérifier si le doigt est au-dessus d'une zone de retour
                const elementAtPoint = document.elementFromPoint(touch.clientX, touch.clientY);
                const zone = elementAtPoint?.closest('.zone');
                
                if (zone) {
                    // Ne rien faire, l'image reste dans sa zone d'origine
                    console.log('📦 Image reste dans la zone');
                } else {
                    // DUPLIQUER l'image et la placer sur le fond
                    const isFromZone2 = img.dataset.originalZone === '2';
                    const duplicatedImg = this.duplicateImage(img);
                    this.moveImageToBackground(duplicatedImg, finalX, finalY);
                    
                    // Si c'est une image de Zone 2, créer la paire connectée
                    if (isFromZone2) {
                        this.createConnectedPair(duplicatedImg, finalX, finalY);
                    }
                    
                    console.log('✅ Image dupliquée et placée sur le fond');
                }
            } else if (img.parentNode === this.backgroundArea || img.parentNode?.classList?.contains('connecteur-multiple-container')) {
                // L'image est déjà sur le fond
                // Vérifier si le doigt est au-dessus d'une zone de retour
                const elementAtPoint = document.elementFromPoint(touch.clientX, touch.clientY);
                const zone = elementAtPoint?.closest('.zone');
                
                if (zone) {
                    // Trouver le conteneur zone-images de cette zone
                    const zoneImages = zone.querySelector('.zone-images');
                    if (zoneImages) {
                        // Déposer l'image dans la zone (suppression)
                        this.moveImageToZone(img, zoneImages);
                    }
                } else {
                    // Si c'est un VAT et qu'il y a un point d'accroche proche, accrocher au connecteur
                    const isVat = img.getAttribute('data-original-zone') === '2';
                    if (isVat && this.nearbyAttachPoint) {
                        this.attachVatToConnector(img, this.nearbyAttachPoint);
                        this.nearbyAttachPoint = null;
                        img.style.border = '';
                    }
                    // Vérifier si l'image zone2 doit être attachée à une image zone1
                    if (img.dataset.originalZone === '2') {
                        this.checkAndAttachToImage(img);
                    }
                }
            }
            
            this.draggedElement.classList.remove('dragging');
            this.draggedElement.style.pointerEvents = '';
        }
        
        // Sécurité tactile : s'assurer que toutes les images du fond restent interactives
        if (this.backgroundArea) {
            const imgs = this.backgroundArea.querySelectorAll('.draggable-image');
            imgs.forEach(img => {
                img.style.pointerEvents = 'auto';
            });
        }

        this.draggedElement = null;
        e.preventDefault();
    }

    moveImageToBackground(img, x, y) {
        // Retirer l'image de son parent actuel
        if (img.parentNode) {
            img.parentNode.removeChild(img);
        }
        
        // Calculer la taille de l'image en fonction du ratio de l'image de fond
        const naturalWidth = parseFloat(img.dataset.naturalWidth) || img.naturalWidth;
        const naturalHeight = parseFloat(img.dataset.naturalHeight) || img.naturalHeight;
        
        let scaledWidth = naturalWidth * this.backgroundScale;
        let scaledHeight = naturalHeight * this.backgroundScale;
        
        // Obtenir la largeur disponible de la zone de fond
        const bgRect = this.backgroundArea.getBoundingClientRect();
        const maxWidth = bgRect.width;
        const maxHeight = bgRect.height;
        
        // Vérifier si l'image dépasse la largeur ou la hauteur de l'écran
        let reductionApplied = false;
        if (scaledWidth > maxWidth || scaledHeight > maxHeight) {
            // Calculer le ratio de réduction nécessaire
            const widthRatio = maxWidth / scaledWidth;
            const heightRatio = maxHeight / scaledHeight;
            
            // Prendre le plus petit ratio pour que l'image rentre complètement
            const reductionRatio = Math.min(widthRatio, heightRatio) * 0.95; // 95% pour une marge
            
            scaledWidth *= reductionRatio;
            scaledHeight *= reductionRatio;
            reductionApplied = true;
            
            console.log(`📏 Image réduite de ${(reductionRatio * 100).toFixed(1)}% pour rentrer dans l'écran`);
        }
        
        // Ajouter à la zone de fond avec position absolue et taille mise à l'échelle
        img.style.position = 'absolute';
        img.style.left = x + 'px';
        img.style.top = y + 'px';
        img.style.width = scaledWidth + 'px';
        img.style.height = scaledHeight + 'px';
        img.style.zIndex = '10';
        if (img.dataset.originalZone === '2') {
            // Zone 2 : toujours au-dessus de tout
            img.style.zIndex = '20';
        } else if (img.dataset.originalZone === '1') {
            // Zone 1 : en dessous des connecteurs (zIndex 6)
            img.style.zIndex = '5';
        }
        img.style.pointerEvents = 'auto'; // S'assurer que l'image est interactive
        
        if (reductionApplied) {
            console.log(`🖼️ Image placée avec ratio ${this.backgroundScale.toFixed(4)} + réduction: ${scaledWidth.toFixed(0)}x${scaledHeight.toFixed(0)}px`);
        } else {
            console.log(`🖼️ Image placée avec ratio ${this.backgroundScale.toFixed(4)}: ${scaledWidth.toFixed(0)}x${scaledHeight.toFixed(0)}px`);
        }
        
        this.backgroundArea.appendChild(img);
    }
    
    createConnectedPair(img1, x, y) {
        // Calculer 20vh en pixels
        const viewportHeight = window.innerHeight;
        const offsetY = viewportHeight * 0.20; // 20vh
        
        // Créer une copie de l'image
        const img2 = document.createElement('img');
        img2.src = img1.src;
        img2.alt = img1.alt;
        img2.className = 'draggable-image';
        img2.draggable = true;
        
        // Copier les données
        img2.dataset.originalZone = img1.dataset.originalZone;
        img2.dataset.imageId = `img_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        img2.dataset.naturalWidth = img1.dataset.naturalWidth;
        img2.dataset.naturalHeight = img1.dataset.naturalHeight;
        
        // Calculer la position de la deuxième image (en dessous)
        const img1Height = parseFloat(img1.style.height) || img1.offsetHeight;
        const y2 = y + img1Height + offsetY;
        
        // Placer la deuxième image
        this.moveImageToBackground(img2, x, y2);
        
        // Ajouter l'image à la liste
        this.images.push(img2);
        this.setupImageEventListeners(img2);
        
        // Créer le connecteur entre les deux images
        this.createConnectorBetweenImages(img1, img2);
        
        console.log(`✅ Paire connectée créée avec offset de ${offsetY.toFixed(0)}px (20vh)`);
    }

    moveImageToZone(img, zoneContainer) {
        // Supprimer tous les connecteurs liés à cette image
        const connectorsToDelete = this.connectors.filter(connector => 
            connector.img1 === img || connector.img2 === img
        );
        connectorsToDelete.forEach(connector => {
            this.deleteConnector(connector);
        });
        
        // Détacher l'image si elle est attachée à un parent
        this.detachImage(img);
        
        // Détacher tous les enfants attachés à cette image
        const childrenToDetach = [];
        this.attachments.forEach((attachment, childImg) => {
            if (attachment.parent === img) {
                childrenToDetach.push(childImg);
            }
        });
        childrenToDetach.forEach(childImg => {
            this.detachImage(childImg);
        });
        
        // Retirer l'image de la liste des images
        const index = this.images.indexOf(img);
        if (index > -1) {
            this.images.splice(index, 1);
        }
        
        // SUPPRIMER l'image au lieu de la remettre dans la zone
        if (img.parentNode) {
            img.parentNode.removeChild(img);
        }
        
        console.log('🗑️ Image supprimée (retour vers la zone)');
    }

    // ========== GESTION DES CONNECTEURS ENTRE IMAGES ==========
    
    createConnectorBetweenImages(img1, img2) {
        // Vérifier que les deux images existent
        if (!img1 || !img2) {
            console.error('❌ Erreur: Images invalides pour créer un connecteur');
            return;
        }
        
        try {
            // Créer un SVG pour le connecteur
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svg.setAttribute('class', 'connector-line');
            svg.style.position = 'absolute';
            svg.style.top = '0';
            svg.style.left = '0';
            svg.style.width = '100%';
            svg.style.height = '100%';
            svg.style.pointerEvents = 'none';
            svg.style.zIndex = '5';
            
            // Utiliser un path au lieu d'une line pour créer une courbe
            const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
            // Utiliser la couleur stockée dans l'image (zone 2)
            const connectorColor = img1.dataset.connectorColor || img2.dataset.connectorColor || '#27ae60';
            path.setAttribute('stroke', connectorColor);
            path.setAttribute('stroke-width', '3');
            path.setAttribute('fill', 'none');
            path.setAttribute('stroke-linecap', 'round');
            
            svg.appendChild(path);
            
            const connectorData = {
                element: svg,
                path: path,
                img1: img1,
                img2: img2,
                id: `connector_${Date.now()}`
            };
            
            this.connectors.push(connectorData);
            this.backgroundArea.appendChild(svg);
            
            // Mettre à jour la position du connecteur
            this.updateConnectorPosition(connectorData);
            
            console.log('✅ Connecteur créé entre deux images (avec effet de gravité)');
        } catch (error) {
            console.error('❌ Erreur lors de la création du connecteur:', error);
        }
    }
    
    updateConnectorPosition(connectorData) {
        const img1 = connectorData.img1;
        const img2 = connectorData.img2;
        
        // Calculer le centre de chaque image
        const rect1 = img1.getBoundingClientRect();
        const rect2 = img2.getBoundingClientRect();
        const bgRect = this.backgroundArea.getBoundingClientRect();
        
        const x1 = rect1.left + rect1.width / 2 - bgRect.left;
        const y1 = rect1.top + rect1.height / 2 - bgRect.top;
        const x2 = rect2.left + rect2.width / 2 - bgRect.left;
        const y2 = rect2.top + rect2.height / 2 - bgRect.top;
        
        // Calculer le point de contrôle pour la courbe (effet de gravité)
        const midX = (x1 + x2) / 2;
        const midY = (y1 + y2) / 2;
        
        // Calculer la distance entre les deux points
        const distance = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
        
        // Ajouter 20% de longueur vers le bas (effet de gravité)
        const sag = distance * 0.60;
        
        // Point de contrôle pour la courbe quadratique
        const controlX = midX;
        const controlY = midY + sag;
        
        // Créer un path au lieu d'une line pour avoir une courbe
        const pathData = `M ${x1} ${y1} Q ${controlX} ${controlY} ${x2} ${y2}`;
        connectorData.path.setAttribute('d', pathData);
    }


    // Détection et accrochage automatique du VAT aux connecteurs
    detectAndAttachVatToConnector(vatImg, x, y) {
        if (!window.businessLogicManager) return;
        
        const connecteurs = window.businessLogicManager.positionedImages.filter(svg => svg.__connecteurData);
        console.log('[VAT AUTO-ATTACH] Recherche de connecteurs proches...', connecteurs.length);
        
        const bgRect = this.backgroundArea.getBoundingClientRect();
        const vatCenter = {
            x: x + vatImg.offsetWidth / 2,
            y: y + vatImg.offsetHeight / 2
        };
        
        let bestMatch = null;
        let minDist = 200; // Distance maximale de détection (200px)
        
        for (const svg of connecteurs) {
            const connecteurData = svg.__connecteurData;
            const { x1Pixel, y1Pixel, x2Pixel, y2Pixel, pending } = connecteurData;
            
            // Approximer la courbe par segments
            for (let t = 0; t <= 1; t += 0.05) {
                const midX = (x1Pixel + x2Pixel) / 2;
                const midY = (y1Pixel + y2Pixel) / 2 + Math.abs(x2Pixel - x1Pixel) * (pending / 100);
                const px = (1 - t) * (1 - t) * x1Pixel + 2 * (1 - t) * t * midX + t * t * x2Pixel;
                const py = (1 - t) * (1 - t) * y1Pixel + 2 * (1 - t) * t * midY + t * t * y2Pixel;
                
                const dx = px - vatCenter.x;
                const dy = py - vatCenter.y;
                const dist = Math.sqrt(dx * dx + dy * dy);
                
                if (dist < minDist) {
                    minDist = dist;
                    bestMatch = {
                        svg,
                        connecteurData,
                        t,
                        x: px,
                        y: py,
                        dist
                    };
                }
            }
        }
        
        if (bestMatch) {
            console.log('[VAT AUTO-ATTACH] VAT accroché au connecteur!', {
                connecteur: bestMatch.connecteurData.name,
                distance: bestMatch.dist.toFixed(2),
                position: { x: bestMatch.x.toFixed(2), y: bestMatch.y.toFixed(2) }
            });
            
            // Stocker l'accrochage dans le connecteur
            bestMatch.connecteurData.vatAccroche = {
                img: vatImg,
                x: vatCenter.x,
                y: vatCenter.y,
                t: bestMatch.t
            };
            bestMatch.svg.__connecteurData = bestMatch.connecteurData;
            
            // Redessiner le connecteur avec le VAT
            window.businessLogicManager.redrawConnectorWithVat(bestMatch.connecteurData, bestMatch.svg);
        } else {
            console.log('[VAT AUTO-ATTACH] Aucun connecteur proche trouvé');
        }
    }

    // NOUVEAU : Détecter les points d'accroche proches pendant le drag du VAT
    detectNearbyAttachPoint(vatImg, x, y) {
        if (!window.businessLogicManager) return;
        
        const connecteurs = window.businessLogicManager.positionedImages.filter(svg => svg.__connecteurData);
        const bgRect = this.backgroundArea.getBoundingClientRect();
        const vatCenterX = x + vatImg.offsetWidth / 2;
        const vatCenterY = y + vatImg.offsetHeight / 2;
        
        let closestPoint = null;
        let minDist = 50; // Distance de détection (50px)
        
        for (const svg of connecteurs) {
            const connecteurData = svg.__connecteurData;
            if (!connecteurData.attachPoint) continue;
            
            const { x: pointX, y: pointY } = connecteurData.attachPoint;
            const dist = Math.sqrt(Math.pow(vatCenterX - pointX, 2) + Math.pow(vatCenterY - pointY, 2));
            
            if (dist < minDist) {
                minDist = dist;
                closestPoint = {
                    svg,
                    connecteurData,
                    dist
                };
            }
        }
        
        // Mettre à jour la bordure rouge
        if (closestPoint) {
            if (!this.nearbyAttachPoint || this.nearbyAttachPoint.svg !== closestPoint.svg) {
                vatImg.style.border = '3px solid red';
                this.nearbyAttachPoint = closestPoint;
                console.log('🎯 Point d\'accroche proche détecté!', closestPoint.connecteurData.name);
            }
        } else {
            if (this.nearbyAttachPoint) {
                vatImg.style.border = '';
                this.nearbyAttachPoint = null;
            }
        }
    }
    
    // NOUVEAU : Accrocher le VAT au connecteur
    attachVatToConnector(vatImg, attachPointData) {
        const { svg, connecteurData } = attachPointData;
        const bgRect = this.backgroundArea.getBoundingClientRect();
        const vatRect = vatImg.getBoundingClientRect();
        const vatCenterX = vatRect.left + vatRect.width / 2 - bgRect.left;
        const vatCenterY = vatRect.top + vatRect.height / 2 - bgRect.top;
        
        console.log('✅ VAT accroché au connecteur!', connecteurData.name);
        
        // Stocker l'accrochage
        connecteurData.vatAccroche = {
            img: vatImg,
            x: vatCenterX,
            y: vatCenterY
        };
        svg.__connecteurData = connecteurData;
        
        // Redessiner le connecteur avec le VAT
        window.businessLogicManager.redrawConnectorWithVat(connecteurData, svg);
    }

    updateAllConnectors() {
        // Mettre à jour tous les connecteurs après déplacement d'images
        this.connectors.forEach(connector => {
            if (connector.img1 && connector.img2) {
                this.updateConnectorPosition(connector);
            }
        });
        
        // Mettre à jour les connecteurs multiples si businessLogicManager existe
        if (window.businessLogicManager) {
            window.businessLogicManager.updateAllConnecteursMultiples();
        }
    }
    
    // ========== SYSTÈME D'ATTACHEMENT PARENT-ENFANT ==========
    
    checkAndAttachToImage(childImg) {
        // Vérifier si l'image zone2 est déposée sur une image zone1
        const childRect = childImg.getBoundingClientRect();
        const childCenterX = childRect.left + childRect.width / 2;
        const childCenterY = childRect.top + childRect.height / 2;
        
        // Parcourir toutes les images sur le fond (zone1 uniquement, pas les autres points du même connecteur)
        const imagesOnBackground = Array.from(this.backgroundArea.querySelectorAll('.draggable-image'))
            .filter(img => img !== childImg && 
                           img.dataset.originalZone === '1' && 
                           img.dataset.isConnecteurMultiplePoint !== 'true');
        
        for (const parentImg of imagesOnBackground) {
            const parentRect = parentImg.getBoundingClientRect();
            
            // Vérifier si le centre de l'image enfant est dans les limites de l'image parent
            if (childCenterX >= parentRect.left && childCenterX <= parentRect.right &&
                childCenterY >= parentRect.top && childCenterY <= parentRect.bottom) {
                
                // Calculer l'offset relatif
                const bgRect = this.backgroundArea.getBoundingClientRect();
                const childX = parseFloat(childImg.style.left) || 0;
                const childY = parseFloat(childImg.style.top) || 0;
                const parentX = parseFloat(parentImg.style.left) || 0;
                const parentY = parseFloat(parentImg.style.top) || 0;
                
                const offsetX = childX - parentX;
                const offsetY = childY - parentY;
                
                // Détacher l'ancienne relation si elle existe
                if (this.attachments.has(childImg)) {
                    const oldAttachment = this.attachments.get(childImg);
                    console.log(`🔓 Image zone2 détachée de l'ancienne image zone1`);
                }
                
                // Créer la nouvelle relation
                this.attachments.set(childImg, {
                    parent: parentImg,
                    offsetX: offsetX,
                    offsetY: offsetY
                });
                
                console.log(`🔗 Image zone2 attachée à image zone1 (offset: ${offsetX.toFixed(1)}, ${offsetY.toFixed(1)})`);
                return;
            }
        }
        
        // Si aucune image parent trouvée, détacher si nécessaire
        if (this.attachments.has(childImg)) {
            this.attachments.delete(childImg);
            console.log(`🔓 Image zone2 détachée (aucune image zone1 sous elle)`);
        }
    }
    
    moveAttachedChildren(parentImg) {
        // Déplacer toutes les images enfants attachées à cette image parent
        const parentX = parseFloat(parentImg.style.left) || 0;
        const parentY = parseFloat(parentImg.style.top) || 0;
        
        let hasMovedConnecteurMultiple = false;
        
        this.attachments.forEach((attachment, childImg) => {
            if (attachment.parent === parentImg) {
                const newX = parentX + attachment.offsetX;
                const newY = parentY + attachment.offsetY;
                
                childImg.style.left = newX + 'px';
                childImg.style.top = newY + 'px';
                
                // Vérifier si c'est une image de connecteur multiple
                if (childImg.dataset.isConnecteurMultiplePoint === 'true') {
                    hasMovedConnecteurMultiple = true;
                }
                
                // Mettre à jour récursivement les enfants de cet enfant (si applicable)
                this.moveAttachedChildren(childImg);
            }
        });
        
        // Mettre à jour les connecteurs multiples si nécessaire
        if (hasMovedConnecteurMultiple && window.businessLogicManager) {
            window.businessLogicManager.updateAllConnecteursMultiples();
        }
    }
    
    detachImage(childImg) {
        // Détacher une image de son parent
        if (this.attachments.has(childImg)) {
            this.attachments.delete(childImg);
            console.log(`🔓 Image détachée`);
        }
    }
    
     deleteConnector(connectorData) {
        // Retirer l'élément du DOM
        connectorData.element.remove();
        
        // Retirer du tableau
        const index = this.connectors.indexOf(connectorData);
        if (index > -1) {
            this.connectors.splice(index, 1);
        }
        
        console.log('🗑️ Connecteur supprimé');
    }



    

    
    previousBackground() {
        if (this.maxBackgroundIndex <= 1) return; // Pas de navigation si un seul fond
        
        this.currentBackgroundIndex--;
        if (this.currentBackgroundIndex < 1) {
            this.currentBackgroundIndex = this.maxBackgroundIndex; // Boucler vers le dernier
        }
        
        this.changeBackground();
    }
    
    nextBackground() {
        if (this.maxBackgroundIndex <= 1) return; // Pas de navigation si un seul fond
        
        this.currentBackgroundIndex++;
        if (this.currentBackgroundIndex > this.maxBackgroundIndex) {
            this.currentBackgroundIndex = 1; // Boucler vers le premier
        }
        
        this.changeBackground();
    }
    
    changeBackground() {
        const newSrc = assetUrl(`ImageFond/fond${this.currentBackgroundIndex}.jpg`);
        this.backgroundImage.src = newSrc;
        
        // Recalculer le ratio après le changement d'image
        this.backgroundImage.addEventListener('load', () => {
            this.calculateBackgroundScale();
            this.updateAllImagesScale();
            
            // Réinitialiser la logique métier si elle existe
            if (typeof businessLogicManager !== 'undefined' && businessLogicManager) {
                businessLogicManager.cleanup();
                businessLogicManager.currentBackgroundIndex = this.currentBackgroundIndex;
                businessLogicManager.init();
            }
        }, { once: true });
        
        console.log(`🖼️ Fond d'écran changé: fond${this.currentBackgroundIndex}.jpg`);
    }
}

// Initialiser l'application quand le DOM est chargé
document.addEventListener('DOMContentLoaded', () => {
    const manager = new DragDropManager();
    
    // Initialisation globale de businessLogicManager
    window.businessLogicManager = new BusinessLogicManager(manager);
    console.log('[DEBUG] businessLogicManager initialisé', window.businessLogicManager);
    
    // Initialiser la logique métier après un court délai pour s'assurer que tout est chargé
    setTimeout(() => {
        if (typeof initBusinessLogic === 'function') {
            initBusinessLogic(manager);
        }
    }, 500);
});

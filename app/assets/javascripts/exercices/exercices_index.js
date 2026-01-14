document.addEventListener('DOMContentLoaded', () => {
  const cardsGrid = document.getElementById('cardsGrid');
  if (!cardsGrid) return;

  let fonds;
  try {
    fonds = JSON.parse(cardsGrid.dataset.fonds || '[]');
  } catch (_e) {
    fonds = [];
  }

  fonds.forEach((fond) => {
    const card = document.createElement('a');
    card.href = fond.link_url;
    card.className = 'card';

    card.innerHTML = `
      <img src="${fond.image_url}" alt="${fond.nom}" class="card-image">
      <div class="card-content">
        <h3 class="card-title">${fond.nom}</h3>
        <p class="card-description">${fond.description}</p>
      </div>
    `;

    cardsGrid.appendChild(card);
  });
});

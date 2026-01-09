/**
 * disk2iso - Archive Page JavaScript
 */

function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('de-DE', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function createFileItem(file) {
    const div = document.createElement('div');
    div.className = 'archive-item';
    div.innerHTML = `
        <div class="archive-item-header">
            <span class="archive-filename">${escapeHtml(file.name)}</span>
            <span class="archive-size">${formatBytes(file.size)}</span>
        </div>
        <div class="archive-item-meta">
            <span>📅 ${formatDate(file.modified)}</span>
        </div>
    `;
    return div;
}

function loadArchive() {
    fetch('/api/archive')
        .then(response => response.json())
        .then(data => {
            // Update counts
            document.getElementById('total-count').textContent = data.total;
            document.getElementById('audio-count').textContent = data.by_type.audio.length;
            document.getElementById('dvd-count').textContent = data.by_type.dvd.length;
            document.getElementById('bluray-count').textContent = data.by_type.bluray.length;
            document.getElementById('data-count').textContent = data.by_type.data.length;

            // Populate Audio section
            const audioSection = document.getElementById('audio-section');
            const audioList = document.getElementById('audio-list');
            if (data.by_type.audio.length > 0) {
                audioSection.style.display = 'block';
                audioList.innerHTML = '';
                data.by_type.audio.forEach(file => {
                    audioList.appendChild(createFileItem(file));
                });
            } else {
                audioSection.style.display = 'none';
            }

            // Populate DVD section
            const dvdSection = document.getElementById('dvd-section');
            const dvdList = document.getElementById('dvd-list');
            if (data.by_type.dvd.length > 0) {
                dvdSection.style.display = 'block';
                dvdList.innerHTML = '';
                data.by_type.dvd.forEach(file => {
                    dvdList.appendChild(createFileItem(file));
                });
            } else {
                dvdSection.style.display = 'none';
            }

            // Populate Blu-ray section
            const bluraySection = document.getElementById('bluray-section');
            const blurayList = document.getElementById('bluray-list');
            if (data.by_type.bluray.length > 0) {
                bluraySection.style.display = 'block';
                blurayList.innerHTML = '';
                data.by_type.bluray.forEach(file => {
                    blurayList.appendChild(createFileItem(file));
                });
            } else {
                bluraySection.style.display = 'none';
            }

            // Populate Data section
            const dataSection = document.getElementById('data-section');
            const dataList = document.getElementById('data-list');
            if (data.by_type.data.length > 0) {
                dataSection.style.display = 'block';
                dataList.innerHTML = '';
                data.by_type.data.forEach(file => {
                    dataList.appendChild(createFileItem(file));
                });
            } else {
                dataSection.style.display = 'none';
            }
        })
        .catch(error => {
            console.error('Fehler beim Laden des Archivs:', error);
            ['audio', 'dvd', 'bluray', 'data'].forEach(type => {
                const list = document.getElementById(`${type}-list`);
                if (list) {
                    list.innerHTML = '<p class="error">Fehler beim Laden der Daten</p>';
                }
            });
        });
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Initialisierung beim Laden der Seite
document.addEventListener('DOMContentLoaded', function() {
    loadArchive();
    
    // Refresh every 60 seconds
    setInterval(loadArchive, 60000);
});

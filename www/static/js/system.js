/**
 * disk2iso - System Page JavaScript
 */

let isRefreshing = false;

function loadSystemInfo() {
    if (isRefreshing) return;
    
    fetch('/api/system')
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                displayOsInfo(data.os);
                displayDisk2IsoInfo(data.disk2iso);
                displaySoftwareVersions(data.software);
                checkForUpdates(data.software);
            } else {
                showError('Fehler beim Laden der Systeminformationen');
            }
        })
        .catch(error => {
            console.error('Fehler:', error);
            showError('Fehler beim Laden der Systeminformationen: ' + error);
        });
}

function displayOsInfo(os) {
    const container = document.getElementById('os-info');
    container.innerHTML = `
        <div class="info-item">
            <span class="info-label">Distribution</span>
            <span class="info-value">${os.distribution || 'Unbekannt'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Version</span>
            <span class="info-value">${os.version || 'Unbekannt'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Kernel</span>
            <span class="info-value">${os.kernel || 'Unbekannt'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Architektur</span>
            <span class="info-value">${os.architecture || 'Unbekannt'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Hostname</span>
            <span class="info-value">${os.hostname || 'Unbekannt'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Uptime</span>
            <span class="info-value">${os.uptime || 'Unbekannt'}</span>
        </div>
    `;
}

function displayDisk2IsoInfo(info) {
    const container = document.getElementById('disk2iso-info');
    const statusClass = info.service_status === 'active' ? 'status-ok' : 
                      info.service_status === 'inactive' ? 'status-warning' : 'status-error';
    
    container.innerHTML = `
        <div class="info-item">
            <span class="info-label">Version</span>
            <span class="info-value">${info.version || 'Unbekannt'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Service Status</span>
            <span class="info-value">
                <span class="status-indicator-small ${statusClass}"></span>
                ${info.service_status || 'Unbekannt'}
            </span>
        </div>
        <div class="info-item">
            <span class="info-label">Installationspfad</span>
            <span class="info-value">${info.install_path || '/opt/disk2iso'}</span>
        </div>
        <div class="info-item">
            <span class="info-label">Python Version</span>
            <span class="info-value">${info.python_version || 'Unbekannt'}</span>
        </div>
    `;
}

function displaySoftwareVersions(software) {
    const container = document.getElementById('software-container');
    
    // Gruppiere Software nach Kategorien
    const categories = {
        'Audio-CD Tools': software.filter(s => 
            ['cdparanoia', 'abcde', 'lame', 'flac', 'vorbis-tools'].includes(s.name)),
        'DVD/Blu-ray Tools': software.filter(s => 
            ['makemkv', 'dvdbackup', 'libbluray', 'handbrake'].includes(s.name)),
        'System Tools': software.filter(s => 
            ['ddrescue', 'gddrescue', 'wodim', 'genisoimage', 'isoinfo'].includes(s.name)),
        'Sonstige': software.filter(s => 
            !['cdparanoia', 'abcde', 'lame', 'flac', 'vorbis-tools',
              'makemkv', 'dvdbackup', 'libbluray', 'handbrake',
              'ddrescue', 'gddrescue', 'wodim', 'genisoimage', 'isoinfo'].includes(s.name))
    };
    
    let html = '';
    
    for (const [category, items] of Object.entries(categories)) {
        if (items.length === 0) continue;
        
        html += `
            <div class="software-category">
                <h3>${category}</h3>
                <table class="software-table">
                    <thead>
                        <tr>
                            <th>Software</th>
                            <th>Installiert</th>
                            <th>Verfügbar</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
        `;
        
        items.forEach(item => {
            const statusBadge = getStatusBadge(item);
            const availableVersion = item.available_version || 'Prüfung läuft...';
            
            html += `
                <tr>
                    <td><strong>${item.display_name || item.name}</strong></td>
                    <td>${item.installed_version || '<em>Nicht installiert</em>'}</td>
                    <td>${availableVersion}</td>
                    <td>${statusBadge}</td>
                </tr>
            `;
        });
        
        html += `
                    </tbody>
                </table>
            </div>
        `;
    }
    
    if (html === '') {
        html = '<p style="text-align: center; padding: 40px; color: #666;">Keine Software-Informationen verfügbar</p>';
    }
    
    container.innerHTML = html;
}

function getStatusBadge(item) {
    if (!item.installed_version) {
        return '<span class="version-badge version-error">❌ Nicht installiert</span>';
    }
    
    if (!item.available_version || item.available_version === 'Unbekannt') {
        return '<span class="version-badge version-unavailable">❓ Unbekannt</span>';
    }
    
    if (item.update_available) {
        return '<span class="version-badge version-outdated">⚠️ Update verfügbar</span>';
    }
    
    return '<span class="version-badge version-current">✅ Aktuell</span>';
}

function checkForUpdates(software) {
    const outdated = software.filter(s => s.update_available);
    const missing = software.filter(s => !s.installed_version);
    
    if (outdated.length === 0 && missing.length === 0) {
        document.getElementById('update-notice').style.display = 'none';
        return;
    }
    
    let message = '';
    
    if (outdated.length > 0) {
        message += `<strong>${outdated.length} Update(s) verfügbar:</strong><br>`;
        message += '<ul style="margin: 10px 0;">';
        outdated.forEach(s => {
            message += `<li><strong>${s.display_name || s.name}:</strong> ${s.installed_version} → ${s.available_version}</li>`;
        });
        message += '</ul>';
    }
    
    if (missing.length > 0) {
        message += `<strong>${missing.length} fehlende Software:</strong><br>`;
        message += '<ul style="margin: 10px 0;">';
        missing.forEach(s => {
            message += `<li>${s.display_name || s.name}</li>`;
        });
        message += '</ul>';
    }
    
    document.getElementById('update-message').innerHTML = message;
    document.getElementById('update-notice').style.display = 'block';
}

function refreshSystemInfo() {
    if (isRefreshing) return;
    
    isRefreshing = true;
    const refreshIcon = document.getElementById('refresh-icon');
    const container = document.getElementById('software-container');
    
    // Rotation animation
    refreshIcon.style.display = 'inline-block';
    refreshIcon.style.animation = 'spin 1s linear infinite';
    container.classList.add('loading');
    
    loadSystemInfo();
    
    // Reset nach 2 Sekunden
    setTimeout(() => {
        isRefreshing = false;
        refreshIcon.style.animation = '';
        container.classList.remove('loading');
    }, 2000);
}

function showError(message) {
    const container = document.getElementById('software-container');
    container.innerHTML = `
        <div style="background: #ffe3e3; border-left: 4px solid #c92a2a; padding: 20px; border-radius: 4px;">
            <strong>⚠️ Fehler</strong><br>
            ${message}
        </div>
    `;
}

// Initialisierung beim Laden der Seite
document.addEventListener('DOMContentLoaded', function() {
    loadSystemInfo();
});

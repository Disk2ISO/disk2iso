# Web Interface for disk2iso

## Overview

A simple web-based monitoring and file management interface for the disk2iso.sh script. The web interface provides a viewing layer on top of the existing bash script to monitor ripping progress and manage ISO files.

## Scope

This is a **simple monitoring tool** for a single-drive operation, not an enterprise job queue system. The web interface does NOT replace the disk2iso.sh script - it monitors what the script is doing and helps manage the resulting ISO files.

## Core Features

### 1. Current Operation Status
- Display what disk2iso.sh is currently doing
- Show progress of active rip operation (if any)
- Read status from log file or status file created by disk2iso.sh
- Simple text-based status display (no complex state machine)

### 2. Drive Status
- Current disc in drive (if any)
- Drive state: idle, ripping, ejecting, error
- Basic disc information (title, type if available from log)

### 3. ISO File Browser
- List ISO files in the configured output directory
- Display file information:
  - Filename
  - File size
  - Creation date
  - Associated metadata (if .nfo or .json file exists)

### 4. Basic File Operations
- **View**: Display file details and metadata
- **Download**: Download ISO file via HTTP
- **Delete**: Remove ISO file (with confirmation)
- **Rename**: Simple file renaming capability

### 5. Simple Log Viewer
- Display recent entries from disk2iso log file
- Basic tail/filter functionality
- Show last N lines or filter by date/keyword

## Technical Approach

### Backend
- **Lightweight web framework**: Flask (Python) or simple Node.js/Express
- **No database required**: Read directly from filesystem and log files
- **No job queue**: Simply monitor what disk2iso.sh is doing
- **No process management**: disk2iso.sh runs independently (systemd, cron, or manually)

### Frontend
- **Simple HTML/CSS/JavaScript**: No complex framework needed
- **Auto-refresh**: Poll backend every 5-10 seconds for status updates
- **Responsive design**: Mobile-friendly for monitoring on phone/tablet

### Integration with disk2iso.sh
The bash script should output status information that the web interface can read:

1. **Status file** (e.g., `/var/run/disk2iso.status`):
   ```json
   {
     "state": "ripping",
     "disc_title": "Movie Name",
     "progress_percent": 45,
     "current_file": "MOVIE_NAME.iso",
     "started_at": "2026-01-04T14:00:00Z"
   }
   ```

2. **Log file**: disk2iso.sh already creates logs - web interface just reads them

3. **Output directory**: web interface scans the ISO output directory

## File Structure

```
disk2iso-web/
├── server.py (or app.js)          # Simple web server
├── templates/
│   └── index.html                  # Single-page interface
├── static/
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── app.js                  # Auto-refresh and AJAX calls
└── config.py                       # Configuration (paths, etc.)
```

## Configuration

Simple configuration file pointing to:
- ISO output directory path
- Log file path
- Status file path
- Port to run web server on

## API Endpoints (RESTful)

```
GET  /api/status              # Current operation status
GET  /api/drive               # Drive status
GET  /api/files               # List ISO files
GET  /api/files/:filename     # Get file details
GET  /api/logs?lines=50       # Get recent log entries
POST /api/files/:filename/delete   # Delete file
POST /api/files/:filename/rename   # Rename file
GET  /download/:filename      # Download ISO file
```

## UI Layout (Single Page)

```
+----------------------------------+
| disk2iso Monitor                 |
+----------------------------------+
| Current Status:                  |
| [Ripping: Movie Name - 45%]      |
|                                  |
| Drive: /dev/sr0 - Disc present   |
+----------------------------------+
| ISO Files (5 total - 23.4 GB):   |
|                                  |
| [📀] Movie1.iso - 4.7GB          |
|      [View] [Download] [Delete]  |
| [📀] Movie2.iso - 8.2GB          |
|      [View] [Download] [Delete]  |
| ...                              |
+----------------------------------+
| Recent Log:                      |
| [2026-01-04 14:05:23] Started... |
| [2026-01-04 14:05:25] Detected.. |
| ...                              |
+----------------------------------+
```

## Implementation Priority

### Phase 1 (Minimal Viable Product)
1. Display current status from log file
2. List ISO files in directory
3. Basic download functionality
4. Log viewer

### Phase 2 (Nice to Have)
1. Delete functionality with confirmation
2. Better progress display
3. File metadata display
4. Rename functionality

### Phase 3 (Future Enhancement)
1. Mobile-optimized interface
2. Dark mode
3. Notifications (when rip completes)
4. Integration with media center (Plex/Jellyfin scan trigger)

## Security Considerations

- **Authentication**: Add basic auth if exposed beyond localhost
- **File access**: Restrict to configured ISO directory only
- **Delete confirmation**: Require confirmation before file deletion
- **Input validation**: Sanitize all file paths and user input
- **Read-only default**: Make destructive operations opt-in via config

## Non-Goals (Out of Scope)

❌ Multi-disc job queue management  
❌ Worker process orchestration  
❌ Complex database schemas  
❌ User management system  
❌ Automated ripping triggers  
❌ Direct drive control from web UI  
❌ Batch operations  
❌ Advanced scheduling  
❌ Distributed processing  

The web interface is strictly a **monitoring and viewing tool** for single-drive operations.

## Integration with Media Center

Simple post-processing triggers:
- After successful rip, optionally trigger Plex/Jellyfin library scan
- Simple webhook or API call (optional feature)
- Or just rely on automatic library scanning

## Development Notes

- Keep it simple - avoid over-engineering
- Prioritize reliability over features
- The bash script is the core - web UI is just a convenience layer
- Should work well on low-power devices (Raspberry Pi, etc.)

## Dependencies

Minimal dependencies:
- Python 3.7+ with Flask (or Node.js 14+ with Express)
- Standard filesystem access
- No database required
- No message queue required

## Estimated Effort

- Basic implementation: 1-2 days
- Testing and refinement: 1 day
- Documentation: 0.5 day

Total: ~3-4 days for a functional monitoring interface

# Web-First Architecture for disk2iso

## Overview

This document outlines the Web-First architecture for disk2iso, providing a modern web-based interface for disk imaging operations. The system is designed to run in an LXC container with a web interface as the primary interaction method, while maintaining minimal CLI support for advanced users.

## Architecture Principles

- **Web-First Design**: Primary interaction through a responsive web interface
- **Container-Based**: Runs in LXC containers for isolation and portability
- **RESTful API**: Clean API design for all operations
- **Progressive Enhancement**: Core functionality works without JavaScript, enhanced UX with it
- **Security-First**: Authentication, authorization, and audit logging built-in
- **Mobile-Friendly**: Responsive design for access from any device

## LXC Container Setup

### Container Requirements

```bash
# Recommended LXC configuration
lxc.cgroup2.memory.max = 2G
lxc.cgroup2.cpu.max = 200000 100000  # 2 CPU cores worth
lxc.mount.entry = /dev/sr0 dev/sr0 none bind,optional,create=file
lxc.mount.entry = /dev/sr1 dev/sr1 none bind,optional,create=file
```

### Installation Steps

1. **Create Container**
```bash
lxc-create -n disk2iso -t download -- -d debian -r bookworm -a amd64
```

2. **Configure Storage**
```bash
# Add storage mount for ISO output
lxc config device add disk2iso storage disk source=/storage/isos path=/opt/disk2iso/output
```

3. **Install Dependencies**
```bash
# Inside container
apt-get update
apt-get install -y python3 python3-pip python3-venv \
    ddrescue cdrdao cdrtools genisoimage \
    nginx python3-flask redis-server \
    udev udisks2
```

4. **Deploy Application**
```bash
cd /opt/disk2iso
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Systemd Service

```ini
[Unit]
Description=disk2iso Web Service
After=network.target redis.service

[Service]
Type=notify
User=disk2iso
Group=disk2iso
WorkingDirectory=/opt/disk2iso
Environment="PATH=/opt/disk2iso/venv/bin"
ExecStart=/opt/disk2iso/venv/bin/gunicorn \
    --workers 4 \
    --bind unix:/run/disk2iso/disk2iso.sock \
    --access-logfile /var/log/disk2iso/access.log \
    --error-logfile /var/log/disk2iso/error.log \
    wsgi:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Web Interface Specifications

### 1. Dashboard Page (`/`)

**Purpose**: Main control center for disk imaging operations

**Layout**:
```
┌─────────────────────────────────────────┐
│  disk2iso - Dashboard                   │
├─────────────────────────────────────────┤
│  [Active Jobs (2)]  [Completed (15)]    │
│                                          │
│  ┌─────────────────────────────────┐   │
│  │ Job: movie_collection_disc1     │   │
│  │ Status: Running (45%)           │   │
│  │ Progress: ████████░░░░░░░░      │   │
│  │ Speed: 2.4 MB/s | ETA: 4:23    │   │
│  │ [Pause] [Cancel] [Details]     │   │
│  └─────────────────────────────────┘   │
│                                          │
│  ┌─────────────────────────────────┐   │
│  │ Job: backup_dvd_2024           │   │
│  │ Status: Queued                  │   │
│  │ Position: #2 in queue          │   │
│  │ [Cancel] [Edit Priority]       │   │
│  └─────────────────────────────────┘   │
│                                          │
│  [+ New Imaging Job]                   │
│                                          │
│  System Status:                         │
│  • Available Drives: 2                  │
│  • Storage Free: 847 GB                │
│  • CPU Usage: 12%                      │
│  • Memory: 456 MB / 2 GB               │
└─────────────────────────────────────────┘
```

**Features**:
- Real-time job status updates (WebSocket or SSE)
- Progress bars with percentage and ETA
- Quick actions (pause, cancel, resume)
- System resource monitoring
- Drive detection and status
- One-click job creation

**Key UI Elements**:
- Job cards with color-coded status (green=running, blue=queued, gray=completed)
- Toast notifications for events
- Responsive grid layout
- Auto-refresh every 2 seconds for active jobs

### 2. Archive Page (`/archive`)

**Purpose**: Browse, search, and manage completed ISO images

**Layout**:
```
┌─────────────────────────────────────────┐
│  Archive                                │
├─────────────────────────────────────────┤
│  [Search: _________] [Filter ▼] [Sort ▼]│
│                                          │
│  ┌─────────────────────────────────┐   │
│  │ 📀 movie_collection_disc1.iso   │   │
│  │ 4.7 GB • Created: 2025-12-30   │   │
│  │ MD5: a3b4c5d6...               │   │
│  │ [Download] [Verify] [Delete]   │   │
│  └─────────────────────────────────┘   │
│                                          │
│  ┌─────────────────────────────────┐   │
│  │ 💿 software_archive_2024.iso    │   │
│  │ 8.5 GB • Created: 2025-12-28   │   │
│  │ SHA256: f7e8d9a0...            │   │
│  │ [Download] [Verify] [Delete]   │   │
│  └─────────────────────────────────┘   │
│                                          │
│  Showing 1-20 of 156 items             │
│  [← Previous] [1] [2] [3] ... [Next →] │
└─────────────────────────────────────────┘
```

**Features**:
- Full-text search across metadata
- Filter by date, size, type, status
- Sort by name, date, size
- Bulk operations (delete, verify)
- Checksum verification
- Direct download links
- Pagination for large archives
- Metadata editing

**Advanced Features**:
- Tags and categories
- Notes and descriptions
- Quality ratings
- Verification history
- Export metadata to CSV/JSON

### 3. Configuration Page (`/config`)

**Purpose**: System settings and preferences

**Sections**:

#### Storage Settings
```
┌─────────────────────────────────────────┐
│ Storage Configuration                   │
├─────────────────────────────────────────┤
│ Output Directory:                       │
│ [/opt/disk2iso/output] [Browse]        │
│                                          │
│ Auto-cleanup:                           │
│ ☑ Delete source on success             │
│ ☑ Keep logs for [30] days              │
│                                          │
│ Storage Threshold:                      │
│ [⚠️ Alert at 90% full]                  │
│ [🛑 Stop at 95% full]                   │
└─────────────────────────────────────────┘
```

#### Imaging Defaults
```
┌─────────────────────────────────────────┐
│ Default Imaging Options                 │
├─────────────────────────────────────────┤
│ Read Attempts: [5]                      │
│ Sector Size: [2048] bytes              │
│ Verify After Creation: ☑ Enabled       │
│ Generate Checksums: ☑ MD5 ☑ SHA256    │
│ Compression: [None ▼]                  │
│ Priority: [Normal ▼]                   │
└─────────────────────────────────────────┘
```

#### Notification Settings
```
┌─────────────────────────────────────────┐
│ Notifications                           │
├─────────────────────────────────────────┤
│ ☑ Email on completion                  │
│   Email: [user@example.com]            │
│                                          │
│ ☑ Webhook notifications                │
│   URL: [https://hooks.example.com]     │
│                                          │
│ ☑ Browser notifications                │
└─────────────────────────────────────────┘
```

#### User Management
```
┌─────────────────────────────────────────┐
│ Users & Authentication                  │
├─────────────────────────────────────────┤
│ Current User: admin                     │
│ Role: Administrator                     │
│                                          │
│ [Change Password]                       │
│ [Manage API Keys]                      │
│ [View Audit Log]                       │
│                                          │
│ Users:                                  │
│ • admin (Administrator)                │
│ • operator (Operator) [Edit] [Delete] │
│ [+ Add User]                           │
└─────────────────────────────────────────┘
```

## API Endpoints

### Authentication

All API endpoints require authentication via:
- Session cookies (web interface)
- API key in header: `X-API-Key: <key>`
- JWT bearer token: `Authorization: Bearer <token>`

### Core Endpoints

#### Jobs

```http
GET /api/v1/jobs
```
List all jobs with pagination and filtering.

**Query Parameters**:
- `status`: filter by status (running, queued, completed, failed)
- `limit`: items per page (default: 50)
- `offset`: pagination offset
- `sort`: sort field (created, updated, name)

**Response**:
```json
{
  "jobs": [
    {
      "id": "job_123456",
      "name": "movie_collection_disc1",
      "status": "running",
      "progress": 45,
      "created_at": "2025-12-31T14:00:00Z",
      "updated_at": "2025-12-31T14:15:00Z",
      "device": "/dev/sr0",
      "output_file": "/opt/disk2iso/output/movie_collection_disc1.iso",
      "size_bytes": 4700000000,
      "speed_bps": 2400000,
      "eta_seconds": 263
    }
  ],
  "total": 156,
  "limit": 50,
  "offset": 0
}
```

---

```http
POST /api/v1/jobs
```
Create a new imaging job.

**Request Body**:
```json
{
  "name": "my_disk_image",
  "device": "/dev/sr0",
  "options": {
    "read_attempts": 5,
    "verify": true,
    "checksums": ["md5", "sha256"],
    "priority": "normal"
  }
}
```

**Response**:
```json
{
  "id": "job_123457",
  "status": "queued",
  "created_at": "2025-12-31T14:20:00Z"
}
```

---

```http
GET /api/v1/jobs/{job_id}
```
Get detailed job information.

---

```http
PATCH /api/v1/jobs/{job_id}
```
Update job (pause, resume, cancel, change priority).

**Request Body**:
```json
{
  "action": "pause"  // or "resume", "cancel"
}
```

---

```http
DELETE /api/v1/jobs/{job_id}
```
Cancel and remove job.

---

#### Archives

```http
GET /api/v1/archives
```
List completed ISO images.

**Response**:
```json
{
  "archives": [
    {
      "id": "archive_789",
      "filename": "movie_collection_disc1.iso",
      "path": "/opt/disk2iso/output/movie_collection_disc1.iso",
      "size_bytes": 4700000000,
      "created_at": "2025-12-30T20:00:00Z",
      "checksums": {
        "md5": "a3b4c5d6e7f8g9h0",
        "sha256": "f7e8d9a0b1c2d3e4f5g6h7i8j9k0l1m2"
      },
      "metadata": {
        "label": "Movie Collection Vol 1",
        "tags": ["movies", "backup"],
        "notes": "Personal movie collection"
      }
    }
  ]
}
```

---

```http
GET /api/v1/archives/{archive_id}
```
Get archive details.

---

```http
GET /api/v1/archives/{archive_id}/download
```
Download ISO file.

---

```http
POST /api/v1/archives/{archive_id}/verify
```
Verify ISO integrity against checksums.

---

```http
PATCH /api/v1/archives/{archive_id}
```
Update metadata.

**Request Body**:
```json
{
  "metadata": {
    "label": "Updated Label",
    "tags": ["movies", "backup", "2024"],
    "notes": "Updated notes"
  }
}
```

---

```http
DELETE /api/v1/archives/{archive_id}
```
Delete archive.

---

#### Devices

```http
GET /api/v1/devices
```
List available optical drives.

**Response**:
```json
{
  "devices": [
    {
      "path": "/dev/sr0",
      "vendor": "ASUS",
      "model": "DVD-RW DRW-24B1ST",
      "status": "idle",
      "has_media": true,
      "media_type": "dvd",
      "media_size_bytes": 4700000000
    }
  ]
}
```

---

```http
POST /api/v1/devices/{device}/eject
```
Eject media from drive.

---

#### System

```http
GET /api/v1/system/status
```
Get system status and resource usage.

**Response**:
```json
{
  "status": "healthy",
  "version": "2.0.0",
  "uptime_seconds": 86400,
  "resources": {
    "cpu_percent": 12.5,
    "memory_used_bytes": 478150656,
    "memory_total_bytes": 2147483648,
    "storage_used_bytes": 102400000000,
    "storage_total_bytes": 1000000000000
  },
  "services": {
    "redis": "running",
    "nginx": "running"
  }
}
```

---

```http
GET /api/v1/system/config
```
Get current configuration.

---

```http
PATCH /api/v1/system/config
```
Update configuration.

---

#### Logs

```http
GET /api/v1/logs
```
Retrieve application logs.

**Query Parameters**:
- `level`: filter by level (debug, info, warning, error)
- `since`: ISO timestamp
- `limit`: number of entries

---

### WebSocket Endpoints

```
ws://server/api/v1/ws/jobs
```
Real-time job updates.

**Message Format**:
```json
{
  "type": "job_update",
  "job_id": "job_123456",
  "data": {
    "status": "running",
    "progress": 46,
    "speed_bps": 2450000,
    "eta_seconds": 258
  }
}
```

## Security Considerations

### Authentication & Authorization

1. **User Roles**:
   - `admin`: Full system access
   - `operator`: Create/manage jobs, view archives
   - `viewer`: Read-only access

2. **Password Policy**:
   - Minimum 12 characters
   - Must include uppercase, lowercase, numbers
   - Hashed with bcrypt (cost factor 12)
   - Forced rotation every 90 days

3. **API Keys**:
   - Generated with cryptographically secure random
   - Can be scoped to specific permissions
   - Expirable
   - Revocable

4. **Session Management**:
   - HTTPOnly, Secure, SameSite cookies
   - 30-minute timeout with activity extension
   - Maximum 24-hour lifetime
   - Concurrent session limits

### Network Security

```nginx
# Nginx configuration
server {
    listen 443 ssl http2;
    server_name disk2iso.local;
    
    ssl_certificate /etc/ssl/certs/disk2iso.crt;
    ssl_certificate_key /etc/ssl/private/disk2iso.key;
    ssl_protocols TLSv1.3 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    location / {
        proxy_pass http://unix:/run/disk2iso/disk2iso.sock;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Input Validation

- All user inputs sanitized and validated
- Path traversal prevention
- SQL injection protection (parameterized queries)
- XSS prevention (output encoding)
- CSRF tokens for state-changing operations
- File upload restrictions (size, type)

### Audit Logging

All security-relevant events logged:
```json
{
  "timestamp": "2025-12-31T14:21:04Z",
  "event_type": "authentication",
  "action": "login_success",
  "user": "admin",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "details": {
    "method": "password"
  }
}
```

Events tracked:
- Login/logout attempts
- Password changes
- API key generation/revocation
- Configuration changes
- Job creation/deletion
- Archive deletion
- Permission changes

### File System Security

- Output directory permissions: `755` (rwxr-xr-x)
- ISO files: `644` (rw-r--r--)
- Config files: `600` (rw-------)
- Service runs as dedicated user `disk2iso`
- No world-writable files
- AppArmor/SELinux profiles

### Backup & Recovery

```bash
# Automated backup script
#!/bin/bash
BACKUP_DIR="/backup/disk2iso"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup database
sqlite3 /opt/disk2iso/data/disk2iso.db ".backup ${BACKUP_DIR}/db_${DATE}.db"

# Backup configuration
tar -czf ${BACKUP_DIR}/config_${DATE}.tar.gz /opt/disk2iso/config/

# Keep only last 30 days
find ${BACKUP_DIR} -type f -mtime +30 -delete
```

## Minimal CLI Usage

While the web interface is primary, CLI tools are available for:

### Emergency Operations

```bash
# Check service status
disk2iso status

# Emergency stop all jobs
disk2iso stop --all

# Manual job creation (bypassing web)
disk2iso create --device /dev/sr0 --output /backup/emergency.iso

# Verify ISO
disk2iso verify /path/to/image.iso
```

### System Administration

```bash
# User management
disk2iso user add <username> --role operator
disk2iso user reset-password <username>
disk2iso user list

# Configuration
disk2iso config get
disk2iso config set storage.output_dir /new/path

# Backup/Restore
disk2iso backup --output /backup/disk2iso_backup.tar.gz
disk2iso restore --input /backup/disk2iso_backup.tar.gz
```

### Automation & Scripting

```bash
# API interaction via curl
curl -X POST https://disk2iso.local/api/v1/jobs \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "automated_backup",
    "device": "/dev/sr0",
    "options": {"verify": true}
  }'

# Batch operations
for device in /dev/sr*; do
  if disk2iso device has-media $device; then
    disk2iso create --device $device --auto-name
  fi
done
```

### Monitoring Integration

```bash
# Prometheus metrics export
disk2iso metrics --format prometheus > /var/lib/prometheus/disk2iso.prom

# Health check for monitoring systems
disk2iso health && echo "OK" || echo "FAIL"

# Log streaming
disk2iso logs --follow --level error | logger -t disk2iso
```

## Technology Stack

### Backend
- **Framework**: Flask 3.x (Python 3.11+)
- **WSGI Server**: Gunicorn with gevent workers
- **Database**: SQLite 3 (or PostgreSQL for multi-instance)
- **Task Queue**: Redis + RQ (Redis Queue)
- **Cache**: Redis

### Frontend
- **Template Engine**: Jinja2
- **CSS Framework**: Tailwind CSS or Bootstrap 5
- **JavaScript**: Vanilla JS + Alpine.js for reactivity
- **Real-time**: Server-Sent Events (SSE) or WebSockets

### DevOps
- **Container**: LXC/LXD
- **Reverse Proxy**: Nginx
- **Process Manager**: systemd
- **Logging**: Python logging + logrotate
- **Monitoring**: Prometheus metrics endpoint

## Development Roadmap

### Phase 1: Core Web Interface (v2.0)
- [ ] Basic dashboard with job listing
- [ ] Job creation and management
- [ ] Archive browsing
- [ ] Device detection and selection
- [ ] User authentication

### Phase 2: Advanced Features (v2.1)
- [ ] Real-time progress updates
- [ ] Batch operations
- [ ] Advanced filtering and search
- [ ] Notification system
- [ ] API documentation (Swagger/OpenAPI)

### Phase 3: Enterprise Features (v2.2)
- [ ] Multi-user support with RBAC
- [ ] Audit logging and compliance
- [ ] LDAP/Active Directory integration
- [ ] High availability setup
- [ ] Prometheus metrics

### Phase 4: Extensions (v2.3+)
- [ ] Webhook integrations
- [ ] Cloud storage backends (S3, Azure Blob)
- [ ] Mobile app (React Native)
- [ ] Advanced scheduling
- [ ] Disk image mounting/browsing

## Deployment Example

```bash
# Complete deployment script
#!/bin/bash
set -e

# Variables
CONTAINER_NAME="disk2iso"
APP_DIR="/opt/disk2iso"
OUTPUT_DIR="/storage/isos"

# Create LXC container
lxc-create -n ${CONTAINER_NAME} -t download -- \
  -d debian -r bookworm -a amd64

# Configure container
cat >> /var/lib/lxc/${CONTAINER_NAME}/config <<EOF
lxc.cgroup2.memory.max = 2G
lxc.cgroup2.cpu.max = 200000 100000
lxc.mount.entry = /dev/sr0 dev/sr0 none bind,optional,create=file
lxc.mount.entry = ${OUTPUT_DIR} opt/disk2iso/output none bind,create=dir
EOF

# Start container
lxc-start -n ${CONTAINER_NAME}

# Install application
lxc-attach -n ${CONTAINER_NAME} -- bash <<'SETUP'
# Update system
apt-get update && apt-get upgrade -y

# Install dependencies
apt-get install -y python3 python3-pip python3-venv \
  ddrescue cdrdao cdrtools genisoimage \
  nginx redis-server git

# Create application user
useradd -r -s /bin/bash -d /opt/disk2iso disk2iso

# Clone repository
git clone https://github.com/DirkGoetze/disk2iso.git /opt/disk2iso
chown -R disk2iso:disk2iso /opt/disk2iso

# Setup Python environment
su - disk2iso -c "
  python3 -m venv /opt/disk2iso/venv
  source /opt/disk2iso/venv/bin/activate
  pip install -r /opt/disk2iso/requirements.txt
"

# Configure services
systemctl enable redis-server
systemctl enable nginx
systemctl enable disk2iso

# Start services
systemctl start redis-server
systemctl start disk2iso
systemctl start nginx

echo "Deployment complete!"
SETUP

echo "Access the web interface at: https://$(lxc-info -n ${CONTAINER_NAME} -iH)"
```

## Conclusion

This Web-First architecture transforms disk2iso from a CLI-only tool into a modern, accessible web application suitable for both individual users and enterprise deployments. The LXC containerization ensures portability and isolation, while the comprehensive API enables integration with existing workflows and automation systems.

The design prioritizes security, usability, and maintainability, with clear separation of concerns between the web interface, API, and core imaging functionality. The minimal CLI remains available for edge cases and automation, but the web interface provides the primary user experience.

---

**Last Updated**: 2025-12-31  
**Version**: 2.0  
**Author**: DirkGoetze
# Study Now - DevOps Assessment

## Objective
Build a reliable, secure and recoverable Node.js application
using Docker, MongoDB, Nginx and GitHub Actions.

## Architecture
- Node.js and Express
- MongoDB with authentication
- Nginx reverse proxy
- Docker Compose
- GitHub Actions CI/CD
- Encrypted offsite backups
- Health monitoring and alerting

## Recovery Objectives
- Target RTO: 4 hours
- Target RPO: 1 hour

## Project Status
Implementation in progress.

## Backup and Recovery Drill Evidence

**Test date:** 7 November 2026

### Backup
- Database: `study_now`
- Backup method: MongoDB `mongodump` using archive and gzip.
- Encryption: `age` public-key encryption.
- Backup location: `backups/offsite-simulation/`
- Backup file: `study_now-20261106T185021Z.archive.gz.age`
- Backup contents: 1 student document.
- Validation: Successfully decrypted the archive and completed a MongoDB restore dry-run.

### Recovery drill
1. Started with the application and MongoDB running.
2. Deleted the `students` collection from the local assessment database.
3. Ran the restore script using the encrypted backup.
4. Verified the application readiness endpoint returned HTTP 200.
5. Verified the original student record was present after restoration.

**Measured local recovery duration: 62 seconds.**

**Recovery verification:**
- `/ready`: HTTP 200 — database connected.
- `/api/students`: HTTP 200 — original test record recovered.

### Scope and limitations
This is a local Docker-based recovery demonstration using synthetic test data. The backup directory is an offsite-storage simulation only; it is not an independently hosted backup destination. The 62-second measurement applies to this local drill and does not establish production RTO or RPO compliance. Production deployment would require independent backup storage, scheduled backups, retention, restore testing, and monitoring.

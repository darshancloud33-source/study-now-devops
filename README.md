# Study Now - DevOps Assessment
# Name - Darshan D


## Objective
Build a reliable, secure and recoverable Node.js application
using Docker, MongoDB, Nginx and GitHub Actions.

## Architecture
- Node.js and Express
- MongoDB with authentication
- Nginx reverse proxy
- Docker Compose
- GitHub Actions CI (tests, lint and Docker image build)
- Encrypted MongoDB backups (local offsite simulation)
- Health monitoring and alerting

## Architecture Diagram for your Study Now DevOps Engineer assessment. It includes application infrastructure, CI/CD, Blue-Green deployment, security, backup and restore, monitoring, and the operational workflow.

<img width="4666" height="5824" alt="image" src="https://github.com/user-attachments/assets/20790b60-98bc-4fa3-854c-45279e95de58" />


# Shows User → Nginx → Blue/Green Node.js → MongoDB, including Docker Compose.
<img width="1188" height="872" alt="image" src="https://github.com/user-attachments/assets/032c031d-f8d3-435e-8e79-46bf62312b01" />


# Shows how traffic switches between Blue and Green and how rollback works.
<img width="800" height="533" alt="image" src="https://github.com/user-attachments/assets/a854f582-b426-4156-8b9f-c90ff6af8105" />



# Part 2 disaster recovery architecture
# Shows the proposed Linode, DigitalOcean, Cloudflare DNS and backup recovery strategy.
<img width="478" height="473" alt="image" src="https://github.com/user-attachments/assets/86cf0eca-402d-4f6a-be57-8d2f47a3413a" />



## Recovery Objectives
- Target RTO: 4 hours
- Target RPO: 1 hour

## Project Status
Local assessment implementation and validation completed. GitHub Actions validates tests, lint and Docker image builds. Production cloud deployment and independently hosted backups are not implemented in this demonstration.

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
This is a local Docker-based recovery demonstration using synthetic test data. The backup directory is an offsite-storage simulation only; it is not an independently hosted backup destination. The 62-second measurement applies to this local drill and does not establish production RTO or RPO compliance. Hourly backups, seven-day local retention, five-minute health checks, and Discord failure notifications are configured and tested locally. Production still requires independent hosted backup storage, reliable server-side scheduling, restore testing, and production monitoring.

## Blue-Green Deployment and Rollback

### Deployment architecture

The application uses two Docker Compose application services:

- `app-blue`
- `app-green`

Nginx routes incoming traffic to one active application using
`docker/nginx/upstream.conf`.

Both application containers connect to the same MongoDB database.
The inactive application is rebuilt and started before traffic is switched.

### Deploy a new version

Run:

    ./scripts/deploy.sh

The deployment script:

1. Identifies the currently active application.
2. Builds and recreates the inactive application.
3. Waits for its Docker readiness health check.
4. Validates the Nginx configuration.
5. Reloads Nginx to switch traffic.
6. Keeps the previous application running for rollback.

### Rollback

Run:

    ./scripts/rollback.sh

The rollback script:

1. Identifies the alternate application.
2. Checks that its container is healthy.
3. Updates the Nginx upstream.
4. Validates and reloads Nginx.

### Local deployment test evidence

The following tests were completed on 7 November 2026:

- Blue to Green deployment: successful.
- Green container health check: passed.
- Nginx configuration validation: passed.
- Nginx traffic switch: successful.
- Green to Blue rollback: successful.
- Application readiness after rollback: HTTP 200.
- Existing test student record remained available after both switches.

### Deployment limitations

This is a local Docker Compose demonstration. The GitHub Actions workflow currently runs lint, application tests and Docker image build. It does not automatically deploy to a cloud server.

Both application versions share the same MongoDB database. Database schema changes must therefore remain backward-compatible with the previous application version during a Blue-Green release.


## Scheduled Backups and Health Monitoring

### Scheduled backup

- macOS cron schedules encrypted MongoDB backups hourly.
- Backup script: `scripts/backup.sh`.
- Encryption: age.
- Retention: seven days.
- Local destination: `backups/offsite-simulation/`.
- Log: `backups/backup-cron.log`.

### Health checks and Discord alerts

- macOS cron runs `scripts/healthcheck.sh` every five minutes.
- The script checks the application `/health` endpoint.
- Failed checks trigger a Discord webhook notification.
- Webhook destination: configured Discord `#general` channel.
- Webhook secret is stored outside the repository at `~/.config/study-now/discord-webhook-url`.
- Log: `backups/healthcheck.log`.

### Alert validation evidence

- Discord webhook test returned HTTP 204.
- Test notification was visible in Discord `#general`.
- Two simulated health-check failures triggered Discord notifications.
- The actual application was not stopped during these tests.

### Scheduling limitations

These cron jobs run on the local Mac. The Mac must be awake and Docker Desktop must be running. This is a local demonstration, not a production scheduling solution. Production backups must be stored independently of the application host.\n

## 2 AM Incident Checklist

1. Acknowledge the alert and assess customer impact.

2. Check application and dependencies:
   - Run `docker compose ps`.
   - Review `docker compose logs --tail=100 nginx app-blue app-green mongo`.
   - Check `/health` and `/ready` on port 8081.

3. Identify the active application using `cat docker/nginx/upstream.conf`.

4. If a recent release caused the issue, verify the alternate application is healthy, run `./scripts/rollback.sh`, and verify readiness.

5. For suspected data loss, preserve the current state, identify a verified backup and obtain authorization before restoring. Use `RESTORE_CONFIRM=YES ./scripts/restore.sh` followed by the actual backup file path.

6. Verify database contents and application readiness after recovery.

7. Escalate, communicate updates and record incident timestamps and actions. Avoid destructive commands without authorization.

**Environment limitation:** This checklist is demonstrated locally. Production incident response requires independent monitoring, off-host backups and an escalation path.

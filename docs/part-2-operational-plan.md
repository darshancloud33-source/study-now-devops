# Part 2 — Infrastructure Operations and Disaster Recovery Plan

## 1. First Two Weeks: Audit, Security and Documentation

My first priority would be to understand the existing infrastructure before making changes that could affect student access or data.

### Days 1–3: Discover and document
- Inventory all Linode and DigitalOcean servers, regions, sizes, operating systems, IP addresses and running services.
- Identify MongoDB instances, uploaded-document storage, application components, DNS records and Cloudflare zones.
- Map application dependencies, traffic flow, deployment processes, backup locations and external integrations.
- Identify service owners, access methods, support contacts and current recovery procedures.
- Capture existing configurations and verify backups before making changes.

### Days 4–7: Reduce immediate risk
- Review SSH access, remove unused accounts and keys, enforce MFA and least-privilege access.
- Rotate shared or exposed credentials and move secrets out of source code.
- Review firewall rules, public ports, database exposure, TLS certificates and operating-system patch levels.
- Enable centralized logs and monitoring for availability, disk space, CPU and memory.
- Check backup schedules, retention, encryption and access permissions.

### Days 8–10: Validate and establish ownership
- Perform an isolated test restore of MongoDB and uploaded documents.
- Document deployment, rollback, backup, restore and incident procedures.
- Identify unsupported software, single points of failure and capacity risks.
- Agree on service-level indicators, alert thresholds, escalation contacts and on-call ownership.
- Produce an audit report with prioritized risks, owners and remediation dates.

I would avoid major architecture changes until the inventory, backup state and recovery dependencies are understood.

## 2. 3-2-1 Backup Strategy with an RPO of One Hour

The objective is to maintain three copies of important data, across two different storage systems or providers, with at least one copy offsite.

### MongoDB
- Keep the primary database in the production Linode environment.
- Use MongoDB replica-set oplog or point-in-time recovery capability, with recovery points no more than 15 minutes apart where supported.
- Create encrypted backups at least hourly and transfer them to separate object storage or another region.
- Enable object versioning and retention protection.
- Regularly test restoration and verify recovered records against backup timestamps.

### Uploaded student documents
- Keep the primary document store in production.
- Enable object versioning and replicate documents to another region or provider.
- Maintain encrypted backup copies with checksums and lifecycle retention policies.
- Ensure database metadata and uploaded documents can be recovered consistently.

### Monitoring and cost control
- Alert if the latest successful recovery point is more than 45 minutes old.
- Verify backup completion, object counts, checksums and restore success.
- Consider daily recovery points for 30 days and monthly copies for longer-term retention.

### Indicative monthly cost
For an assumed 50 GB MongoDB dataset and 100 GB of uploaded documents, I would initially budget approximately US$25–75 per month for backup storage, versioning, requests and transfer.

A warm standby server or database capacity could add approximately US$30–100 per month or more, depending on sizing and provider.

These are planning estimates, not provider quotations. Actual costs depend on retention, storage class, replication, requests and recovery egress.

The one-hour RPO must be demonstrated by measuring the age of the latest recoverable committed transaction, not simply by scheduling a backup every hour.

## 3. Linode Region Failure at 09:00 UK Time

I would declare a major incident, assign an incident lead and record the recovery timeline from 09:00.

### 09:00–09:30 — Assess and contain
- Confirm the region failure using provider status and independent health checks.
- Identify affected services, database availability and uploaded-document access.
- Communicate the incident and coordinate recovery actions.
- Record the latest known-good database recovery point and document replication status.

### 09:30–10:30 — Recover infrastructure
- Activate the pre-provisioned DigitalOcean standby environment in a separate region.
- Apply infrastructure configuration, firewall rules, application images and secrets.
- Restore or promote the MongoDB replica or backup using the latest valid recovery point.
- Restore or verify access to replicated student documents.

### 10:30–12:00 — Restore application service
- Start application services and validate database connectivity.
- Verify application readiness, authentication and representative student workflows.
- Check database records and uploaded-document references for consistency.
- Run synthetic transactions and review application and infrastructure logs.

### 12:00–13:00 — Shift traffic and monitor
- Update the Cloudflare origin or activate configured load-balancer failover.
- Verify DNS resolution, TLS, origin connectivity and application availability.
- Monitor errors, latency, database health and customer-facing workflows.
- Communicate service restoration and continue heightened monitoring.

The target is to restore verified customer-facing service by 13:00 UK time, within the four-hour RTO. If recovery is delayed, I would communicate the impact and revised estimate rather than claim service is restored prematurely.

## 4. Cloudflare and DNS Improvements During the First Month

### Week 1
- Audit DNS records, zone ownership, proxy settings, TTLs, TLS configuration and existing access tokens.
- Export and securely retain the current configuration.

### Week 2
- Enforce MFA and use scoped API tokens.
- Enable DNSSEC where supported.
- Configure TLS to Full (strict).
- Restrict direct origin access to trusted Cloudflare traffic where practical.

### Week 3
- Review WAF rules, rate limiting, bot protection and caching.
- Bypass caching for authentication, student records and other sensitive dynamic endpoints.
- Define safe cache rules for static assets.

### Week 4
- Configure external origin health checks and failover to the DigitalOcean standby where the Cloudflare plan supports it.
- Document DNS rollback.
- Test failover and validate TLS and application behavior after traffic switching.

I would finish the month with a documented DNS inventory, access-control review, tested failover procedure and clear ownership of Cloudflare changes.

## Implementation Boundary

The accompanying assessment project demonstrates a local Docker Compose application, CI tests and image build, Blue-Green deployment and rollback, encrypted MongoDB backup and restore, and Discord health alerts.

The Linode and DigitalOcean standby, independent hosted backups, production Cloudflare failover and production RPO/RTO are proposed operational improvements. They have not been deployed or validated in the local demonstration.

# Decision: local read-only evidence

Status: accepted, 4 November 2026.

An endpoint problem needs evidence from the affected computer. The first
version runs locally and writes small reports. No remote management service,
cloud account or stored credential is required.

Collection, interpretation and reporting are separate functions. Each read has
an explicit status. Partial evidence remains visible. A missing or failed read
becomes unknown. A finding suggests a check and does not claim a cause.

The alternative was automatic repair. That would require policy decisions,
elevation, user consent and rollback logic. Those are outside this first lab.
Manual actions belong in runbooks and must be verified with the user.

The event sample is capped and excludes messages. Device identifiers and raw
registry file paths are excluded to reduce unnecessary data collection.

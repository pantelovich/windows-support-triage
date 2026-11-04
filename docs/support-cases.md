# Support cases

These are fictional practice cases. Reports alone do not close a ticket.

## Documents do not print

Ask whether one application, one user or everyone using that printer is affected.
Confirm the printer is powered, connected and showing no physical error.
Compare another document or the approved test page with the user's permission.

Run the printing case. A stopped Spooler is a lead. Check whether the service
was disabled intentionally and whether policy allows printing on this device.
Follow the local runbook for an authorised service change. Restarting a shared
print service can affect others, so agree the impact first.

Check the printer connection, correct printer, queue and driver when the service
is already running. Do not delete queued jobs without checking their impact.
Verify with a test page and the user's original document. Escalate recurring
service crashes with times, event IDs, driver information and checks completed.

## Laptop is slow and applications cannot save

Confirm affected applications, free space, start time, recent updates and whether
other devices show the same issue. Use the performance case as a starting point.
Low free disk space may explain failed saves or updates, but does not explain
every performance problem. Memory, CPU, storage health and application problems
need separate checks. They are not measured by this version.

Agree cleanup through approved Windows storage controls. Preserve user files.
If a restart is suitable, save work and agree a time first. Recheck disk space
and reproduce the original task. Record the measured change and user outcome.

## Evidence cannot be read

Run the unavailable case. Several checks have no evidence. Establish whether
the limitation is permissions, policy or a missing Windows component. Follow
the approved elevation process only when needed. Escalate with the missing
checks and error types. Never report those checks as passed.

## Handover example

"One user reports that documents do not print. The local read-only check found
the Print Spooler stopped. I will confirm the printer is expected on this device
and review policy before any service change. Resolution is not yet verified."

After a real authorised repair, add the action, time, owner and the user's test.

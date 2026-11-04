# First exercise

The user says: "My documents will not print. It worked yesterday."

1. Run the printing demo from the README. Open the Markdown report.
2. Identify the stopped service and explain why that is a useful lead.
3. Explain why the 7031 example event is supporting context rather than proof.
4. Tell the user what you will check before changing the service.
5. Use the printing runbook to describe the authorised action and a test page.
6. Write five ticket lines: impact, evidence, action, verification, next step.
   Label the ticket as a fictional practice case. No printer has been repaired.
7. Run `-Demo unavailable` with a different case reference. Explain why a
   permission failure must not become a healthy result.

## Explain the code

`Get-EndpointSnapshot` reads local Windows information. It converts each read
into a status and a small set of values. An exception produces unavailable
evidence rather than ending the entire collection.

`Get-EndpointFinding` applies explicit rules. For example, it compares free disk
bytes with total bytes. It does not use an AI model or infer a confirmed cause.

`ConvertTo-EndpointReport` turns those findings into Markdown and adds a ticket
handover. It leaves the repair and resolution for the technician to record.

`Invoke-EndpointTriage.ps1` chooses live collection or a fixed demo snapshot,
then writes JSON and Markdown without replacing an existing case.

## Windows practice

Use an authorised disposable Windows VM or your own Windows computer. Take a VM
snapshot first. Run live collection and compare the version, disk space and
service state with Settings, Services and Event Viewer. Do not stop services or
fill a real disk to reproduce the fixtures. Record which readings you verified.
Manual Windows 11 verification is a separate step from the offline demo.

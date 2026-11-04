# Project context

Purpose: demonstrate Windows endpoint troubleshooting and clear incident handovers.
It complements the Azure Service Desk Toolkit, which focuses on tenant evidence.
Initial scope: operating system details, system disk space, printing service state,
restart indicators and recent error metadata. Produce JSON and Markdown reports.
Offline examples must work on macOS without a Windows VM or a cloud subscription.
The live collector requires Windows. It does not diagnose every support issue.
Current state: collector, rules, reports, fictional cases and CI implemented.
macOS checks and Windows/Linux CI pass, including live Windows collection.
Published at https://github.com/Pantelovich/windows-support-triage.
Use docs/validation.md for the current test boundary.


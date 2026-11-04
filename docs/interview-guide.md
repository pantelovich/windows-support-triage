# Interview explanation

## Describe the project

"I built a PowerShell tool to collect Windows device evidence and produce a
clear support handover. It checks disk space, restart indicators, a printing
service and recent error metadata. It separates missing evidence from a pass
and leaves the repair and user verification for the technician."

## Why build it

The tenant toolkit helps investigate Microsoft 365 account issues. A user may
have a healthy account and still have a local Windows problem. This project
adds device troubleshooting and gives me repeatable cases to practise.

## Why read only

An unexpected service restart or cleanup can interrupt work. Collect first,
understand the impact, then use the organisation's approved repair process.

## What is the hardest design decision

Keep a failed read separate from a healthy result. A normal user might not be
allowed to read a log. Reporting zero errors in that situation would hide a
gap in evidence. This tool says unknown instead.

## How do you test it

Fictional fixtures cover stopped printing, low disk space, limited evidence
and an example with no flagged findings. Boundary tests check thresholds,
invalid values and protected report files. Windows smoke checks exercise
the actual collection APIs. Explain which checks you have personally run.

## What is outside the project

It does not manage Active Directory or Intune, repair devices automatically,
check network access or prove a printer works. A successful report is not a
resolved incident. Manual Windows 11 and printer checks remain separate.

## CV wording

"Built a read-only PowerShell endpoint triage tool with disk, restart and
printing checks, structured reports, Pester tests and Windows/Linux CI."

Use this as a personal project. Only claim live CI checks after they pass.
Do not describe fictional cases as incidents at a previous employer.

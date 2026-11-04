# Validation

4 November 2026.

- macOS, PowerShell 7.6.8: PSScriptAnalyzer checks and 16 Pester checks pass.
- Offline demo: all four fictional scenarios exercised by the test suite or
  evidence tests. Report output and protection against overwrite checked.
- Windows and Linux GitHub Actions: both passed, including live Windows
  collection, on [run 41901519882](https://github.com/Pantelovich/windows-support-triage/actions/runs/41901519882).
- Windows CI used Pester 5.7.1 and PSScriptAnalyzer 1.24.0. Linux passed the
  same checks. Windows skipped the one non-Windows platform rejection test.
- Windows 11 VM and physical printer: not yet manually verified.

The Windows CI smoke test reads real hosted Windows APIs. It is not a Windows 11
desktop or end-user repair test. No live report is uploaded as an artifact.

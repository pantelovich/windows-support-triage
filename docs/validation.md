# Validation

4 November 2026.

- macOS, PowerShell 7.6.8: PSScriptAnalyzer checks and 16 Pester checks pass.
- Offline demo: all four fictional scenarios exercised by the test suite or
  evidence tests. Report output and protection against overwrite checked.
- Windows and Linux GitHub Actions: configured. Live Windows result pending.
- Windows 11 VM and physical printer: not yet manually verified.

The Windows CI smoke test reads real hosted Windows APIs. It is not a Windows 11
desktop or end-user repair test. No live report is uploaded as an artifact.

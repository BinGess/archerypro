I will enhance the app's stability and debuggability to address the crash on restart. The crash likely occurs during the UI rendering phase due to data edge cases (e.g., single data point in charts, NaN values) or race conditions that were not fully captured in the previous logs.

### Plan:
1.  **Harden `ScoreTrendChart`**: 
    - Add checks for `NaN`/`Infinity` values in scores.
    - Handle edge cases where all scores are identical (flat line) or there is only one data point, preventing `fl_chart` from crashing due to invalid axis ranges.
2.  **Defensive Coding in `DashboardScreen`**:
    - Add safety checks when mapping sessions to UI items.
    - Ensure `session.equipment` and `session.scorePercentage` are accessed safely.
3.  **Enhance Logging in `MainContainer`**:
    - Log a summary of loaded sessions (count, first session ID) in `_initializeApp` to verify data integrity immediately after loading.
    - Flush logs to ensure they are written to disk before a potential crash.
4.  **Verify Data Loading**:
    - Add a check in `SessionService` or `StorageService` (via the logging above) to confirm that deserialized objects have valid fields.

This approach addresses the most probable causes (rendering crash due to data anomalies) while providing the necessary observability to pinpoint the issue if it persists.
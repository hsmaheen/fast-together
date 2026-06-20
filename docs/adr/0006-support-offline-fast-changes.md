# Support offline fast changes

The MVP should let users start and end Fasting Sessions while offline and sync those changes later. This keeps the core fasting workflow usable without network access, while circle visibility and notifications can update when connectivity returns. If synced edits conflict from the current Active Device, the last edit wins; writes from a superseded Active Device are rejected when they try to sync.

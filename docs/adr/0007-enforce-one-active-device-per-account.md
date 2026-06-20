# Enforce one active device with takeover

The MVP will allow only one Active Device per App Account. Signing in on a new device transfers the Active Device to that device and signs out the previous device, which avoids trapping users who lose access to an old device while still preventing concurrent edits from multiple signed-in devices. If a superseded device made offline changes, those writes are rejected when the device later reconnects.

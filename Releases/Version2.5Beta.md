# V2.5 Beta Release — Security Overhaul

## Server Side:
- Complete backend rewrite using **Express.js** for performance and reliability.  
- Introduced strict **host-based allowlist** enforcement per domain.  
- Overhauled homepage UI with live uptime, Roblox status, and Discord widget.  
- Enforced **TLS 1.2+ / TLS 1.3** deployment requirements.  
- Introduced **90-day key rotation** for all API and Discord secrets.  
- Sanitized environment variables and disabled verbose stack traces.  
- Added runtime hardening and log redaction of Roblox usernames/IPs.  
- Implemented retry + exponential backoff for Roblox API calls.  
- Added **rate-limiting and WAF guidance**.  
- Deprecated legacy V1.x–V2.x builds (V2 supported until 2025-12-31).  

## Roblox Side:
- Improved **license verification handshake** with stronger validation tokens.  
- Added **real-time Archon Accords health integration** to verify backend status in-game.  
- Optimized **datastore interactions** for faster key lookups and reduced latency.  
- Enhanced **error telemetry** for clearer failure reporting and tracking.  
- Introduced **secure product binding** between user, group, and asset for anti-tamper protection.  
- Added fallback routines for **graceful degradation** during Roblox API downtime.  
- Updated **in-game connection layer** to automatically detect and sync with the latest V3 endpoints.  
- Reduced unnecessary HTTP calls, improving average handshake speed
- Implemented **integrity checking** for game-linked assets to prevent spoofing.

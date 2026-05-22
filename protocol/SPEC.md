# OpenAFP Protocol (Experimental Draft)

> ⚠️ Experimental — OpenAFP is an experimental Agent P2P networking project.  
> This document records the current message structure, network behavior, and engineering constraints. It may change as the project evolves.  
> Current focus: agent discovery, relay, NAT traversal, cross-NAT invocation, and capability collaboration in real network environments.

---

# 1. Design Goals

OpenAFP does not attempt to define an "industry standard."  
Current priorities:

- Agent interconnection in complex network topologies
- NAT / Relay / DHT scenario validation
- Node discovery and capability invocation
- Minimal message structure
- Stability in real public network environments

The protocol emphasizes:

- Minimalism
- Debuggability
- Ease of implementation
- Suitability for real-world network experiments

---

# 2. Current Protocol Positioning

The protocol is best described as:

- Experimental Message Format
- P2P Agent Invocation Format
- Relay-aware Agent Messaging
- libp2p Agent Networking experimental layer

Rather than:

- An industry standard
- Universal Agent infrastructure
- A production-grade interoperability protocol

---

# 3. Message Structure (Current Experimental Version)

The current experimental version uses an 8-field lightweight message structure:

```json
{
  "protocol_version": "0.1",
  "type": "task.request",
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": 1736000000000,
  "from": "peer_a",
  "to": "peer_b",
  "payload": {},
  "extensions": {}
}
```

Field descriptions:

| Field | Required | Description |
|------|----------|-------------|
| protocol_version | ✅ | Current protocol version |
| type | ✅ | Message type |
| id | ✅ | Unique message ID |
| timestamp | ✅ | Millisecond timestamp |
| from | ✅ | Sending node |
| to | ❌ | Target node (empty = broadcast) |
| payload | ✅ | Message content |
| extensions | ❌ | Extension fields |

---

# 4. Current Message Types

The experimental version maintains a minimal message set:

| Type | Purpose |
|------|---------|
| invoke | Invoke a capability on a target node |
| register | Register an agent with its capabilities |
| discover | Query a node's identity and supported capabilities |
| get_status | Retrieve the status of an async task |
| system/list_agents | List all registered agents |

> **Note**: The original v0.1 draft defined `task.request`, `task.result`, and `agent.capabilities`.  
> The current implementation uses JSON-RPC-style method names above. Both sets are semantically equivalent.  
> Future versions may unify the naming convention based on real-world usage feedback.

---

# 5. Timestamp Rules (Experimental Constraints)

To reduce message replay and ordering issues, the current experimental version recommends:

- Message timestamp must fall within a tolerance window of local time
- Expired messages may be silently discarded
- Nodes may use timestamps for basic idempotency checks

These rules remain subject to adjustment.

---

# 6. ID Idempotency Rules

Nodes should:

- Maintain a short-term cache of processed message IDs
- Silently ignore duplicate messages
- Network retries must not re-execute side-effectful operations

This rule primarily addresses:

- Relay retries
- Network instability
- Mobile network switching
- Short-term disconnection recovery

---

# 7. Broadcast Limitations

Broadcast capability is currently experimental only.

Recommendations:

- Limit TTL
- Limit broadcast frequency
- Disable infinite forwarding
- Avoid message storms

OpenAFP does not currently attempt to build a complex broadcast system.

---

# 8. Extension Mechanism

Extension fields should use namespacing:

```json
{
  "extensions": {
    "openafp.trace": {},
    "openafp.progress": {},
    "custom.vendor.feature": {}
  }
}
```

Current principles:

- Keep core fields minimal
- Extension capabilities are carried through extensions
- Unrecognized extensions should be safely ignored

---

# 9. Agent Identity (Current Experimental Stage)

Currently using:

- peer_id
- libp2p identity
- agent_id

For node identification.

Complex authentication systems (DID / PKI / Trust Network) are outside the current experimental scope.

---

# 10. Relationship to Other Protocols

OpenAFP does not attempt to replace:

- MCP
- A2A
- Existing RPC systems

Current focus areas:

- NAT
- Relay
- Node discovery
- Dynamic network connections
- Agent P2P networking behavior

---

# 11. Verified Scenarios

Completed real-world network experiments:

- Home broadband ↔ Public Relay
- 5G hotspot ↔ Cloud nodes
- DHT automatic discovery
- Relay-routed invocation
- Cross-NAT capability invocation
- Dynamic network reconnection
- pull.file cross-node file reading
- Shell capability controlled experiments

---

# 12. Known Issues

Currently present:

- Slow DHT synchronization under certain NAT configurations
- Short delays during relay reconnection
- Stream reconstruction on mobile network switching
- Variable stability in some CGNAT environments
- Security risks with experimental capabilities

---

# 13. Current Project Stage

OpenAFP is closer to:

**"Agent P2P Networking Lab"**

Rather than:

- Enterprise product
- Industry standard
- Commercial platform

The project's primary value lies in:

- Real-world network experimentation
- libp2p + Agent engineering practice
- Relay/NAT/DHT lessons learned
- Agent network behavior exploration

---

# 14. Future Directions (Subject to Change)

Possible future explorations:

- Relay stability improvements
- NAT traversal optimization
- Node recovery
- Broadcast control
- Streaming messages
- Simpler SDK
- Minimal demo network

Whether this evolves into a more formal protocol depends on real-world usage and external feedback.

---

# 15. Document Status

This protocol document is currently:

**Experimental Protocol Draft**

Interfaces, fields, and behaviors may change.  
Do not use directly in production environments.

# auv3-host-introspection

What can an **AUv3 app extension** actually observe about its host and
environment while it's hosted (in AUM, AudioBus, Logic, GarageBand, …)? This
library answers that with a single `Codable` snapshot, `HostDiagnostics`,
assembled from everything reachable from inside the appex sandbox.

Factored out of [auv3-probe](https://github.com/teemow/auv3-probe). Apple
platforms only — iOS 16+ / macOS 13+ (it reads `AVFoundation` / `AudioToolbox` /
`CoreMIDI`).

## Install

```swift
.package(url: "https://github.com/teemow/auv3-host-introspection.git", from: "0.1.0"),
```

then add `AUv3HostIntrospection` to your target's dependencies.

## What it captures

The snapshot is split by provenance:

- **Sanctioned** (AUv3 host blocks, captured on the render thread): `transport`
  (play/record/cycle + sample position), `musicalContext` (tempo, time
  signature, beat/measure position), and the render `AudioTimeStamp`
  (`sampleTime` / `hostTime` / `rateScalar`).
- **AU surface** (off-thread reads on the `AUAudioUnit`): full identity &
  capabilities (`AudioUnitInfo`), a bounded `AUParameterTree` summary, and MIDI
  protocol / MIDI-CI profile negotiation (`MIDINegotiation`).
- **Backdoors** (system frameworks): the `AVAudioSession` route/channels/latency,
  the entire visible `CoreMIDI` graph (every endpoint & device with its
  properties), and the runtime `Environment` (thermal/power, memory, OS/device).

## Use

The render-thread fields must be captured on the realtime thread and published
to the reporter via a closure; everything else the reporter reads off-thread.

```swift
import AUv3HostIntrospection

// Pin a stable os_log subsystem your log tooling (e.g. idevicesyslog) filters on.
HostDiagnostics.logSubsystem = "com.yourapp.auv3"

// One reporter per hosted unit. It assembles a snapshot ~1 Hz for as long as
// the appex is hosted — independent of whether the plugin UI is open.
let reporter = HostDiagnosticsReporter(source: "MyEffect", audioUnit: auAudioUnit) {
    // Read your engine's published render-thread snapshot (never block here).
    HostRenderSnapshot(transport: myEngine.transport,
                       musicalContext: myEngine.musicalContext,
                       renderTime: myEngine.renderTime)
}
reporter.onSnapshot = { snapshot in /* stream / display it */ }
reporter.start()

// Latest snapshot for a passive UI reader:
let json = reporter.latest?.prettyJSON()
```

You can also call the collectors directly, no reporter needed:

```swift
let au = HostDiagnosticsCollector.audioUnit(myAU)        // identity + capabilities
let midi = HostDiagnosticsCollector.midiNegotiation(myAU) // MIDI 1.0/2.0 + MIDI-CI
let session = HostDiagnosticsCollector.audioSession()     // AVAudioSession route
let ports = HostDiagnosticsCollector.coreMIDI()           // visible CoreMIDI graph
let env = HostDiagnosticsCollector.environment()          // thermal/power/device
```

## Output

`HostDiagnostics` is `Codable`/`Sendable`/`Equatable`. `jsonData()` gives a
compact wire frame, `prettyJSON()` a sorted human-readable form, and `log()`
dumps one compact line per section to `os_log` under `logSubsystem` (so each
line survives the unified-log per-message cap and reaches `idevicesyslog`).

## Privacy

A snapshot includes endpoint/device names and the AU's parameter identifiers —
an installation fingerprint. Show it in-UI if you like, but treat it as private.

## License

See [LICENSE](LICENSE).

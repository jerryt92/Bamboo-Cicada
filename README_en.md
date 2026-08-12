# Bamboo Cicada

Language: [中文](README.md) | English

Bamboo Cicada is a small SwiftUI iOS app that recreates the traditional Chinese folk sound toy "竹知了" on a iPhone. Shake the device gently and the bamboo cicada spins, buzzes, and taps back through haptics like a handheld summer toy.

## Features

- Motion-driven cicada toy animation powered by Core Motion.
- Layered bamboo forest and folk-toy visual style.
- Low-latency buzzing audio synchronized with the swing phase.
- UIKit haptic feedback that follows shake intensity and spin speed.
- Full-screen introduction and about screens.
- Introduction and about copy localized in Simplified Chinese, Traditional Chinese, English, Japanese, Korean, and French.
- App Store marketing asset workflow for bilingual screenshots and copy.

## Requirements

- Xcode 16 or later
- iOS 15.0 or later
- A physical iPhone is recommended for motion, audio, and haptic testing

The app can build and run in Simulator, but the main interaction is designed around real device motion.

## Getting Started

1. Open `Bamboo Cicada.xcodeproj` in Xcode.
2. Select the `Bamboo Cicada` scheme.
3. Choose a physical iPhone.
4. Build and run.

Command-line build:

```sh
xcodebuild \
  -project "Bamboo Cicada.xcodeproj" \
  -scheme "Bamboo Cicada" \
  -destination 'generic/platform=iOS' \
  -derivedDataPath DerivedData-CodexBuild \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Tests

Run the unit and UI test targets with Xcode, or from the command line:

```sh
xcodebuild \
  -project "Bamboo Cicada.xcodeproj" \
  -scheme "Bamboo Cicada" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

## Project Structure

```text
Bamboo Cicada/
  App/                    SwiftUI app entry point
  Configuration/          Tunable motion, audio, and haptic constants
  Features/Game/          Motion model, view model, audio, haptics, and toy view
  Features/Introduction/  Introduction, about screens, and language copy
  Shared/Views/           Reusable backgrounds and layout helpers
  *.lproj/                Localized Info.plist strings

AppStoreMarketing/        App Store copy, source screenshots, and generator
zhuzhiliao/               Website pages and screenshot assets
Bamboo CicadaTests/       Unit tests
Bamboo CicadaUITests/     UI tests
```

## Rigid-Rope Motion Model

The toy is modeled as a small ball on the phone screen plane, constrained by a rigid rope to a fixed anchor. The rope length never stretches or projects shorter. Radial force is consumed by the rope constraint; only tangential force changes angular velocity.

![Rigid-rope constraint diagram](docs/assets/physics-rigid-rope.svg)

Frame update:

![Frame physics update flow](docs/assets/physics-frame-pipeline.svg)

### 1. Input Mapping

- `CMDeviceMotion.gravity` represents the gravity direction in device coordinates. It is the main source of slow, natural hanging motion.
- `CMDeviceMotion.userAcceleration` represents linear acceleration from hand motion. It is the main source of fast spin-up.
- The controller keeps smoothed `smoothedGravityX/Y` and `smoothedAccelerationX/Y` values so sensor spikes do not directly cause visual stutter.

In screen coordinates, `x+` points right and `y+` points down:

```text
gravityForce     = ( gravity.x, -gravity.y )
inertialForce    = ( -userAcceleration.x, userAcceleration.y )
tablePlaneForce  = gravityForce * gravityScale
                 + inertialForce * accelerationScale
```

`inertialForce` uses reversed acceleration to mimic the relative throw of a small ball when the phone-plane "table" moves suddenly.

### 2. Rigid-Rope Constraint

The cicada position is driven only by a continuous `orbitAngle`:

```text
screenAngle = 90 deg + orbitAngle
position.x  = anchor.x + cos(screenAngle) * ropeLength
position.y  = anchor.y + sin(screenAngle) * ropeLength
```

Because `ropeLength` is fixed, the visible rope always connects the red bead to the cicada attachment point. The physical model projects the screen-plane force onto the circular tangent:

```text
tangent = ( -cos(orbitAngle), -sin(orbitAngle) )
tangentialForce = dot(tablePlaneForce, tangent)
angularVelocity += tangentialForce * ropeGravityResponse
```

`orbitAngle` is accumulated continuously instead of normalized to `0...360` each frame, avoiding a visible `359 -> 0` jump during wide swings.

### 3. Low-Speed Gravity and High-Speed Spin

At low speed, `highSpeedBlendRatio` stays near `0`, gravity participates almost fully, and the cicada hangs and swings naturally like a small object on a rigid rope.

At high speed, `highSpeedBlendRatio` eases toward `1`:

- Gravity influence drops to `highSpeedMinimumGravityInfluence`, so fast rotation is not constantly dragged down.
- Acceleration influence is boosted by `highSpeedAccelerationBoost`.
- High-speed motion no longer samples acceleration or crosses zero to choose direction; acceleration only adds energy along an existing direction, while `highSpeedSpinDirection` inherits angular velocity and releases near zero speed.
- `applyHighSpeedSpinDrive` eases the existing angular velocity toward the target spin speed without resetting inertia.
- `highSpeedBlendKickstartRatio` gives the first fast shake an initial high-speed blend so spin-up does not crawl from zero.

```text
low speed:  gravityScale ~= 1.0        accelerationScale ~= ropeAccelerationResponse
high speed: gravityScale reduced       accelerationScale boosted
```

### 4. Latency and Smoothness

The motion model uses several safeguards to keep SwiftUI frames smooth:

- `motionInputSmoothing`: smooths gravity and acceleration input.
- `maximumAngularVelocityDeltaPerFrame`: clamps per-frame angular velocity changes.
- `ropeAngularDamping`: retains part of angular velocity each frame for natural decay.
- Audio play, stop, and prewarm work runs on a separate audio queue so `AVAudioPlayer.play()` / `stop()` does not block the SwiftUI frame callback.
- Each frame caps audio triggers with `maximumAudioPulsesPerFrame`, preventing extreme spins from scheduling too many audio events at once.

![Audio and haptic latency path](docs/assets/physics-latency-timeline.svg)

### 5. Audio and Friction Haptics

Audio and haptics are split into two channels:

- Audio pulses are driven only by actual angular speed. Low-speed gravity swings also accumulate audio phase; faster motion produces denser pulses and a higher playback rate.
- Friction haptics follow actual angular travel through `frictionHapticPhaseDegrees`, so both gravity swings and fast spins produce tactile feedback.
- `frictionHapticMinimumIntensity` keeps slow gravity swings perceptible.
- `frictionHapticSpeedMultiplier` increases haptic strength with speed.

## Tuning

Most interaction feel lives in `Bamboo Cicada/Configuration/CicadaTuning.swift`.

- `maximumSpinVelocityDegreesPerFrame`: maximum rigid-rope angular speed.
- `ropeGravityResponse`: gravity-to-angular-velocity response.
- `ropeAccelerationResponse`: linear-acceleration-to-inertial-force response.
- `highSpeedBlendStartIntensity` / `highSpeedBlendEndIntensity`: low-speed to high-speed blend range.
- `highSpeedMinimumGravityInfluence`: minimum gravity influence retained at high speed.
- `highSpeedAccelerationBoost`: acceleration boost at high speed.
- `highSpeedSpinDriveResponse`: target spin speed response.
- `motionInputSmoothing`: low-pass smoothing for gravity and acceleration.
- `maximumAngularVelocityDeltaPerFrame`: per-frame angular velocity delta clamp.
- `ropeAngularDamping`: angular velocity retention per frame.
- `ropeAudioVelocityDeadzone`: very-low-speed audio noise gate; it filters stillness jitter without blocking slow swing audio.
- `audioPhaseDegrees`: audio pulse phase interval.
- `frictionHapticPhaseDegrees`: friction haptic phase interval.
- `frictionHapticMinimumIntensity` / `frictionHapticSpeedMultiplier`: friction haptic intensity mapping.
- `hapticMinimumInterval`: minimum spacing between haptic pulses.
- `audioPrewarmPlayerCount`: number of players prepared at startup; prewarm does not play audio, keeping cold launch silent.

## Marketing Assets

`AppStoreMarketing/` contains App Store copy, source screenshots, generated upload screenshots, and contact sheets. See `AppStoreMarketing/README.md` for details.

## License

MIT License. See `LICENSE`.

---
title: Core Haptics
source: https://developer.apple.com/documentation/corehaptics
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/index/corehaptics
timestamp: 2026-05-10T06:22:46.886Z
---

**Navigation:** [Core Haptics](/documentation/corehaptics)

## Essentials

- [Preparing your app to play haptics](/documentation/corehaptics/preparing-your-app-to-play-haptics)
- [Playing a single-tap haptic pattern](/documentation/corehaptics/playing-a-single-tap-haptic-pattern)
- [CHHapticEngine](/documentation/corehaptics/chhapticengine)
### Initializing a Haptic Engine

- [init() throws](/documentation/corehaptics/chhapticengine/init())
- [init(audioSession: AVAudioSession?) throws](/documentation/corehaptics/chhapticengine/init(audiosession:))
### Starting and Stopping the Haptic Engine

- [func start() throws](/documentation/corehaptics/chhapticengine/start())
- [func start(completionHandler: (((any Error)?) -> Void)?)](/documentation/corehaptics/chhapticengine/start(completionhandler:))
- [func stop(completionHandler: (((any Error)?) -> Void)?)](/documentation/corehaptics/chhapticengine/stop(completionhandler:))
- [CHHapticEngine.CompletionHandler](/documentation/corehaptics/chhapticengine/completionhandler)
### Creating Haptic Pattern Players

- [func makePlayer(with: CHHapticPattern) throws -> any CHHapticPatternPlayer](/documentation/corehaptics/chhapticengine/makeplayer(with:))
- [func makeAdvancedPlayer(with: CHHapticPattern) throws -> any CHHapticAdvancedPatternPlayer](/documentation/corehaptics/chhapticengine/makeadvancedplayer(with:))
### Modifying Playback Properties

- [var playsAudioOnly: Bool](/documentation/corehaptics/chhapticengine/playsaudioonly)
- [var playsHapticsOnly: Bool](/documentation/corehaptics/chhapticengine/playshapticsonly)
- [var isMutedForAudio: Bool](/documentation/corehaptics/chhapticengine/ismutedforaudio)
- [var isMutedForHaptics: Bool](/documentation/corehaptics/chhapticengine/ismutedforhaptics)
### Playing a Pattern

- [func playPattern(from: URL) throws](/documentation/corehaptics/chhapticengine/playpattern(from:)-6m9m5)
- [func playPattern(from: Data) throws](/documentation/corehaptics/chhapticengine/playpattern(from:)-7u8se)
### Registering Audio Resources

- [func registerAudioResource(URL, options: [AnyHashable : Any]) throws -> CHHapticAudioResourceID](/documentation/corehaptics/chhapticengine/registeraudioresource(_:options:))
#### Audio Resource Keys

- [let CHHapticAudioResourceKeyLoopEnabled: String](/documentation/corehaptics/chhapticaudioresourcekeyloopenabled)
- [let CHHapticAudioResourceKeyUseVolumeEnvelope: String](/documentation/corehaptics/chhapticaudioresourcekeyusevolumeenvelope)
- [CHHapticAudioResourceKey](/documentation/corehaptics/chhapticaudioresourcekey)

- [func unregisterAudioResource(CHHapticAudioResourceID) throws](/documentation/corehaptics/chhapticengine/unregisteraudioresource(_:))
- [CHHapticAudioResourceID](/documentation/corehaptics/chhapticaudioresourceid)
### Monitoring Finished Playback

- [func notifyWhenPlayersFinished(finishedHandler: CHHapticEngine.FinishedHandler)](/documentation/corehaptics/chhapticengine/notifywhenplayersfinished(finishedhandler:))
- [CHHapticEngine.FinishedHandler](/documentation/corehaptics/chhapticengine/finishedhandler)
- [CHHapticEngine.FinishedAction](/documentation/corehaptics/chhapticengine/finishedaction)
#### Finished Actions

- [case leaveEngineRunning](/documentation/corehaptics/chhapticengine/finishedaction/leaveenginerunning)
- [case stopEngine](/documentation/corehaptics/chhapticengine/finishedaction/stopengine)
#### Initializers

- [init?(rawValue: Int)](/documentation/corehaptics/chhapticengine/finishedaction/init(rawvalue:))

### Handling Haptic Engine Resets

- [var resetHandler: CHHapticEngine.ResetHandler](/documentation/corehaptics/chhapticengine/resethandler-swift.property)
- [CHHapticEngine.ResetHandler](/documentation/corehaptics/chhapticengine/resethandler-swift.typealias)
### Handling Haptic Engine Stoppages

- [var stoppedHandler: CHHapticEngine.StoppedHandler](/documentation/corehaptics/chhapticengine/stoppedhandler-swift.property)
- [CHHapticEngine.StoppedHandler](/documentation/corehaptics/chhapticengine/stoppedhandler-swift.typealias)
- [CHHapticEngine.StoppedReason](/documentation/corehaptics/chhapticengine/stoppedreason)
#### Stopped Reasons

- [case audioSessionInterrupt](/documentation/corehaptics/chhapticengine/stoppedreason/audiosessioninterrupt)
- [case applicationSuspended](/documentation/corehaptics/chhapticengine/stoppedreason/applicationsuspended)
- [case engineDestroyed](/documentation/corehaptics/chhapticengine/stoppedreason/enginedestroyed)
- [case gameControllerDisconnect](/documentation/corehaptics/chhapticengine/stoppedreason/gamecontrollerdisconnect)
- [case idleTimeout](/documentation/corehaptics/chhapticengine/stoppedreason/idletimeout)
- [case notifyWhenFinished](/documentation/corehaptics/chhapticengine/stoppedreason/notifywhenfinished)
- [case systemError](/documentation/corehaptics/chhapticengine/stoppedreason/systemerror)
#### Initializers

- [init?(rawValue: Int)](/documentation/corehaptics/chhapticengine/stoppedreason/init(rawvalue:))

### Getting the Current Media Time

- [var currentTime: TimeInterval](/documentation/corehaptics/chhapticengine/currenttime)
- [var CHHapticTimeImmediate: TimeInterval](/documentation/corehaptics/chhaptictimeimmediate)
### Querying System Capabilities

- [class func capabilitiesForHardware() -> any CHHapticDeviceCapability](/documentation/corehaptics/chhapticengine/capabilitiesforhardware())
- [CHHapticDeviceCapability](/documentation/corehaptics/chhapticdevicecapability)
#### Determining Support for Haptics

- [var supportsAudio: Bool](/documentation/corehaptics/chhapticdevicecapability/supportsaudio)
- [var supportsHaptics: Bool](/documentation/corehaptics/chhapticdevicecapability/supportshaptics)
#### Determining Supported Parameters

- [func attributes(forDynamicParameter: CHHapticDynamicParameter.ID) throws -> any CHHapticParameterAttributes](/documentation/corehaptics/chhapticdevicecapability/attributes(fordynamicparameter:))
- [func attributes(forEventParameter: CHHapticEvent.ParameterID, eventType: CHHapticEvent.EventType) throws -> any CHHapticParameterAttributes](/documentation/corehaptics/chhapticdevicecapability/attributes(foreventparameter:eventtype:))

- [CHHapticParameterAttributes](/documentation/corehaptics/chhapticparameterattributes)
#### Parameter Attributes

- [var defaultValue: Float](/documentation/corehaptics/chhapticparameterattributes/defaultvalue)
- [var minValue: Float](/documentation/corehaptics/chhapticparameterattributes/minvalue)
- [var maxValue: Float](/documentation/corehaptics/chhapticparameterattributes/maxvalue)

- [func attributes(forDynamicParameter: CHHapticDynamicParameter.ID) throws -> any CHHapticParameterAttributes](/documentation/corehaptics/chhapticdevicecapability/attributes(fordynamicparameter:))
### Managing Power

- [var isAutoShutdownEnabled: Bool](/documentation/corehaptics/chhapticengine/isautoshutdownenabled)
### Initializers

- [init(andReturnError: ()) throws](/documentation/corehaptics/chhapticengine/init(andreturnerror:))
### Instance Properties

- [var intendedSpatialExperience: any SpatialAudioExperience](/documentation/corehaptics/chhapticengine/intendedspatialexperience-55ca0)

- [CHHapticPattern](/documentation/corehaptics/chhapticpattern)
### Creating a Haptic Pattern

- [init(contentsOf: URL) throws](/documentation/corehaptics/chhapticpattern/init(contentsof:))
- [init(events: [CHHapticEvent], parameterCurves: [CHHapticParameterCurve]) throws](/documentation/corehaptics/chhapticpattern/init(events:parametercurves:))
- [init(events: [CHHapticEvent], parameters: [CHHapticDynamicParameter]) throws](/documentation/corehaptics/chhapticpattern/init(events:parameters:))
- [init(dictionary: [CHHapticPattern.Key : Any]) throws](/documentation/corehaptics/chhapticpattern/init(dictionary:))
- [CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key)
#### Haptic Pattern Keys

- [static let event: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/event)
- [static let eventDuration: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/eventduration)
- [static let eventParameters: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/eventparameters)
- [static let eventType: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/eventtype)
- [static let eventWaveformLoopEnabled: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/eventwaveformloopenabled)
- [static let eventWaveformPath: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/eventwaveformpath)
- [static let eventWaveformUseVolumeEnvelope: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/eventwaveformusevolumeenvelope)
- [static let parameter: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/parameter)
- [static let parameterCurve: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/parametercurve)
- [static let parameterCurveControlPoints: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/parametercurvecontrolpoints)
- [static let parameterID: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/parameterid)
- [static let parameterValue: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/parametervalue)
- [static let pattern: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/pattern)
- [static let time: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/time)
- [static let version: CHHapticPattern.Key](/documentation/corehaptics/chhapticpattern/key/version)
#### Initializers

- [init(rawValue: String)](/documentation/corehaptics/chhapticpattern/key/init(rawvalue:))

### Retrieving Haptic Pattern Duration

- [var duration: TimeInterval](/documentation/corehaptics/chhapticpattern/duration)
### Exporting a Haptic Pattern

- [func exportDictionary() throws -> [CHHapticPattern.Key : Any]](/documentation/corehaptics/chhapticpattern/exportdictionary())
### Initializers

- [init(contentsOfURL: URL) throws](/documentation/corehaptics/chhapticpattern/init(contentsofurl:))

- [CHHapticPatternPlayer](/documentation/corehaptics/chhapticpatternplayer)
### Starting and Stopping Playback

- [func start(atTime: TimeInterval) throws](/documentation/corehaptics/chhapticpatternplayer/start(attime:))
- [func stop(atTime: TimeInterval) throws](/documentation/corehaptics/chhapticpatternplayer/stop(attime:))
- [func cancel() throws](/documentation/corehaptics/chhapticpatternplayer/cancel())
### Sending Parameters to a Haptic

- [func sendParameters([CHHapticDynamicParameter], atTime: TimeInterval) throws](/documentation/corehaptics/chhapticpatternplayer/sendparameters(_:attime:))
- [func scheduleParameterCurve(CHHapticParameterCurve, atTime: TimeInterval) throws](/documentation/corehaptics/chhapticpatternplayer/scheduleparametercurve(_:attime:))
### Silencing Haptic Playback

- [var isMuted: Bool](/documentation/corehaptics/chhapticpatternplayer/ismuted)

- [CHHapticAdvancedPatternPlayer](/documentation/corehaptics/chhapticadvancedpatternplayer)
### Setting Playback Properties

- [var loopEnabled: Bool](/documentation/corehaptics/chhapticadvancedpatternplayer/loopenabled)
- [var loopEnd: TimeInterval](/documentation/corehaptics/chhapticadvancedpatternplayer/loopend)
- [var playbackRate: Float](/documentation/corehaptics/chhapticadvancedpatternplayer/playbackrate)
- [var completionHandler: CHHapticAdvancedPatternPlayerCompletionHandler](/documentation/corehaptics/chhapticadvancedpatternplayer/completionhandler)
- [CHHapticAdvancedPatternPlayerCompletionHandler](/documentation/corehaptics/chhapticadvancedpatternplayercompletionhandler)
### Controlling Playback

- [func pause(atTime: TimeInterval) throws](/documentation/corehaptics/chhapticadvancedpatternplayer/pause(attime:))
- [func resume(atTime: TimeInterval) throws](/documentation/corehaptics/chhapticadvancedpatternplayer/resume(attime:))
- [func seek(toOffset: TimeInterval) throws](/documentation/corehaptics/chhapticadvancedpatternplayer/seek(tooffset:))
### Silencing Haptic Playback

- [var isMuted: Bool](/documentation/corehaptics/chhapticadvancedpatternplayer/ismuted)

## Programmatic haptics

- [Delivering Rich App Experiences with Haptics](/documentation/corehaptics/delivering-rich-app-experiences-with-haptics)
- [Playing Collision-Based Haptic Patterns](/documentation/corehaptics/playing-collision-based-haptic-patterns)
- [Updating Continuous and Transient Haptic Parameters in Real Time](/documentation/corehaptics/updating-continuous-and-transient-haptic-parameters-in-real-time)
- [CHHapticEvent](/documentation/corehaptics/chhapticevent)
### Categorizing Haptic Events

- [var type: CHHapticEvent.EventType](/documentation/corehaptics/chhapticevent/type)
- [CHHapticEvent.EventType](/documentation/corehaptics/chhapticevent/eventtype)
#### Specifying a Type

- [init(rawValue: String)](/documentation/corehaptics/chhapticevent/eventtype/init(rawvalue:))
#### Enumerating Haptic Types

- [static let audioContinuous: CHHapticEvent.EventType](/documentation/corehaptics/chhapticevent/eventtype/audiocontinuous)
- [static let audioCustom: CHHapticEvent.EventType](/documentation/corehaptics/chhapticevent/eventtype/audiocustom)
- [static let hapticTransient: CHHapticEvent.EventType](/documentation/corehaptics/chhapticevent/eventtype/haptictransient)
- [static let hapticContinuous: CHHapticEvent.EventType](/documentation/corehaptics/chhapticevent/eventtype/hapticcontinuous)

### Creating Haptic Events

- [init(audioResourceID: CHHapticAudioResourceID, parameters: [CHHapticEventParameter], relativeTime: TimeInterval)](/documentation/corehaptics/chhapticevent/init(audioresourceid:parameters:relativetime:))
- [init(audioResourceID: CHHapticAudioResourceID, parameters: [CHHapticEventParameter], relativeTime: TimeInterval, duration: TimeInterval)](/documentation/corehaptics/chhapticevent/init(audioresourceid:parameters:relativetime:duration:))
- [init(eventType: CHHapticEvent.EventType, parameters: [CHHapticEventParameter], relativeTime: TimeInterval)](/documentation/corehaptics/chhapticevent/init(eventtype:parameters:relativetime:))
- [init(eventType: CHHapticEvent.EventType, parameters: [CHHapticEventParameter], relativeTime: TimeInterval, duration: TimeInterval)](/documentation/corehaptics/chhapticevent/init(eventtype:parameters:relativetime:duration:))
### Configuring Haptic Events

- [var eventParameters: [CHHapticEventParameter]](/documentation/corehaptics/chhapticevent/eventparameters)
- [CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid)
#### Haptic Event Parameter IDs

- [static let hapticIntensity: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/hapticintensity)
- [static let hapticSharpness: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/hapticsharpness)
- [static let attackTime: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/attacktime)
- [static let decayTime: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/decaytime)
- [static let releaseTime: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/releasetime)
- [static let sustained: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/sustained)
#### Audio Event Parameter IDs

- [static let audioVolume: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiovolume)
- [static let audioPan: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiopan)
- [static let audioPitch: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiopitch)
- [static let audioBrightness: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiobrightness)
#### Swift Initializers

- [init(rawValue: String)](/documentation/corehaptics/chhapticevent/parameterid/init(rawvalue:))

- [var relativeTime: TimeInterval](/documentation/corehaptics/chhapticevent/relativetime)
- [var duration: TimeInterval](/documentation/corehaptics/chhapticevent/duration)

- [CHHapticEventParameter](/documentation/corehaptics/chhapticeventparameter)
### Creating an Event Parameter

- [init(parameterID: CHHapticEvent.ParameterID, value: Float)](/documentation/corehaptics/chhapticeventparameter/init(parameterid:value:))
- [CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid)
#### Haptic Event Parameter IDs

- [static let hapticIntensity: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/hapticintensity)
- [static let hapticSharpness: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/hapticsharpness)
- [static let attackTime: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/attacktime)
- [static let decayTime: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/decaytime)
- [static let releaseTime: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/releasetime)
- [static let sustained: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/sustained)
#### Audio Event Parameter IDs

- [static let audioVolume: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiovolume)
- [static let audioPan: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiopan)
- [static let audioPitch: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiopitch)
- [static let audioBrightness: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticevent/parameterid/audiobrightness)
#### Swift Initializers

- [init(rawValue: String)](/documentation/corehaptics/chhapticevent/parameterid/init(rawvalue:))

### Specifying an Event Parameter’s Value

- [var parameterID: CHHapticEvent.ParameterID](/documentation/corehaptics/chhapticeventparameter/parameterid)
- [var value: Float](/documentation/corehaptics/chhapticeventparameter/value)

- [CHHapticDynamicParameter](/documentation/corehaptics/chhapticdynamicparameter)
### Creating a Dynamic Parameter

- [init(parameterID: CHHapticDynamicParameter.ID, value: Float, relativeTime: TimeInterval)](/documentation/corehaptics/chhapticdynamicparameter/init(parameterid:value:relativetime:))
- [CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id)
#### Haptic Dynamic Parameter IDs

- [static let hapticIntensityControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/hapticintensitycontrol)
- [static let hapticSharpnessControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/hapticsharpnesscontrol)
- [static let hapticAttackTimeControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/hapticattacktimecontrol)
- [static let hapticDecayTimeControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/hapticdecaytimecontrol)
- [static let hapticReleaseTimeControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/hapticreleasetimecontrol)
#### Audio Dynamic Parameter IDs

- [static let audioBrightnessControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/audiobrightnesscontrol)
- [static let audioVolumeControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/audiovolumecontrol)
- [static let audioPanControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/audiopancontrol)
- [static let audioPitchControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/audiopitchcontrol)
- [static let audioAttackTimeControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/audioattacktimecontrol)
- [static let audioDecayTimeControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/audiodecaytimecontrol)
- [static let audioReleaseTimeControl: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/id/audioreleasetimecontrol)
#### Swift Initializers

- [init(rawValue: String)](/documentation/corehaptics/chhapticdynamicparameter/id/init(rawvalue:))

### Specifying a Dynamic Parameter’s Value

- [var parameterID: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticdynamicparameter/parameterid)
- [var relativeTime: TimeInterval](/documentation/corehaptics/chhapticdynamicparameter/relativetime)
- [var value: Float](/documentation/corehaptics/chhapticdynamicparameter/value)

- [CHHapticParameterCurve](/documentation/corehaptics/chhapticparametercurve)
### Creating a Curve

- [init(parameterID: CHHapticDynamicParameter.ID, controlPoints: [CHHapticParameterCurve.ControlPoint], relativeTime: TimeInterval)](/documentation/corehaptics/chhapticparametercurve/init(parameterid:controlpoints:relativetime:))
- [CHHapticParameterCurve.ControlPoint](/documentation/corehaptics/chhapticparametercurve/controlpoint)
#### Creating a Control Point

- [init(relativeTime: TimeInterval, value: Float)](/documentation/corehaptics/chhapticparametercurve/controlpoint/init(relativetime:value:))
#### Specifying Control Point Coordinates

- [var relativeTime: TimeInterval](/documentation/corehaptics/chhapticparametercurve/controlpoint/relativetime)
- [var value: Float](/documentation/corehaptics/chhapticparametercurve/controlpoint/value)

### Describing the Curve

- [var controlPoints: [CHHapticParameterCurve.ControlPoint]](/documentation/corehaptics/chhapticparametercurve/controlpoints)
- [var parameterID: CHHapticDynamicParameter.ID](/documentation/corehaptics/chhapticparametercurve/parameterid)
- [var relativeTime: TimeInterval](/documentation/corehaptics/chhapticparametercurve/relativetime)

## File-based haptics

- [Playing a Custom Haptic Pattern from a File](/documentation/corehaptics/playing-a-custom-haptic-pattern-from-a-file)
- [Representing haptic patterns in AHAP files](/documentation/corehaptics/representing-haptic-patterns-in-ahap-files)
## Game controller haptics

- [Playing Haptics on Game Controllers](/documentation/corehaptics/playing-haptics-on-game-controllers)
## Haptic errors

- [let CoreHapticsErrorDomain: String](/documentation/corehaptics/corehapticserrordomain)
- [CHHapticError](/documentation/corehaptics/chhapticerror)
### Inspecting an Error

- [CHHapticError.Code](/documentation/corehaptics/chhapticerror/code)
#### Error Codes

- [case badEventEntry](/documentation/corehaptics/chhapticerror/code/badevententry)
- [case badParameterEntry](/documentation/corehaptics/chhapticerror/code/badparameterentry)
- [case engineNotRunning](/documentation/corehaptics/chhapticerror/code/enginenotrunning)
- [case engineStartTimeout](/documentation/corehaptics/chhapticerror/code/enginestarttimeout)
- [case fileNotFound](/documentation/corehaptics/chhapticerror/code/filenotfound)
- [case insufficientPower](/documentation/corehaptics/chhapticerror/code/insufficientpower)
- [case invalidAudioResource](/documentation/corehaptics/chhapticerror/code/invalidaudioresource)
- [case invalidAudioSession](/documentation/corehaptics/chhapticerror/code/invalidaudiosession)
- [case invalidEngineParameter](/documentation/corehaptics/chhapticerror/code/invalidengineparameter)
- [case invalidEventDuration](/documentation/corehaptics/chhapticerror/code/invalideventduration)
- [case invalidEventTime](/documentation/corehaptics/chhapticerror/code/invalideventtime)
- [case invalidEventType](/documentation/corehaptics/chhapticerror/code/invalideventtype)
- [case invalidParameterType](/documentation/corehaptics/chhapticerror/code/invalidparametertype)
- [case invalidPatternData](/documentation/corehaptics/chhapticerror/code/invalidpatterndata)
- [case invalidPatternDictionary](/documentation/corehaptics/chhapticerror/code/invalidpatterndictionary)
- [case invalidPatternPlayer](/documentation/corehaptics/chhapticerror/code/invalidpatternplayer)
- [case invalidTime](/documentation/corehaptics/chhapticerror/code/invalidtime)
- [case memoryError](/documentation/corehaptics/chhapticerror/code/memoryerror)
- [case notSupported](/documentation/corehaptics/chhapticerror/code/notsupported)
- [case operationNotPermitted](/documentation/corehaptics/chhapticerror/code/operationnotpermitted)
- [case resourceNotAvailable](/documentation/corehaptics/chhapticerror/code/resourcenotavailable)
- [case serverInterrupted](/documentation/corehaptics/chhapticerror/code/serverinterrupted)
- [case serverInitFailed](/documentation/corehaptics/chhapticerror/code/serverinitfailed)
- [case unknownError](/documentation/corehaptics/chhapticerror/code/unknownerror)
#### Initializers

- [init?(rawValue: Int)](/documentation/corehaptics/chhapticerror/code/init(rawvalue:))

- [Error Constants](/documentation/corehaptics/error-constants)
#### Error Code Constants

- [static var badEventEntry: CHHapticError.Code](/documentation/corehaptics/chhapticerror/badevententry)
- [static var badParameterEntry: CHHapticError.Code](/documentation/corehaptics/chhapticerror/badparameterentry)
- [static var engineNotRunning: CHHapticError.Code](/documentation/corehaptics/chhapticerror/enginenotrunning)
- [static var engineStartTimeout: CHHapticError.Code](/documentation/corehaptics/chhapticerror/enginestarttimeout)
- [static var fileNotFound: CHHapticError.Code](/documentation/corehaptics/chhapticerror/filenotfound)
- [static var insufficientPower: CHHapticError.Code](/documentation/corehaptics/chhapticerror/insufficientpower)
- [static var invalidAudioResource: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidaudioresource)
- [static var invalidAudioSession: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidaudiosession)
- [static var invalidEngineParameter: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidengineparameter)
- [static var invalidEventDuration: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalideventduration)
- [static var invalidEventTime: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalideventtime)
- [static var invalidEventType: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalideventtype)
- [static var invalidParameterType: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidparametertype)
- [static var invalidPatternData: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidpatterndata)
- [static var invalidPatternDictionary: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidpatterndictionary)
- [static var invalidPatternPlayer: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidpatternplayer)
- [static var invalidTime: CHHapticError.Code](/documentation/corehaptics/chhapticerror/invalidtime)
- [static var memoryError: CHHapticError.Code](/documentation/corehaptics/chhapticerror/memoryerror)
- [static var notSupported: CHHapticError.Code](/documentation/corehaptics/chhapticerror/notsupported)
- [static var operationNotPermitted: CHHapticError.Code](/documentation/corehaptics/chhapticerror/operationnotpermitted)
- [static var resourceNotAvailable: CHHapticError.Code](/documentation/corehaptics/chhapticerror/resourcenotavailable)
- [static var serverInterrupted: CHHapticError.Code](/documentation/corehaptics/chhapticerror/serverinterrupted)
- [static var serverInitFailed: CHHapticError.Code](/documentation/corehaptics/chhapticerror/serverinitfailed)
- [static var unknownError: CHHapticError.Code](/documentation/corehaptics/chhapticerror/unknownerror)

### Type Properties

- [static var errorDomain: String](/documentation/corehaptics/chhapticerror/errordomain)

- [CHHapticError.Code](/documentation/corehaptics/chhapticerror/code)
### Error Codes

- [case badEventEntry](/documentation/corehaptics/chhapticerror/code/badevententry)
- [case badParameterEntry](/documentation/corehaptics/chhapticerror/code/badparameterentry)
- [case engineNotRunning](/documentation/corehaptics/chhapticerror/code/enginenotrunning)
- [case engineStartTimeout](/documentation/corehaptics/chhapticerror/code/enginestarttimeout)
- [case fileNotFound](/documentation/corehaptics/chhapticerror/code/filenotfound)
- [case insufficientPower](/documentation/corehaptics/chhapticerror/code/insufficientpower)
- [case invalidAudioResource](/documentation/corehaptics/chhapticerror/code/invalidaudioresource)
- [case invalidAudioSession](/documentation/corehaptics/chhapticerror/code/invalidaudiosession)
- [case invalidEngineParameter](/documentation/corehaptics/chhapticerror/code/invalidengineparameter)
- [case invalidEventDuration](/documentation/corehaptics/chhapticerror/code/invalideventduration)
- [case invalidEventTime](/documentation/corehaptics/chhapticerror/code/invalideventtime)
- [case invalidEventType](/documentation/corehaptics/chhapticerror/code/invalideventtype)
- [case invalidParameterType](/documentation/corehaptics/chhapticerror/code/invalidparametertype)
- [case invalidPatternData](/documentation/corehaptics/chhapticerror/code/invalidpatterndata)
- [case invalidPatternDictionary](/documentation/corehaptics/chhapticerror/code/invalidpatterndictionary)
- [case invalidPatternPlayer](/documentation/corehaptics/chhapticerror/code/invalidpatternplayer)
- [case invalidTime](/documentation/corehaptics/chhapticerror/code/invalidtime)
- [case memoryError](/documentation/corehaptics/chhapticerror/code/memoryerror)
- [case notSupported](/documentation/corehaptics/chhapticerror/code/notsupported)
- [case operationNotPermitted](/documentation/corehaptics/chhapticerror/code/operationnotpermitted)
- [case resourceNotAvailable](/documentation/corehaptics/chhapticerror/code/resourcenotavailable)
- [case serverInterrupted](/documentation/corehaptics/chhapticerror/code/serverinterrupted)
- [case serverInitFailed](/documentation/corehaptics/chhapticerror/code/serverinitfailed)
- [case unknownError](/documentation/corehaptics/chhapticerror/code/unknownerror)
### Initializers

- [init?(rawValue: Int)](/documentation/corehaptics/chhapticerror/code/init(rawvalue:))

## Variables

- [let CHHapticAudioResourceKeyLoopEnabled: String](/documentation/corehaptics/chhapticaudioresourcekeyloopenabled)
- [let CHHapticAudioResourceKeyUseVolumeEnvelope: String](/documentation/corehaptics/chhapticaudioresourcekeyusevolumeenvelope)
## Type Aliases

- [CHHapticAudioResourceKey](/documentation/corehaptics/chhapticaudioresourcekey)

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*

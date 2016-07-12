VideoToolboxPlus
================

VideoToolboxPlus is a collection of VideoToolbox helpers and extensions. It also adds some Swift-y syntax to the VideoToolbox API.

Getting Started
===============

Simply add the VideoToolboxPlus.swift file to your project.

Usage
=====

Turn code like this:

```Swift
var session : VTCompressionSession? = nil

let status = VTCompressionSessionCreate( nil, 
  width, 
  height, 
  kCMVideoCodecType_H264, 
  nil, 
  attributes, 
  nil, 
  callback, 
  unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self), 
  &session ) 

var properties: [NSString: NSObject] = [
    kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
    kVTCompressionPropertyKey_ProfileLevel: profileLevel,
    kVTCompressionPropertyKey_AverageBitRate: bitrate,
    kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration: maxKeyFrameIntervalDuration
  ]
        
VTSessionSetProperties(_session!, properties)
VTCompressionSessionPrepareToEncodeFrames(_session!)

let imageBuffer : CVImageBuffer! = CMSampleBufferGetImageBuffer(sampleBuffer)

let status = VTCompressionSessionEncodeFrame(session, 
  imageBuffer, 
  presentationTimeStamp, 
  presentationDuration, 
  nil, 
  nil, 
  &flags)

if status == noErr {
  // handle error
} else {
  // handle success
}
```

Into:

```Swift
var session : VTCompressionSession! = VTCompressionSession.new(width: width, 
  height: height, 
  codec: kCMVideoCodecType_H264, 
  callback: callback)

session.isRealtime = true
session.profile = profileLevel
session.averageBitrate = bitrate
session.maxKeyframeIntervalDuration = maxKeyframeIntervalDuration
        
session.prepare()

do {
  try session.encode(buffer: sampleBuffer)
} catch {
  // handle error
}
// handle success
```

License
=======

VideoToolboxPlus is released under the MIT license.

Comments or Questions?
======================

Any questions or comments should be made into issues, or pull requests if you want to write some code.

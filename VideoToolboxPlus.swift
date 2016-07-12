//
//  VideoToolboxPlus.swift
//
//  Created by John Manos on 7/1/16.
//  Copyright © 2016 John Manos. All rights reserved.
//

import Foundation
import VideoToolbox

/**
 VideoToolboxError
 
 - propertyNotSupported: The videotoolbox session doesnt support the property.
 - encodeError: The session cant encode the frame.
 = errorCreatingImageBuffer: Couldnt convert cmsamplebuffer to pixel buffer.
 */
public enum VideoToolboxError : ErrorProtocol {
    case propertyNotSupported
    case encodeError
    case errorCreatingImageBuffer
}

extension VTCompressionSession {
    /// The number of pending frames in the compression session.
    public var pendingFrames : Int? {
        guard let frames = try? get(kVTCompressionPropertyKey_NumberOfPendingFrames) as? NSNumber else { return nil }
        return frames?.intValue
    }
    /// The maximum interval between key frames, also known as the key frame rate.
    public var maxKeyframeInterval : Int? {
        get {
            guard let interval = try? get(kVTCompressionPropertyKey_MaxKeyFrameInterval) as? NSNumber else { return nil }
            return interval?.intValue
        }
        set {
            guard let interval = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_MaxKeyFrameInterval, value: NSNumber(value:  interval))
        }
    }
    /// The maximum duration from one key frame to the next in seconds.
    public var maxKeyframeIntervalDuration : TimeInterval? {
        get {
            guard let duration = try? get(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration) as? NSNumber else { return nil }
            return duration?.doubleValue
        }
        set {
            guard let duration = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: NSNumber(value: duration))
        }
    }
    /// Enables frame reordering.
    public var frameReordering : Bool? {
        get {
            guard let allow = try? get(kVTCompressionPropertyKey_AllowFrameReordering) as? NSNumber else { return nil }
            return allow?.boolValue
        }
        set {
            guard let allow = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_AllowFrameReordering, value: NSNumber(value: allow))
        }
    }
    /// The long-term desired average bit rate in bits per second.
    public var averageBitrate : Int32? {
        get {
            guard let avg = try? get(kVTCompressionPropertyKey_AverageBitRate) as? NSNumber else { return nil }
            return avg?.int32Value
        }
        set {
            guard let avg = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_AverageBitRate, value: NSNumber(value: avg))
        }
    }
    /// Specifies the profile and level for the encoded bitstream.
    public var profile : CFString? {
        get {
            guard let profile = try? get(kVTCompressionPropertyKey_ProfileLevel) as! CFString else { return nil }
            return profile
        }
        set {
            guard let profile = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_ProfileLevel, value: profile)
        }
    }
    /// The entropy encoding mode for H.264 compression.
    public var entropyMode : CFString? {
        get {
            guard let mode = try? get(kVTCompressionPropertyKey_H264EntropyMode) as! CFString else { return nil }
            return mode
        }
        set {
            guard let mode = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_H264EntropyMode, value: mode)
        }
    }
    /// Hints the video encoder that compression is, or is not, being performed in real time.
    public var isRealtime : Bool? {
        get {
            guard let real = try? get(kVTCompressionPropertyKey_RealTime) as? NSNumber else { return nil }
            return real?.boolValue
        }
        set {
            guard let realtime = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_RealTime, value: NSNumber(value: realtime))
        }
    }
    /// The desired compression quality.
    public var quality : Float? {
        get {
            guard let quality = try? get(kVTCompressionPropertyKey_Quality) as? NSNumber else { return nil }
            return quality?.floatValue
        }
        set {
            guard let quality = newValue else { return }
            let _ = try? set(kVTCompressionPropertyKey_Quality, value: NSNumber(value: quality))
        }
    }
    /**
     Get the specific property of a VideoToolbox Session.
     
     - Parameter property: The CFString name of the desired property.
     
     - Throws: 'VideoToolboxError.propertyNotSupported' if the property cant be read.
     
     - Returns: An object that is read from the session.
     */
    private func get(_ property: CFString) throws -> AnyObject {
        var object : AnyObject = NSNumber(integerLiteral: 0)
        guard VTSessionCopyProperty(self, property, nil, &object) == noErr else {
            throw VideoToolboxError.propertyNotSupported
        }
        return object
    }
    /**
     Set the specific property of a VideoToolbox Session.
     
     - Parameter property: The CFString name of the desired property.
     - Parameter value: The value to set the session property.
     
     - Throws: 'VideoToolboxError.propertyNotSupported' if the property cant be set.
     */
    private func set(_ property: CFString, value: AnyObject) throws {
        guard VTSessionSetProperty(self, property, value) == noErr else {
            throw VideoToolboxError.propertyNotSupported
        }
    }
    /// Prepares the VideoToolbox Session for encoding.
    public func prepare() {
        VTCompressionSessionPrepareToEncodeFrames(self)
    }
    /**
     Initializes a new compression session with the provided dimmensions, attributes, codec, and callback.
     
     - Parameters:
     - width: The width of the session.
     - height: The height of the session.
     - attributes: The attributes of the input frames.
     - codec: The desired compression codec.
     - callback: The output handler.
     
     - Returns: A session if one was able to be created.
     */
    public static func new(width: Int32, height: Int32, attributes: [NSString:AnyObject]? = nil, codec: CMVideoCodecType, callback: VTCompressionOutputHandler) -> VTCompressionSession? {
        var session : VTCompressionSession? = nil
        let encoderAttributes = attributes ?? [ kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) ]
        guard VTCompressionSessionCreate( nil, width, height, codec, nil, encoderAttributes, nil, nil, nil, &session ) == noErr else {
            return nil
        }
        return session
    }
    /**
     Encode a sample buffer.
     
     - Parameter buffer: The sample buffer to be encoded.
     
     - Throws: 'VideoToolboxError.errorCreatingImageBuffer' if the sample buffer cant be converted.
     - Throws: 'VideoToolboxError.encodeError' if the pixel buffer cant be encoded.
     */
    public func encode( buffer : CMSampleBuffer ) throws {
        guard let image = buffer.imageBuffer else {
            throw VideoToolboxError.errorCreatingImageBuffer
        }
        try encode(buffer: image, presentationTimestamp: buffer.presentationTimeStamp, duration: buffer.duration)
    }
    /**
     Encode a image buffer.
     
     - Parameter buffer: The image buffer to be encoded.
     - Parameter presentationTimestamp: The presentation timestamp of the buffer.
     - Parameter duration: The duration of the buffer.
     
     - Throws: 'VideoToolboxError.encodeError' if the pixel buffer cant be encoded.
     */
    public func encode( buffer: CVImageBuffer, presentationTimestamp: CMTime, duration: CMTime ) throws {
        guard VTCompressionSessionEncodeFrame(self, buffer, presentationTimestamp, duration, nil, nil, nil) == noErr else {
            throw VideoToolboxError.encodeError
        }
    }
}

extension CMSampleBuffer {
    /**
     The sample buffer's attachments array.
     
     - Parameter createIfNecessary: Creates the attachments array if one is not present. Defaults to false.
     
     - Returns: A dictionary whose values are the sample buffer's attachment array.
     */
    public func attachmentsArray(_ createIfNecessary : Bool = false) -> Dictionary<NSObject,AnyObject>? {
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary),
            array = unsafeBitCast(CFArrayGetValueAtIndex(attachmentsArray, 0), to: CFDictionary.self) as Dictionary? else {
                return nil
        }
        
        return array
    }
    /// Whether or not the sample buffer depends on other sample buffers.
    public var dependsOnOthers : Bool {
        get {
            guard let array = attachmentsArray(), result = array[kCMSampleAttachmentKey_DependsOnOthers] as? Bool else {
                return false
            }
            
            return result
        }
        set {
            guard var array = attachmentsArray(true) else { return }
            array[kCMSampleAttachmentKey_DependsOnOthers] = newValue
        }
    }
    /// The sample buffer's media data buffer.
    public var dataBuffer : CMBlockBuffer? {
        get {
            return CMSampleBufferGetDataBuffer(self)
        }
        set {
            guard let dataBuffer = newValue else { return }
            
            CMSampleBufferSetDataBuffer(self, dataBuffer)
        }
    }
    /// The sample buffer's image buffer of media data.
    public var imageBuffer : CVImageBuffer? {
        return CMSampleBufferGetImageBuffer(self)
    }
    /// The duration of the sample buffer.
    public var duration : CMTime {
        return CMSampleBufferGetDuration(self)
    }
    /// The format description of the sample buffer.
    public var formatDescription : CMFormatDescription? {
        return CMSampleBufferGetFormatDescription(self)
    }
    /// The numerically earliest decode timestamp of all the samples in a sample buffer.
    public var decodeTimeStamp : CMTime {
        let decodeTimestamp = CMSampleBufferGetDecodeTimeStamp(self)
        return decodeTimestamp == kCMTimeInvalid ? presentationTimeStamp : decodeTimestamp
    }
    /// The numerically earliest decode time value of all the samples in a sample buffer.
    public var decodeTime : Double {
        let decodeTimestamp:CMTime = self.decodeTimeStamp
        return Double(decodeTimestamp.value) / Double(decodeTimestamp.timescale)
    }
    /// The numerically earliest presentation timestamp of all the samples in a sample buffer.
    public var presentationTimeStamp : CMTime {
        return CMSampleBufferGetPresentationTimeStamp(self)
    }
    /// The numerically earliest presentation time value of all the samples in a sample buffer.
    public var presentationTime : Double {
        let presentationTimeStamp = self.presentationTimeStamp
        return Double(presentationTimeStamp.value) / Double(presentationTimeStamp.timescale)
    }
    /// Whether or not a sample buffer's data is ready.
    public var isDataReady : Bool {
        return CMSampleBufferDataIsReady(self)
    }
    /// The number of media samples in a sample buffer.
    public var numberOfSamples : Int {
        return CMSampleBufferGetNumSamples(self)
    }
    /// The total size in bytes of sample data in the sample buffer. Returns 0 if no sample sizes are present.
    public var size : Int {
        return CMSampleBufferGetTotalSampleSize(self)
    }
}

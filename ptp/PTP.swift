//
//  PTP.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-27.
//  Copyright © 2016 FFFF00 Agents AB. All rights reserved.
//
//  Triggy is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Triggy is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Triggy.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation


public protocol PTPArgument {
    var argumentValue: UInt32 { get }
}

extension Int32: PTPArgument { public var argumentValue: UInt32 { return UInt32(self) } }
extension Int16: PTPArgument { public var argumentValue: UInt32 { return UInt32(self) } }
extension Int8: PTPArgument { public var argumentValue: UInt32 { return UInt32(self) } }
extension UInt32: PTPArgument { public var argumentValue: UInt32 { return self } }
extension UInt16: PTPArgument { public var argumentValue: UInt32 { return UInt32(self) } }
extension UInt8: PTPArgument { public var argumentValue: UInt32 { return UInt32(self) } }
extension Int: PTPArgument { public var argumentValue: UInt32 { return UInt32(self) } }

public enum PTPResponseCode: UInt16 {
    case Unknown                                = 0x0000
    case Undefined                              = 0x2000
    case OK                                     = 0x2001
    case GeneralError                           = 0x2002
    case SessionNotOpen                         = 0x2003
    case InvalidTransactionID                   = 0x2004
    case OperationNotSupported                  = 0x2005
    case ParameterNotSupported                  = 0x2006
    case IncompleteTransfer                     = 0x2007
    case InvalidStorageId                       = 0x2008
    case InvalidObjectHandle                    = 0x2009
    case DevicePropNotSupported                 = 0x200A
    case InvalidObjectFormatCode                = 0x200B
    case StoreFull                              = 0x200C
    case ObjectWriteProtected                   = 0x200D
    case StoreReadOnly                          = 0x200E
    case AccessDenied                           = 0x200F
    case NoThumbnailPresent                     = 0x2010
    case SelfTestFailed                         = 0x2011
    case PartialDeletion                        = 0x2012
    case StoreNotAvailable                      = 0x2013
    case SpecificationByFormatUnsupported       = 0x2014
    case NoValidObjectInfo                      = 0x2015
    case InvalidCodeFormat                      = 0x2016
    case UnknownVendorCode                      = 0x2017
    case CaptureAlreadyTerminated               = 0x2018
    case DeviceBusy                             = 0x2019
    case InvalidParentObject                    = 0x201A
    case InvalidDevicePropFormat                = 0x201B
    case InvalidDevicePropValue                 = 0x201C
    case InvalidParameter                       = 0x201D
    case SessionAlreadyOpened                   = 0x201E
    case TransactionCanceled                    = 0x201F
    case SpecificationOfDestinationUnsupported  = 0x2020
}

public struct PTPOperationCode : RawRepresentable, Equatable, Hashable, Comparable, CustomStringConvertible, ExpressibleByIntegerLiteral {
    
    public typealias RawValue = UInt16
    
    public let rawValue: UInt16
    
    public static let Unknown                = PTPOperationCode(0x0000)
    public static let Undefined              = PTPOperationCode(0x1000)
    public static let GetDeviceInfo          = PTPOperationCode(0x1001)
    public static let OpenSession            = PTPOperationCode(0x1002)
    public static let CloseSession           = PTPOperationCode(0x1003)
    public static let GetStorageIDs          = PTPOperationCode(0x1004)
    public static let GetStorageInfo         = PTPOperationCode(0x1005)
    public static let GetNumObjects          = PTPOperationCode(0x1006)
    public static let GetObjectHandles       = PTPOperationCode(0x1007)
    public static let GetObjectInfo          = PTPOperationCode(0x1008)
    public static let GetObject              = PTPOperationCode(0x1009)
    public static let GetThumb               = PTPOperationCode(0x100A)
    public static let DeleteObject           = PTPOperationCode(0x100B)
    public static let SendObjectInfo         = PTPOperationCode(0x100C)
    public static let SendObject             = PTPOperationCode(0x100D)
    public static let InitiateCapture        = PTPOperationCode(0x100E)
    public static let FormatStore            = PTPOperationCode(0x100F)
    public static let ResetDevice            = PTPOperationCode(0x1010)
    public static let SelfTest               = PTPOperationCode(0x1011)
    public static let SetObjectProtection    = PTPOperationCode(0x1012)
    public static let PowerDown              = PTPOperationCode(0x1013)
    public static let GetDevicePropDesc      = PTPOperationCode(0x1014)
    public static let GetDevicePropValue     = PTPOperationCode(0x1015)
    public static let SetDevicePropValue     = PTPOperationCode(0x1016)
    public static let ResetDevicePropValue   = PTPOperationCode(0x1017)
    public static let TerminateOpenCapture   = PTPOperationCode(0x1018)
    public static let MoveObject             = PTPOperationCode(0x1019)
    public static let CopyObject             = PTPOperationCode(0x101A)
    public static let GetPartialObject       = PTPOperationCode(0x101B)
    public static let InitiateOpenCapture    = PTPOperationCode(0x101C)
    // PTP 1.1
    public static let StartEnumHandles       = PTPOperationCode(0x101D)
    public static let EnumHandles            = PTPOperationCode(0x101E)
    public static let StopEnumHandles        = PTPOperationCode(0x101F)
    public static let GetVendorExtensionMaps = PTPOperationCode(0x1020)
    public static let GetVendorDeviceInfo    = PTPOperationCode(0x1021)
    public static let GetResizedImageObject  = PTPOperationCode(0x1022)
    public static let GetFilesystemManifest  = PTPOperationCode(0x1023)
    public static let GetStreamInfo          = PTPOperationCode(0x1024)
    public static let GetStream              = PTPOperationCode(0x1025)

    public init(_ value: UInt16) {
        self.rawValue = value
    }

    public init(integerLiteral value: UInt16) {
        self.rawValue = value
    }

    public init?(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public static func <(lhs: PTPOperationCode, rhs: PTPOperationCode) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var description: String {
        let hex = String(rawValue, radix: 16, uppercase: false)
        return "PTPOperationCode-0x\(hex)"
    }

}


public enum PTPObjectFormat: UInt16 {
    case Unknown                         = 0x0000
    case Undefined                       = 0x3000
    case Defined                         = 0x3800
    case Association                     = 0x3001
    case Script                          = 0x3002
    case Executable                      = 0x3003
    case Text                            = 0x3004
    case HTML                            = 0x3005
    case DPOF                            = 0x3006
    case AIFF                            = 0x3007
    case WAV                             = 0x3008
    case MP3                             = 0x3009
    case AVI                             = 0x300A
    case MPEG                            = 0x300B
    case ASF                             = 0x300C
    case QT                              = 0x300D
    case EXIF_JPEG                       = 0x3801
    case TIFF_EP                         = 0x3802
    case FlashPix                        = 0x3803
    case BMP                             = 0x3804
    case CIFF                            = 0x3805
    case Undefined_0x3806                = 0x3806
    case GIF                             = 0x3807
    case JFIF                            = 0x3808
    case PCD                             = 0x3809
    case PICT                            = 0x380A
    case PNG                             = 0x380B
    case Undefined_0x380C                = 0x380C
    case TIFF                            = 0x380D
    case TIFF_IT                         = 0x380E
    case JP2                             = 0x380F
    case JPX                             = 0x3810
    case DNG                             = 0x3811
    case EK_M3U                          = 0xb002
    case CANON_CRW                       = 0xb101
    case CANON_CRW3                      = 0xb103
    case CANON_MOV                       = 0xb104
    case MTP_MediaCard                   = 0xb211
    case MTP_MediaCardGroup              = 0xb212
    case MTP_Encounter                   = 0xb213
    case MTP_EncounterBox                = 0xb214
    case MTP_M4A                         = 0xb215
    case MTP_Firmware                    = 0xb802
    case MTP_WindowsImageFormat          = 0xb881
    case MTP_UndefinedAudio              = 0xb900
    case MTP_WMA                         = 0xb901
    case MTP_OGG                         = 0xb902
    case MTP_AAC                         = 0xb903
    case MTP_AudibleCodec                = 0xb904
    case MTP_FLAC                        = 0xb906
    case MTP_UndefinedVideo              = 0xb980
    case MTP_WMV                         = 0xb981
    case MTP_MP4                         = 0xb982
    case MTP_MP2                         = 0xb983
    case MTP_3GP                         = 0xb984
    case MTP_UndefinedCollection         = 0xba00
    case MTP_AbstractMultimediaAlbum     = 0xba01
    case MTP_AbstractImageAlbum          = 0xba02
    case MTP_AbstractAudioAlbum          = 0xba03
    case MTP_AbstractVideoAlbum          = 0xba04
    case MTP_AbstractAudioVideoPlaylist  = 0xba05
    case MTP_AbstractContactGroup        = 0xba06
    case MTP_AbstractMessageFolder       = 0xba07
    case MTP_AbstractChapteredProduction = 0xba08
    case MTP_AbstractAudioPlaylist       = 0xba09
    case MTP_AbstractVideoPlaylist       = 0xba0a
    case MTP_AbstractMediacast           = 0xba0b
    case MTP_WPLPlaylist                 = 0xba10
    case MTP_M3UPlaylist                 = 0xba11
    case MTP_MPLPlaylist                 = 0xba12
    case MTP_ASXPlaylist                 = 0xba13
    case MTP_PLSPlaylist                 = 0xba14
    case MTP_UndefinedDocument           = 0xba80
    case MTP_AbstractDocument            = 0xba81
    case MTP_XMLDocument                 = 0xba82
    case MTP_MSWordDocument              = 0xba83
    case MTP_MHTCompiledHTMLDocument     = 0xba84
    case MTP_MSExcelSpreadsheetXLS       = 0xba85
    case MTP_MSPowerpointPresentationPPT = 0xba86
    case MTP_UndefinedMessage            = 0xbb00
    case MTP_AbstractMessage             = 0xbb01
    case MTP_UndefinedContact            = 0xbb80
    case MTP_AbstractContact             = 0xbb81
    case MTP_vCard2                      = 0xbb82
    case MTP_vCard3                      = 0xbb83
    case MTP_UndefinedCalendarItem       = 0xbe00
    case MTP_AbstractCalendarItem        = 0xbe01
    case MTP_vCalendar1                  = 0xbe02
    case MTP_vCalendar2                  = 0xbe03
    case MTP_UndefinedWindowsExecutable  = 0xbe80
    case MTP_MediaCast                   = 0xbe81
    case MTP_Section                     = 0xbe82
}

public enum PTPDeviceProperty: UInt16 {
    case Unknown                  = 0x0000
    case Undefined                = 0x5000
    case BatteryLevel             = 0x5001
    case FunctionalMode           = 0x5002
    case ImageSize                = 0x5003
    case CompressionSetting       = 0x5004
    case WhiteBalance             = 0x5005
    case RGBGain                  = 0x5006
    case FNumber                  = 0x5007
    case FocalLength              = 0x5008
    case FocusDistance            = 0x5009
    case FocusMode                = 0x500A
    case ExposureMeteringMode     = 0x500B
    case FlashMode                = 0x500C
    case ExposureTime             = 0x500D
    case ExposureProgramMode      = 0x500E
    case ExposureIndex            = 0x500F
    case ExposureBiasCompensation = 0x5010
    case DateTime                 = 0x5011
    case CaptureDelay             = 0x5012
    case StillCaptureMode         = 0x5013
    case Contrast                 = 0x5014
    case Sharpness                = 0x5015
    case DigitalZoom              = 0x5016
    case EffectMode               = 0x5017
    case BurstNumber              = 0x5018
    case BurstInterval            = 0x5019
    case TimelapseNumber          = 0x501A
    case TimelapseInterval        = 0x501B
    case FocusMeteringMode        = 0x501C
    case UploadURL                = 0x501D
    case Artist                   = 0x501E
    case CopyrightInfo            = 0x501F
    // PTP 1.1
    case SupportedStreams         = 0x5020
    case EnabledStreams           = 0x5021
    case VideoFormat              = 0x5022
    case VideoResolution          = 0x5023
    case VideoQuality             = 0x5024
    case VideoFrameRate           = 0x5025
    case VideoContrast            = 0x5026
    case VideoBrightness          = 0x5027
    case AudioFormat              = 0x5028
    case AudioBitrate             = 0x5029
    case AudioSamplingRate        = 0x502A
    case AudioBitPerSample        = 0x502B
    case AudioVolume              = 0x502C
}

extension PTPDeviceProperty: PTPArgument {
    public var argumentValue: UInt32 { return UInt32(self.rawValue) }
}




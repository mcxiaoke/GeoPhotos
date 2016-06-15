//
//  Constants.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

let DateFormatter = NSDateFormatter(dateFormat:"yyyy:MM:dd HH:mm:ss")
let ImageExtensions = ["jpg", "jpeg", "png", "gif"]


let latitudeRange = -90.0...90.0
let longitudeRange  = -180.0...180.0

let kCGImagePropertyCommonDictionary = "{Info}"

let ImageCategoryPrefixKeys:[String:String] = [
  kCGImagePropertyCommonDictionary:"Info",
  kCGImagePropertyExifDictionary as String:"Exif",
  kCGImagePropertyExifAuxDictionary as String:"Exif Aux",
  kCGImagePropertyGPSDictionary as String:"GPS",
  kCGImagePropertyTIFFDictionary as String:"TIFF",
  kCGImagePropertyIPTCDictionary as String:"IPTC",
  kCGImagePropertyJFIFDictionary as String:"JFTF",
  kCGImagePropertyRawDictionary as String:"Raw",
  kCGImagePropertyDNGDictionary  as String:"DNG",
  kCGImagePropertyPNGDictionary as String:"PNG",
  kCGImagePropertyGIFDictionary  as String:"GIF",
  kCGImagePropertyMakerAppleDictionary  as String:"Apple",
  kCGImagePropertyMakerNikonDictionary  as String:"Nikon",
  kCGImagePropertyMakerCanonDictionary  as String:"Canon",
  kCGImagePropertyMakerFujiDictionary  as String:"Fuji",
  kCGImagePropertyMakerOlympusDictionary  as String:"Olympus",
  kCGImagePropertyMakerPentaxDictionary as String: "Pentax"
]

let ArrayTypePropertyKeys:[String] = [
  kCGImagePropertyExifVersion as String,
  kCGImagePropertyExifISOSpeedRatings as String,
  kCGImagePropertyExifLensSpecification as String,
  kCGImagePropertyExifAuxLensInfo as String,
  kCGImagePropertyExifComponentsConfiguration as String,
  kCGImagePropertyExifFlashPixVersion as String,
  kCGImagePropertyExifSubjectArea as String,
]

let DateTypePropertyKeys:[String] = [
  kCGImagePropertyExifDateTimeOriginal as String,
  kCGImagePropertyExifDateTimeDigitized as String,
  kCGImagePropertyTIFFDateTime as String,
]

let StringTypePropertyKeys:[String] = [
  kCGImagePropertyColorModel as String,
  kCGImagePropertyExifLensModel as String,
  kCGImagePropertyExifLensMake as String,
  kCGImagePropertyExifBodySerialNumber as String,
  kCGImagePropertyExifSubsecTimeOrginal as String,
  kCGImagePropertyExifSubsecTimeDigitized as String,
  kCGImagePropertyExifUserComment as String,
  kCGImagePropertyGPSDestBearingRef as String,
  kCGImagePropertyGPSImgDirectionRef as String,
  kCGImagePropertyGPSLatitudeRef as String,
  kCGImagePropertyGPSLongitudeRef as String,
  kCGImagePropertyGPSSpeedRef as String,
  kCGImagePropertyProfileName as String,
  kCGImagePropertyTIFFMake as String,
  kCGImagePropertyTIFFModel as String,
  kCGImagePropertyTIFFSoftware as String,
  
]

let ImagePropertyKeys:[String] = [
  kCGImagePropertyDPIHeight as String,
  kCGImagePropertyDPIWidth as String,
  kCGImagePropertyPixelWidth as String,
  kCGImagePropertyPixelHeight as String,
  kCGImagePropertyDepth as String,
  kCGImagePropertyOrientation as String,
  kCGImagePropertyIsFloat as String,
  kCGImagePropertyIsIndexed as String,
  kCGImagePropertyHasAlpha as String,
  kCGImagePropertyColorModel as String,
  kCGImagePropertyProfileName as String,
]

let ExifPropertyKeys:[String] = [
  kCGImagePropertyExifExposureTime as String,
  kCGImagePropertyExifFNumber as String,
  kCGImagePropertyExifExposureProgram as String,
  kCGImagePropertyExifSpectralSensitivity as String,
  kCGImagePropertyExifISOSpeedRatings as String,
  kCGImagePropertyExifOECF as String,
  kCGImagePropertyExifVersion as String,
  kCGImagePropertyExifDateTimeOriginal as String,
  kCGImagePropertyExifDateTimeDigitized as String,
  kCGImagePropertyExifComponentsConfiguration as String,
  kCGImagePropertyExifCompressedBitsPerPixel as String,
  kCGImagePropertyExifShutterSpeedValue as String,
  kCGImagePropertyExifApertureValue as String,
  kCGImagePropertyExifBrightnessValue as String,
  kCGImagePropertyExifExposureBiasValue as String,
  kCGImagePropertyExifMaxApertureValue as String,
  kCGImagePropertyExifSubjectDistance as String,
  kCGImagePropertyExifMeteringMode as String,
  kCGImagePropertyExifLightSource as String,
  kCGImagePropertyExifFlash as String,
  kCGImagePropertyExifFocalLength as String,
  kCGImagePropertyExifSubjectArea as String,
  kCGImagePropertyExifMakerNote as String,
  kCGImagePropertyExifUserComment as String,
  kCGImagePropertyExifSubsecTime as String,
  kCGImagePropertyExifSubsecTimeOrginal as String,
  kCGImagePropertyExifSubsecTimeDigitized as String,
  kCGImagePropertyExifFlashPixVersion as String,
  kCGImagePropertyExifColorSpace as String,
  //  kCGImagePropertyExifPixelXDimension as String,
  //  kCGImagePropertyExifPixelYDimension as String,
  kCGImagePropertyExifRelatedSoundFile as String,
  kCGImagePropertyExifFlashEnergy as String,
  kCGImagePropertyExifSpatialFrequencyResponse as String,
  kCGImagePropertyExifFocalPlaneXResolution as String,
  kCGImagePropertyExifFocalPlaneYResolution as String,
  kCGImagePropertyExifFocalPlaneResolutionUnit as String,
  kCGImagePropertyExifSubjectLocation as String,
  kCGImagePropertyExifExposureIndex as String,
  kCGImagePropertyExifSensingMethod as String,
  kCGImagePropertyExifFileSource as String,
  kCGImagePropertyExifSceneType as String,
  kCGImagePropertyExifCFAPattern as String,
  kCGImagePropertyExifCustomRendered as String,
  kCGImagePropertyExifExposureMode as String,
  kCGImagePropertyExifWhiteBalance as String,
  kCGImagePropertyExifDigitalZoomRatio as String,
  kCGImagePropertyExifFocalLenIn35mmFilm as String,
  kCGImagePropertyExifSceneCaptureType as String,
  kCGImagePropertyExifGainControl as String,
  kCGImagePropertyExifContrast as String,
  kCGImagePropertyExifSaturation as String,
  kCGImagePropertyExifSharpness as String,
  kCGImagePropertyExifDeviceSettingDescription as String,
  kCGImagePropertyExifSubjectDistRange as String,
  kCGImagePropertyExifImageUniqueID as String,
  kCGImagePropertyExifGamma as String,
  kCGImagePropertyExifCameraOwnerName as String,
  kCGImagePropertyExifBodySerialNumber as String,
  kCGImagePropertyExifLensSpecification as String,
  kCGImagePropertyExifLensMake as String,
  kCGImagePropertyExifLensModel as String,
  kCGImagePropertyExifLensSerialNumber as String,
]

let GPSPropertyKeys:[String] = [
  kCGImagePropertyGPSVersion as String,
  kCGImagePropertyGPSLatitudeRef as String,
  kCGImagePropertyGPSLatitude as String,
  kCGImagePropertyGPSLongitudeRef as String,
  kCGImagePropertyGPSLongitude as String,
  kCGImagePropertyGPSAltitudeRef as String,
  kCGImagePropertyGPSAltitude as String,
  kCGImagePropertyGPSTimeStamp as String,
  kCGImagePropertyGPSSatellites as String,
  kCGImagePropertyGPSStatus as String,
  kCGImagePropertyGPSMeasureMode as String,
  kCGImagePropertyGPSDOP as String,
  kCGImagePropertyGPSSpeedRef as String,
  kCGImagePropertyGPSSpeed as String,
  kCGImagePropertyGPSTrackRef as String,
  kCGImagePropertyGPSTrack as String,
  kCGImagePropertyGPSImgDirectionRef as String,
  kCGImagePropertyGPSImgDirection as String,
  kCGImagePropertyGPSMapDatum as String,
  kCGImagePropertyGPSDestLatitudeRef as String,
  kCGImagePropertyGPSDestLatitude as String,
  kCGImagePropertyGPSDestLongitudeRef as String,
  kCGImagePropertyGPSDestLongitude as String,
  kCGImagePropertyGPSDestBearingRef as String,
  kCGImagePropertyGPSDestBearing as String,
  kCGImagePropertyGPSDestDistanceRef as String,
  kCGImagePropertyGPSDestDistance as String,
  kCGImagePropertyGPSProcessingMethod as String,
  kCGImagePropertyGPSAreaInformation as String,
  kCGImagePropertyGPSDateStamp as String,
  kCGImagePropertyGPSDifferental as String,
]

let TIFFPropertyKeys:[String] = [
  kCGImagePropertyTIFFCompression as String as String,
  kCGImagePropertyTIFFPhotometricInterpretation as String,
  kCGImagePropertyTIFFDocumentName as String,
  kCGImagePropertyTIFFImageDescription as String,
  kCGImagePropertyTIFFMake as String,
  kCGImagePropertyTIFFModel as String,
  kCGImagePropertyTIFFOrientation as String,
  //  kCGImagePropertyTIFFXResolution as String,
  //  kCGImagePropertyTIFFYResolution as String,
  kCGImagePropertyTIFFResolutionUnit as String,
  kCGImagePropertyTIFFSoftware as String,
  kCGImagePropertyTIFFTransferFunction as String,
  kCGImagePropertyTIFFDateTime as String,
  kCGImagePropertyTIFFArtist as String,
  kCGImagePropertyTIFFHostComputer as String,
  kCGImagePropertyTIFFCopyright as String,
  kCGImagePropertyTIFFWhitePoint as String,
  kCGImagePropertyTIFFPrimaryChromaticities as String,
]

let GPSEditablePropertyKeys:[String] = [
  kCGImagePropertyGPSLatitude as String,
  kCGImagePropertyGPSLongitude as String,
  kCGImagePropertyGPSAltitude as String,
  kCGImagePropertyGPSTimeStamp as String,
  kCGImagePropertyGPSDateStamp as String,
]

let AllEditablePropertyKeys =  ExifPropertyKeys + GPSPropertyKeys

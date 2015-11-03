//
//  ViewController.swift
//  imageExif
//
//  Created by 王望 on 15/11/3.
//  Copyright © 2015年 Will. All rights reserved.
//

import UIKit
import ImageIO

enum ExifOrientation : Int {
  case Up = 1
  case Down = 3
  case Left = 8
  case Right = 6
  case UpMirrored = 2
  case DownMirrored = 4
  case LeftMirrored = 5
  case RightMirrored = 7
}

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    guard let url = NSBundle.mainBundle().URLForResource("home", withExtension: ".png"),let data = NSData(contentsOfURL: url) else{ // Do something because you couldn't get the file or convert it to NSData
      return
    }
    /// 可以在https://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFDataRef/#//apple_ref/c/func/CFDataCreate 看到使用方法的例子
    let dataPtr = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(data.bytes), data.length)
    
    let imageSourceRef = CGImageSourceCreateWithData(dataPtr, nil)
    let exif = CGImageSourceCopyPropertiesAtIndex(imageSourceRef!, 0, nil)
    print(exif)
    /// 打印出来的字典中
    let uti = CGImageSourceGetType(imageSourceRef!)
    let mutableData = CFDataCreateMutable(kCFAllocatorDefault, 0)
    let imageDestination = CGImageDestinationCreateWithData(mutableData, uti!, 1, nil)
    let orientation =
    NSDictionary(dictionary: [kCGImagePropertyOrientation:ExifOrientation.Down.rawValue]) as CFDictionaryRef
    CGImageDestinationAddImage(imageDestination!, (UIImage(data: data)?.CGImage)!, orientation)
    CGImageDestinationFinalize(imageDestination!)
    let image = UIImage(data: data, scale: UIScreen.mainScreen().scale)
    image?.ww_decompressedImage()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
extension UIImage{
  func ww_decompressedImage() -> UIImage! {
    let originalImageRef = self.CGImage
    let originalBitmapInfo = CGImageGetBitmapInfo(originalImageRef)
    let alphaInfo = CGImageGetAlphaInfo(originalImageRef)
    
    // See: http://stackoverflow.com/questions/23723564/which-cgimagealphainfo-should-we-use
    var bitmapInfo = originalBitmapInfo
    switch (alphaInfo) {
    case .None:
      let rawBitmapInfoWithoutAlpha = bitmapInfo.rawValue & ~CGBitmapInfo.AlphaInfoMask.rawValue
      let rawBitmapInfo = rawBitmapInfoWithoutAlpha | CGImageAlphaInfo.NoneSkipFirst.rawValue
      bitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
    case .PremultipliedFirst, .PremultipliedLast, .NoneSkipFirst, .NoneSkipLast:
      break
    case .Only, .Last, .First: // Unsupported
      return self
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let pixelSize = CGSizeMake(self.size.width * self.scale, self.size.height * self.scale)
    guard let context = CGBitmapContextCreate(nil, Int(ceil(pixelSize.width)), Int(ceil(pixelSize.height)), CGImageGetBitsPerComponent(originalImageRef), 0, colorSpace, bitmapInfo.rawValue) else {
      return self
    }
    
    let imageRect = CGRectMake(0, 0, pixelSize.width, pixelSize.height)
    UIGraphicsPushContext(context)
    
    // Flip coordinate system. See: http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
    CGContextTranslateCTM(context, 0, pixelSize.height)
    CGContextScaleCTM(context, 1.0, -1.0)
    
    // UIImage and drawInRect takes into account image orientation, unlike CGContextDrawImage.
    self.drawInRect(imageRect)
    UIGraphicsPopContext()
    
    guard let decompressedImageRef = CGBitmapContextCreateImage(context) else {
      return self
    }
    
    let scale = UIScreen.mainScreen().scale
    let image = UIImage(CGImage: decompressedImageRef, scale:scale, orientation:UIImageOrientation.Up)
    return image
  }
}

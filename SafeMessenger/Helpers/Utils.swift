//
//  Utils.swift
//  SafeMessenger
//
//  Created by Sandeep Kumar on 06/06/21.
//

import Foundation
import UIKit
import AVKit

class Utils {
    static let shared = Utils()
    
    static let networkDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd H:m:ss SSSS"
        return formatter
    }()
    
    static let hrMinDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()
    
    static let hrMinOnDateDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMM d, yyyy"
        return formatter
    }()
}

extension Utils {
    func isUserLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultConstant.isLoggedIn)
    }
    
    func getLoggedInUserEmail() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultConstant.userEmail)
    }
    
    func getLoggedInUserSafeEmail() -> String? {
        guard let userEmail = getLoggedInUserEmail() else {
            return nil
        }
        return safeEmail(email: userEmail)
    }
    
    func safeEmail(email: String?) -> String? {
        guard let email = email else {
            print("Utils: no Email passed to safeEmail Converter")
            return nil
        }
        
        return email.replacingOccurrences(of: ".", with: "-")
    }
    
    func getStoragePathForEmail(for email:String) -> String {
        let safeEmail = StorageManager.safeEmail(for: email)
        let fileName = StorageManager.profileImageFilename(for: safeEmail)
        let path = StorageManager.profileImageRefPath(fileName: fileName)
        return path
    }
    
    func getLoggedInUserDisplayURL() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultConstant.profileImageUrl)
    }
    
    func getLoggedInUserDisplayName() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultConstant.userName)
    }
}

extension Utils {
    static func getThumbnailImage(forUrl url: URL?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
            return UIImage.init(cgImage: thumbnailImage)
        } catch let error {
            print("Utils: Get ThumbnailImage Failed: \(error)")
            return nil
        }
    }
}

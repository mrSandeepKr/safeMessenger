//
//  Utils.swift
//  SafeMessenger
//
//  Created by Sandeep Kumar on 06/06/21.
//

import Foundation

class Utils {
    static let shared = Utils()
    
    public static let networkDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        return formatter
    }()
    
    public static let hrMinDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
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

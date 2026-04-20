//
//  DateFormatter.swift
//  VocabularyForest
//
//  Created by Yakup Kavak on 11.04.2026.
//

import Foundation

extension Date {
    func toFriendlyLocalizedString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            if day == 1 {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return String(localized: "Yesterday at \(formatter.string(from: self))")
            } else if day < 7 {
                return String(localized: "\(day) days ago")
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter.string(from: self)
            }
        }
        
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? String(localized: "1 hour ago") : String(localized: "\(hour) hours ago")
        }
        
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? String(localized: "1 minute ago") : String(localized: "\(minute) minutes ago")
        }
        
        return String(localized: "Just now")
    }
    func toFriendlyRemaintime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: self)
        return timeString
    }
}

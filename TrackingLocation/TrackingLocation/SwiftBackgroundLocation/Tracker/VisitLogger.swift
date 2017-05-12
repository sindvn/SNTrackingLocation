//
//  VisitLogger.swift
//  trippa
//
//  Created by dang huu duong on 4/4/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import Foundation
import CoreLocation

struct VisitLogger {
    
    private static var fileUrl = { () -> URL in
        let dir: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!
        return dir.appendingPathComponent("visit.log")
    }()
    
    func removeLogFile() {
        try? FileManager.default.removeItem(at: VisitLogger.fileUrl)
    }
    
    func writeVisitToFile(visit: Visit) {
      NSKeyedArchiver.archiveRootObject(visit, toFile: VisitLogger.fileUrl.path)
    }
    
    func readVisit() -> Visit? {
        if let visit = NSKeyedUnarchiver.unarchiveObject(withFile: VisitLogger.fileUrl.path) as? Visit
        {
            return visit
        }
        return nil
    }
}


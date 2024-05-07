//
//  AppDelegate.swift
//  PPM Research
//
//  Created by raheel on 4/4/24.
//

import UIKit
import SMARTMarkers
import SMART

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


public func localresource<T: DomainResource>(_ filename: String, bundle: Foundation.Bundle, resourceType: T.Type) throws -> T {
    
    if let filePath = bundle.path(forResource: filename, ofType: "json"),
        let data = NSData(contentsOfFile: filePath) {
        do {
            let jsonData = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! FHIRJSON
            var ctx = FHIRInstantiationContext(strict: false)
            let q = T.instantiate(from: jsonData, owner: nil, context: &ctx)
            return q
        }
        catch {
            throw error
        }
    }
    else {
        throw SMError.undefined(description: "Cannot find file at path: \(filename)")
    }
}




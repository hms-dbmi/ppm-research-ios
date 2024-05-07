//
//  Misc.swift
//  PPM Research
//
//  Created by raheel on 4/15/24.
//

import Foundation
import SMART
import SMARTMarkers


class FHIRMethods {
    
     static func sm_Questionnaire(_ filename: String) -> Questionnaire? {
        
        let bundle = Bundle(identifier: "org.chip.SMARTMarkers")!
        return try? localresource(filename, bundle: bundle, resourceType: Questionnaire.self)
    }
    
     static func local_Questionnaire(_ filename: String) throws -> Questionnaire? {
        return try localresource(filename, bundle: Foundation.Bundle.main, resourceType: Questionnaire.self)
    }
    
    public static func ppmg_StringFrom(filename: String, bundle: Foundation.Bundle) throws -> String? {
        
        if let filepath = bundle.path(forResource: filename, ofType: nil) {
            return try String(contentsOfFile: filepath)
        }
        
        return nil
    }
    
    public static func localresource<T: DomainResource>(_ filename: String, bundle: Foundation.Bundle, resourceType: T.Type) throws -> T {
        
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
}

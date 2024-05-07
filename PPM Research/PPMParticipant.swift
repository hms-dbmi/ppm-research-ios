//
//  File.swift
//  PPM Research
//
//  Created by raheel on 4/22/24.
//

import Foundation
import SMARTMarkers
import SMART


class PPMParticipant: Participant {
    
    func taskDidConclude(task: SMARTMarkers.StudyTask) {
       
    }

    var smConsent: SMARTMarkers.Consented?
    
    typealias ConsentedType = Consented
    
    var identifier: String?
    
    var firstName: String?
    
    var lastName: String?
    
    var study: SMARTMarkers.Study
    
    var didCompleteAllTasks: Bool  {
        false
    }
    
    var fhirPatient: SMART.Patient
    
    var fhirResearchSubject: SMART.ResearchSubject
    

    func update<Task>(from userGeneratedData: [SMART.DomainResource]?, ofTask studyTask: Task) where Task : SMARTMarkers.StudyTaskProtocol {
    }
    

    
    required public init(patient: Patient, for study: Study, consent: Consent?, subject: ResearchSubject) {
        
        self.fhirPatient = patient
        self.firstName = fhirPatient.name?.first?.given?.first?.string
        self.lastName = fhirPatient.name?.first?.family?.string
        self.fhirPatient.identifier?.first?.system = study.identifier?.system
        self.study = study
        self.fhirResearchSubject = subject
        if let consent {
            self.smConsent = Consented(consent)
        }
        
    }
    
    public static func CreateNewStudyParticipant(givenName: String?, lastName: String?, participantIdentifier: String?, contactEmail: String?, study: Study) throws -> Self {

        // synthetic identifier
        let participantId = participantIdentifier ?? synthetic_identifier()
        
        
        let patient = try Patient.ppmgNewParticipant(
            givenName: givenName,
            lastName: lastName,
            participantIdentifier: participantId,
            fhirId: nil,
            contactEmail: contactEmail,
            subjectStatus: nil,
            datasubmitted: nil,
            sharePolicy: nil)
        
        // Assign study tag
//        patient.assignTag_PPMG()
        
        let sub = try ResearchSubject(individual: Reference(), status: .pendingOnStudy, study: study.resource.asRelativeReference())
 
        return PPMParticipant(patient: patient, for: study, consent: nil, subject: sub) as! Self
    }
    
}


extension Patient {
    
    public static func ppmgNewParticipant(
        givenName: String?,
        lastName: String?,
        participantIdentifier: String?,
        fhirId: String?,
        contactEmail: String?,
        subjectStatus: String? = nil,
        datasubmitted: String? = nil,
        sharePolicy: String?
    ) throws -> Patient {
        
        let filename = "StudyResources/fhir_templates/Patient"
        guard let patient = try? localresource(filename, bundle: Foundation.Bundle.main, resourceType: Patient.self) else {
            throw SMError.undefined(description: "Error: Faulty Patient resource")
        }
        
        patient.name?.first?.family = lastName?.fhir_string
        patient.name?.first?.given = [givenName?.fhir_string].compactMap{$0}
        patient.identifier?.first?.value = participantIdentifier?.fhir_string
        patient.id = fhirId?.fhir_string
 
        
        
        var extensions = patient.extension_fhir ?? []
        
        if let subject_status = subjectStatus,
           let rsStatus = ResearchSubjectStatus(rawValue: subject_status) {
            let ext = rsStatus.sm_asExtension
            extensions.append(ext)
        }
        
        if let contactEmail = contactEmail {
            let contact = ContactPoint()
            contact.system = .email
            contact.value = contactEmail.fhir_string
            patient.telecom = [contact]
        }
        
        patient.extension_fhir = extensions.count > 0 ? extensions : nil
        return patient
    }
    
}


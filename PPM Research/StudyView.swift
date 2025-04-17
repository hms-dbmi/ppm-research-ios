//
//  StudyView.swift
//  PPM Research
//
//  Created by raheel on 4/19/24.
//

import SwiftUI
import WebKit
import SMARTMarkers
import ResearchKit




struct html: Identifiable {
    let text: String
    let id = UUID()
}


struct StudyView: View {
    
    @State var viewModel: StudyViewModel
    @State var enrollmentView: EnrollmentView? = nil
    @State var isPresented: Bool = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Text(viewModel.study.name ?? "-na-")
                    .font(.largeTitle)
                Text(viewModel.study.organization?.name?.string ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    LazyHStack (alignment: .top) {
                        ForEach(viewModel.about_content ?? []) { content in
                            WebView(text: content.text)
                                .frame(width: 250, height: 320)
                                .padding([.top, .leading])
                        }
                    }
                    .background(Color.secondary)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                Button {
                    if let view = self.viewModel.showEnrollmentView() {
                        self.enrollmentView = EnrollmentView(view)
                    }
                }
                label: {
                    Text("Check Eligibility")
                        .frame(minWidth: 0, maxWidth: 300)
                        .foregroundColor(.white)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.blue)
                        }
                }
                .sheet(item: $enrollmentView, content: { view in
                    view
                })
            }
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }        
        .background(Color.red)

    }
}

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    var text: String
    
    func makeUIView(context: Context) -> WKWebView {
        let v = WKWebView()
        v.pageZoom = 1.0
        return v
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(text, baseURL: nil)
    }
}

@Observable
public class StudyViewModel {
    var study: Study
    var enrollmentModule: Enrollment?
    var viewController: UIViewController?
    
    var about_content: [html]?
    
    public init(study: Study) {
        self.study = study
        guard let about_study = self.study.study_notes?.compactMap({
            html(text: StudiesView.htmlSection($0))
        }) else {
            return
        }
        
        self.about_content =  about_study
    }
    
    func showEnrollmentView() -> UIViewController? {
        
        let consent = ConsentController(
            study_title: study.name!,
            htmlTemplate: "<h1>Consent</h1>",
            signatureTitle: nil,
            signaturePageContent: "Signature",
            requiredToShowEnrollmentOptions: true,
            requiredConsentToShare: true,
            requiredConsentToSubmitHealthRecord: true
        )
        
        self.enrollmentModule = Enrollment(
            repository: nil,
            for: study,
            participantType: PPMParticipant.self,
            eligibilityController: study.eligibility!,
            consentController: consent,
            preProcessor: nil,
            callback: nil)
        
        
        do {
            return try self.enrollmentModule?.viewController()
        }
        catch {
            print(error)
            return nil
        }
    }
    
}

struct EnrollmentView: UIViewControllerRepresentable, Identifiable {
    var id = UUID()
    
    typealias UIViewControllerType = UIViewController
    
    let view: UIViewController
    
    init(_ view: UIViewController) {
        self.view = view
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        return view
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

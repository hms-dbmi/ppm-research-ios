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
    @State private var enrollmentView: EnrollmentView? = nil
    @State private var currentPageID: html.ID? = nil
    @State private var currentIndex: Int = 0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(viewModel.study.organization?.name?.string ?? "")
                    Text(viewModel.study.studyDescription ?? "")
                        .font(.subheadline)

                }
                .background(Color.clear)

                
                if let about = viewModel.about_content, !about.isEmpty {
                    GeometryReader { proxy in
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .center, spacing: 0) {
                                ForEach(about) { content in
                                    WebView(text: content.text, openLinksExternally: true)
                                        .frame(width: proxy.size.width, height: proxy.size.height)
                                        .contentShape(Rectangle())
                                        .containerRelativeFrame(.horizontal)
                                        .id(content.id)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollIndicators(.visible, axes: .horizontal)
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $currentPageID)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        // Update current page index when the bound scroll position changes
                        .onChange(of: currentPageID) { _, newID in
                            if let newID, let idx = about.firstIndex(where: { $0.id == newID }) {
                                currentIndex = idx
                            }
                        }
                        // Page dots overlay
                        .overlay(alignment: .bottom) {
                            HStack(spacing: 6) {
                                ForEach(about.indices, id: \.self) { i in
                                    Circle()
                                        .fill(i == currentIndex ? Color.primary : Color.secondary.opacity(0.35))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .frame(minHeight: 360)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                
                
            }
            .listStyle(.insetGrouped)
            .navigationTitle(viewModel.study.name ?? "Untitled Study")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Spacer()
                        Button {
                            if let view = viewModel.showEnrollmentView() {
                                enrollmentView = EnrollmentView(view)
                            }
                        } label: {
                            Text("Check Eligibility").bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityIdentifier("checkEligibilityButton")
                        Spacer()
                    }
                }
            }
            .sheet(item: $enrollmentView) { view in
                view
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    var text: String
    var baseURL: URL? = nil
    var openLinksExternally: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator(openLinksExternally: openLinksExternally) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let v = WKWebView(frame: .zero, configuration: config)
        v.isOpaque = false
        v.backgroundColor = .clear
        v.scrollView.contentInsetAdjustmentBehavior = .never
        v.navigationDelegate = context.coordinator
        v.pageZoom = 1.0
        return v
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Avoid unnecessary reloads if HTML hasn't changed
        if context.coordinator.lastHTML != text {
            context.coordinator.lastHTML = text
            uiView.loadHTMLString(text, baseURL: baseURL)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?
        let openLinksExternally: Bool

        init(openLinksExternally: Bool) {
            self.openLinksExternally = openLinksExternally
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard openLinksExternally,
                  navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            // Open external links in Safari and cancel in-webview navigation
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
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
        guard let title = study.name else { return nil }
        guard let eligibility = study.eligibility else { return nil }

        let consent = ConsentController(
            study_title: title,
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
            eligibilityController: eligibility,
            consentController: consent,
            preProcessor: nil,
            callback: nil
        )

        do { return try self.enrollmentModule?.viewController() }
        catch {
            print("Enrollment error: \(error)")
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

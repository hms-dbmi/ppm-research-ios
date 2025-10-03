//
//  ViewController.swift
//  PPM Research
//
//  Created by raheel on 4/4/24.
//

import UIKit
import SwiftUI
import SMARTMarkers
import SMART
import CodeScanner


// let url = URL(string: "https://hms-dbmi-ppm-public-site.s3.us-east-1.amazonaws.com/fhir/")!
let url = URL(string: "https://peoplepoweredmedicine.org/fhir/")!
//let url = URL(string: "https://server.fire.ly/r4/")!
class StudiesView: UITableViewController {
    
    var studies: [Study]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Studies"
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(showQRScanner(_:)))
        getstudies(url: url) { bundl, error in
            if let bundl {
                do {
                    if let studies = try bundl.entry?
                        .compactMap({ $0.resource as? ResearchStudy })
                        .compactMap({ try Study($0) }){
                        self.studies = studies
                        
                        
                    }
                }
                catch {
                    print(error)
                }
            } else if let error {
                print(error.description)
            }

            callOnMainThread {
                self.tableView.reloadData()
            }
        }
    }
    
    func getstudies(url: URL, callback: @escaping FHIRSearchBundleErrorCallback) {
        let server = Server(baseURL: url)
        let search = FHIRSearch(type: ResearchStudy.self, query: [])
        search.perform(server, callback: callback)
    }
    
    @objc func showQRScanner(_ sender: Any?) {
        
        let view = CodeScannerView(codeTypes: [.qr], simulatedData: "https://peoplepoweredmedicine.org/") { result in
            print(result)
        }
        
        let host = UIHostingController(rootView: view)
        present(host, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        
        return self.studies?.count ?? 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "studycell",
            for: indexPath
        )
        
        if indexPath.section == 0 {
            cell.contentConfiguration = UIHostingConfiguration {
                VStack (alignment: .leading) {
                    Text("People-Powered Medicine")
                        .font(.title2)
                    Text(url.absoluteString)
                        .font(.footnote)
                }
            }
            cell.backgroundColor = .clear
            return cell
        }
        else {
            let study = self.studies![indexPath.row]
            cell.contentConfiguration = UIHostingConfiguration {
                HStack (alignment: .top) {
                    Text("\(indexPath.row+1).")
                        .font(.headline)
                    VStack(alignment: .leading) {
                        Text(study.name ?? "title")
                            .font(.headline)
                        Text(study.organization?.name?.string ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Active: 2023-22-1")
                            .font(.footnote)
                        Text("http://peoplepoweredmedicine.org/heart")
                            .font(.footnote)
                        Spacer(minLength: 10)
                        Text(study.studyDescription ?? "")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)

                    }
                }
            }
            return cell
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let study = studies![indexPath.row]
        let studyModel = StudyViewModel(study: study)
        let view = StudyView(viewModel: studyModel)
        let host = UIHostingController(rootView: view)
        present(host, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
//    func loadLocalResearchStudy() throws -> [Study]? {
//        do {
//            let phs = try localresource("researchstudy-phs", bundle: .main, resourceType: ResearchStudy.self)
//            let phs_study = try Study(phs)
//            return [phs_study]
//        }
//        catch {
//            print(error)
//            return nil
//        }
//    }
}



extension StudiesView {
    
    static func htmlSection(_ body: String) -> String {
        
        return """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
                    <meta name="viewport" content="initial-scale=1.0" />
                    <style>
              body { font: -apple-system-body; }
              img {
                height: 50px;
                width: autho;
              }
              header div {
                  height: 60px; margin: 1em 0;
                  text-align: center;
            
              }
              h1 {
                  padding: 0;
                  font: -apple-system-subheadline;
                  font-size: 1.5em; font-weight: 400;
                  color: black; text-align:center;
              }
              hr {
                  height: 1px; margin: 2em;
                  border: none;
                  background: linear-gradient(transparent 0%, transparent 50%, #AAA 50%, #AAA 100%);
              }
              a, a:link, a:visited {
                  color: rgb(57,99,159);
              }
            </style></head>
            \(body)
            </html>
            """
    }
}


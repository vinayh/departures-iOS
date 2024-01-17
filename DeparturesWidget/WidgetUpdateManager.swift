//
//  DeparturesWidgetBackground.swift
//  DeparturesWidgetExtension
//
//  Created by Vinay Hiremath on 2024-01-17.
//

import Foundation
import WidgetKit

class WidgetUpdateManager: UpdateManager, URLSessionDelegate, URLSessionDataDelegate {
    private var receivedData: Data?
    var completion: (() -> Void)? = nil
    private var identifier: String
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: self.identifier)
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode),
              let mimeType = response.mimeType,
              mimeType == "application/json"
        else {
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData?.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.logger.log("Server error fetching departures, \(error)")
            }
            else if let data = self.receivedData {
                do {
                    let response = try JSONDecoder().decode(Response.self, from: data) // Parse JSON
                    self.stnsDeps = response.stnsDeps
                    self.lastDepUpdateFinished = Date()
                    self.logger.log("Finished updating departures for location \(self.locationString), station count: \(self.stnsDeps.count)")
                    Cache.store(stnsDeps: self.stnsDeps, date: self.lastDepUpdateFinished!)
                } catch {
                    self.logger.error("Error parsing departures, \(error)")
                    self.lastDepUpdateStarted = nil
                }
            }
            self.numCurrentlyUpdating -= 1
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if session.configuration.identifier == "com.vinayh.Departures.DeparturesWidget" {
            logger.log("Reloading widget due to data update")
            WidgetCenter.shared.reloadAllTimelines()
            completion!()
        }
    }
    
    @MainActor
    override func updateDeparturesHelper(url: URL, configuration: ConfigurationAppIntent? = nil) async {
        logger.log("Widget update helper running")
        receivedData = Data()
        let task = urlSession.dataTask(with: url)
        task.resume()
    }
}

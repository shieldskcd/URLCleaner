// ShareViewController.swift
// This is the main file for your Share Extension

import UIKit
import Social
import MobileCoreServices

class ShareViewController: UIViewController {
    
    // MARK: - Configuration
    // Change this to your email address
    let YOUR_EMAIL = "aykons@gmail.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Extract the URL from the share sheet
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = item.attachments {
                for attachment in attachments {
                    // Check if it's a URL
                    if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                        attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (url, error) in
                            if let shareURL = url as? URL {
                                self?.handleURL(shareURL)
                            }
                        }
                    }
                    // Also check for plain text (sometimes URLs come as text)
                    else if attachment.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                        attachment.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { [weak self] (text, error) in
                            if let urlString = text as? String, let url = URL(string: urlString) {
                                self?.handleURL(url)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func handleURL(_ url: URL) {
        // Follow redirects to get the final URL
        getActualURL(from: url) { [weak self] finalURL in
            DispatchQueue.main.async {
                self?.sendEmail(with: finalURL)
            }
        }
    }
    
    func getActualURL(from url: URL, completion: @escaping (URL) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // Just get headers, not full content
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               let finalURL = httpResponse.url {
                // Return the final URL after following redirects
                completion(finalURL)
            } else {
                // If something fails, just use the original URL
                completion(url)
            }
        }
        task.resume()
    }
    
    func sendEmail(with url: URL) {
        // Create mailto URL
        let subject = "Article from Facebook"
        let body = url.absoluteString
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:\(YOUR_EMAIL)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let mailtoURL = URL(string: mailtoString) {
            // Open Mail app with pre-filled email
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(mailtoURL, options: [:]) { [weak self] _ in
                        // Close the share extension
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    }
                    return
                }
                responder = responder?.next
            }
        }
        
        // Fallback: just close the extension
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

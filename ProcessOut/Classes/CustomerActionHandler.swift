//
//  CustomerActionHandler.swift
//  ProcessOut
//
//  Created by Jeremy Lejoux on 19/09/2019.
//

import Foundation
import UIKit
import WebKit


class CustomerActionHandler {
    
    var handler: ThreeDSHandler
    var with: UIViewController
    var processOutWebView: ProcessOutWebView
    
    public init(handler: ThreeDSHandler, processOutWebView: ProcessOutWebView, with: UIViewController) {
        self.handler = handler
        self.with = with
        self.processOutWebView = processOutWebView
    }
    
    
    /// Handle a customer action request for an authorization
    ///
    /// - Parameters:
    ///   - customerAction: the customerAction returned by the auth request
    ///   - completion: completion callback
    public func handleCustomerAction(customerAction: CustomerAction, completion: @escaping (String) -> Void) {
        switch customerAction.type{
            // 3DS2 fingerprint request
        case .fingerPrintMobile:
            performFingerprint(customerAction: customerAction, handler: handler, completion: { (encodedData, error) in
                if encodedData != nil {
                    completion(encodedData!)
                    return
                }
                self.handler.onError(error: error!)
            })
            // 3DS2 challenge request
        case .challengeMobile:
            performChallenge(customerAction: customerAction, handler: handler) { (success, error) in
                guard success else {
                    completion(ProcessOut.threeDS2ChallengeError)
                    return
                }
                completion(ProcessOut.threeDS2ChallengeSuccess)
            }
            // 3DS1 web fallback
        case .url, .redirect:
            guard let url = URL(string: customerAction.value) else {
                // Invalid URL
                handler.onError(error: ProcessOutException.InternalError)
                return
            }

            // Loading the url
            let request = URLRequest(url: url)
            guard let _ = processOutWebView.load(request) else {
                handler.onError(error: ProcessOutException.InternalError)
                return
            }
            
            // Displaying the webview
            handler.doPresentWebView(webView: processOutWebView)
            
            break
            
        case .fingerprint:
            // Need to open a webview for fingerprinting fallback
            
            guard let url = URL(string: customerAction.value) else {
                // Invalid URL
                handler.onError(error: ProcessOutException.InternalError)
                return
            }
            
            // Prepare the fingerprint hiddenWebview
            let fingerprintWebView = FingerprintWebView(customerAction: customerAction, frame: with.view.frame, onResult: { (newSource) in
                completion(newSource)
            }) {
                self.handler.onError(error: ProcessOutException.BadRequest(errorMessage: "Web authentication failed", errorCode: ""))
            }
            
            // Loading the url
            let request = URLRequest(url: url)
            guard let _ = fingerprintWebView.load(request) else {
                handler.onError(error: ProcessOutException.InternalError)
                return
            }
            
            // We force the webView display
            with.view.addSubview(fingerprintWebView)
            break
        }
    }
    
    private func performFingerprint(customerAction: CustomerAction, handler: ThreeDSHandler, completion: @escaping (String?, ProcessOutException?) -> Void) {
        let decodedData = Data(base64Encoded: customerAction.value)!
        var directoryServerData: DirectoryServerData
        do {
            directoryServerData = try JSONDecoder().decode(DirectoryServerData.self, from: decodedData)
        } catch {
            completion(nil, ProcessOutException.InternalError)
            return
        }
        
        handler.doFingerprint(directoryServerData: directoryServerData) { (response) in
            do {
                guard let body = String(data: try JSONEncoder().encode(response), encoding: .utf8) else {
                    completion(nil, ProcessOutException.InternalError)
                    return
                }
                
                let miscGatewayRequest = MiscGatewayRequest(fingerprintResponse: body)
                guard let gatewayToken = miscGatewayRequest.generateToken() else {
                    completion(nil, ProcessOutException.InternalError)
                    return
                }
                
                completion(gatewayToken, nil)
            } catch {
                completion(nil, ProcessOutException.InternalError)
            }
        }
    }
    
    private func performChallenge(customerAction: CustomerAction, handler: ThreeDSHandler, completion: @escaping (Bool, ProcessOutException?) -> Void) {
        do {
            guard let decodedB64Data = Data(base64Encoded: customerAction.value) else {
                completion(false, ProcessOutException.InternalError)
                return
            }
            let authentificationChallengeData = try JSONDecoder().decode(AuthentificationChallengeData.self, from: decodedB64Data)
            handler.doChallenge(authentificationData: authentificationChallengeData) { (success) in
                completion(success, nil)
            }
        } catch {
            completion(false, ProcessOutException.InternalError)
        }
        
    }
}

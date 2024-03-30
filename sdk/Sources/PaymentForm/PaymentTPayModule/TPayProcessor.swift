//
//  TPayProcessor.swift
//  Cloudpayments
//
//  Created by Artem Eremeev on 24.03.2024.
//

import Foundation

@MainActor
final public class TPayProcessor: ProgressTPayProtocol {
    
    private var processContinuation: CheckedContinuation<Result, Never>?
    
    public init() { }
    
    public func requestIsTPayAvailable(publicId: String) async -> Bool {
        await withCheckedContinuation { continuation in
            CloudpaymentsApi.getMerchantConfiguration(publicId: publicId) { configuration in
                let tPayAvailable = configuration?.isOnButton ?? false
                continuation.resume(returning: tPayAvailable)
            }
        }
    }
    
    public func process(paymentConfiguration: PaymentConfiguration) async -> Result {
        await withCheckedContinuation { continuation in
            self.processContinuation = continuation
            self.openProcessingViewController(paymentConfiguration: paymentConfiguration)
        }
    }
    
    // MARK: - ProgressTPayProtocol
    
    func resultPayment(
        result: PaymentTPayView.PaymentAction,
        error: String?,
        transactionId: Int64?
    ) {
        switch result {
        case .success:
            processContinuation?.resume(returning: .successed(transactionId: transactionId ?? -1))
        case .close:
            processContinuation?.resume(returning: .closed)
        case .error:
            processContinuation?.resume(returning: .failed(errorMessage: error ?? ""))
        }
    }
    
    // MARK: - Private methods
    
    private func openProcessingViewController(paymentConfiguration: PaymentConfiguration) {
        let viewController = Assembly.createTPayVC(configuration: paymentConfiguration)
        viewController.delegate = self
        let topViewController = UIApplication.topViewController()
        
        DispatchQueue.main.async {
            topViewController?.present(viewController, animated: true)
        }
    }
    
}

// MARK: - ProcessorResult

extension TPayProcessor {
    
    public enum Result {
        case successed(transactionId: Int64)
        case closed
        case failed(errorMessage: String)
    }
    
}

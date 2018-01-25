import Foundation

@available(*, deprecated)
typealias InteractorExecuter = InteractorExecutor

open class InteractorExecutor {
    
    private var interactors = Dictionary<String, AnyObject>()
    
    // MARK: - Register
    
    public func registerInteractor<InteractorProtocol: Interactor, Response>
        (_ interactor: InteractorProtocol, request: InteractorRequest<Response>)
    {
        let key = String(describing: request)
        interactors[key] = InteractorWrapper(interactor: interactor)
    }
    
    // MARK: - Execute
    
    open func execute<Request: InteractorRequestProtocol>(_ request: Request) {
        let key = String(describing: request)
        let optionalValue = interactors[key]
        
        guard let value = optionalValue else {
            fireInteractorNotRegisterdError(request)
            return
        }
        
        guard let wrapper = value as? InteractorWrapper<Request> else {
            fireInteractorMismatchError(request)
            return
        }
        
        wrapper.execute(request)
    }
    
    // MARK: - GetInteractor
    
    open func getInteractor<Request: InteractorRequestProtocol>(request: Request) -> AnyObject? {
        let key = String(describing: request)
        let optional = interactors[key]
        
        guard let wrapper = optional as? InteractorWrapper<Request> else {
            return nil
        }
        
        return wrapper.wrappedInteractor
    }
    
    // MARK: - Error Handling
    
    private func fireErrorOnRequest(_ request: ErrorRequestProtocol, errorMessage: String) {
        let error = InteractorError(message: errorMessage)
        request.onError?(error)
    }
    
    private func fireInteractorNotRegisterdError(_ request: ErrorRequestProtocol) {
        let message = "ACInteractor.ACInteractorExecutor: No Interactor is registered for this request!"
        fireErrorOnRequest(request, errorMessage: message)
    }
    
    private func fireInteractorMismatchError(_ request: ErrorRequestProtocol) {
        let message = "ACInteractor.ACInteractorExecutor: Request does not match execute function of registered Interactor!"
        fireErrorOnRequest(request, errorMessage: message)
    }
    
}


// MARK: Wrapper

// Wrapper class for interactors.
// This class is required as long as Swift does not support generic protocol types as variable types.
// For instance:
// let x: Interactor<RequestType> does not work
// let x: InteractorWrapper<RequestType> does work

private class InteractorWrapper<Request> {
    
    let executeClosure: (Request) -> Void
    let wrappedInteractor: AnyObject
    
    init<I: Interactor>(interactor: I) where I.Request == Request {
        self.executeClosure = interactor.execute
        self.wrappedInteractor = interactor
    }
    
    func execute(_ request: Request) {
        executeClosure(request)
    }
    
}

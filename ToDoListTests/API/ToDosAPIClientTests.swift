//
//  ToDosAPIClientTests.swift
//  ToDoListTests
//
//  Created by Alexander Shevtsov on 03.09.2025.
//

import XCTest
@testable import ToDoList

final class ToDosAPIClientTests: XCTestCase {
    
    // MARK: - URLProtocol mock
    
    final class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
        
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canInit(with task: URLSessionTask) -> Bool { true }
        override class func canonicalRequest(
            for request: URLRequest
        ) -> URLRequest { request }
        
        override func startLoading() {
            guard let handler = Self.requestHandler else {
                client?.urlProtocol(
                    self,
                    didFailWithError: NSError(domain: "NoHandler", code: -1)
                )
                return
            }
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(
                    self,
                    didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        override func stopLoading() {}
    }
    
    private let todosURL = URL(string: "https://dummyjson.com/todos?limit=0")!
    
    private func makeClient() -> ToDosAPIClient {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockURLProtocol.self]
        config.timeoutIntervalForRequest = 1
        config.timeoutIntervalForResource = 1
        return ToDosAPIClient(urlSession: URLSession(configuration: config))
    }
    
    func test_fetchAll_success_mapsDTO() {
        let json = """
        {"todos":[
          {"id":1,"todo":"Task A","completed":false,"userId":10},
          {"id":2,"todo":"Task B","completed":true,"userId":20}
        ],
        "total":2,"skip":0,"limit":2}
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { _ in
            let http = HTTPURLResponse(
                url: self.todosURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (http, json)
        }
        let sut = makeClient()
        let exp = expectation(description: "fetch maps")
        sut.fetchAll {
            guard case let .success(items) = $0 else { return XCTFail() }
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0].title, "Task A")
            XCTAssertTrue(items[1].isDone)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    func test_fetchAll_httpError_fails() {
        MockURLProtocol.requestHandler = { _ in
            let http = HTTPURLResponse(
                url: self.todosURL,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (http, Data())
        }
        let sut = makeClient()
        let exp = expectation(description: "http error")
        sut.fetchAll { if case .failure = $0 { exp.fulfill() } else { XCTFail() } }
        wait(for: [exp], timeout: 3)
    }
}

//
//  ToDosAPIClient.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import Foundation

// MARK: - ToDosAPIClient
final class ToDosAPIClient {
    
    // MARK: - Private Properties
    private let baseURL = URL(string: "https://dummyjson.com")!
    private let urlSession: URLSession
    
    // MARK: - Init
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // MARK: - Public Methods
    func fetchAll(completion: @escaping (Result<[ToDoEntity], Error>) -> Void) {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("todos"),
            resolvingAgainstBaseURL: true
        )!
        components.queryItems = [URLQueryItem(name: "limit", value: "0")]
        
        guard let requestURL = components.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        urlSession.dataTask(with: requestURL) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(APIError.httpStatus(status)))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.emptyData))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(ToDoResponseDTO.self, from: data)
                let currentDate = Date()
                
                let entities = decodedResponse.todos.map {
                    ToDoEntity(
                        id: $0.id,
                        title: $0.todo,
                        details: nil,
                        createdAt: currentDate,
                        isDone: $0.completed
                    )
                }
                completion(.success(entities))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Types
    enum APIError: Error { case invalidURL, httpStatus(Int), emptyData }
}

// MARK: - DTO
private struct ToDoResponseDTO: Decodable {
    let todos: [ToDoDTO]
    let total: Int
    let skip: Int
    let limit: Int
}

private struct ToDoDTO: Decodable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}

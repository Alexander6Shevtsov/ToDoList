//
//  ToDosAPIClient.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import Foundation

final class ToDosAPIClient {
    
    private let baseURL = URL(string: "https://dummyjson.com")!
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func fetchAll(completion: @escaping (Result<[ToDoEntity], Error>) -> Void) {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/todos"),
            resolvingAgainstBaseURL: true
        )!
        components.queryItems = [URLQueryItem(name: "limit", value: "0")]
        
        guard let url = components.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let task = urlSession.dataTask(with: url) {
            data,
            response,
            error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse,
               (200..<300).contains(http.statusCode) == false {
                completion(.failure(APIError.httpStatus(http.statusCode)))
                return
            }
            // парсинг JSON
            guard let data = data else {
                completion(.failure(APIError.emptyData))
                return
            }
            do {
                let todosResponseDTO = try JSONDecoder().decode(
                    ToDoResponseDTO.self,
                    from: data
                )
                let importTimestamp = Date()
                let entities: [ToDoEntity] = todosResponseDTO.todos.map {
                    ToDoEntity(
                        id: $0.id,
                        title: $0.todo,
                        details: nil,
                        createdAt: importTimestamp,
                        isDone: $0.completed
                    )
                }
                completion(.success(entities))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    enum APIError: Error {
        case invalidURL
        case httpStatus(Int)
        case emptyData
    }
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
    let todo:String
    let completed: Bool
    let userId: Int
}

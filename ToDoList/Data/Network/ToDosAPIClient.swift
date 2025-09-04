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
        var components = URLComponents(url: baseURL.appendingPathComponent("/todos"), resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "limit", value: "0")]
        guard let url = components.url else { return completion(.failure(APIError.invalidURL)) }
        
        urlSession.dataTask(with: url) { data, response, error in
            if let error = error { return completion(.failure(error)) }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return completion(.failure(APIError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? -1)))
            }
            guard let data = data else { return completion(.failure(APIError.emptyData)) }
            
            do {
                let dto = try JSONDecoder().decode(ToDoResponseDTO.self, from: data)
                let now = Date()
                let entities = dto.todos.map {
                    ToDoEntity(id: $0.id, title: $0.todo, details: nil, createdAt: now, isDone: $0.completed)
                }
                completion(.success(entities))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
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

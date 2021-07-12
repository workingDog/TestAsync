//
//  ContentView.swift
//  Shared
//
//  Created by Ringo Wathelet on 2021/07/12.
//

import SwiftUI


struct Post: Decodable, Identifiable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
    var comments: [Comment]?
}

struct Comment: Decodable, Identifiable {
    let postId: Int
    let id: Int
    let name: String
    let email: String
    let body: String
}

@MainActor
class APIClient: ObservableObject {
    @Published var posts = [Post]()
    
    static let shared = APIClient()
    
    func getPosts() async {
        posts = await fetchThem()
    }
    
    func getCommentsFor(post: Post) async {
        let comments: [Comment] = await fetchThem(with: post)
        if let ndx = posts.firstIndex(where: {$0.id == post.id}) {
            posts[ndx].comments = comments
        }
    }
    
    func getAll() async {
        await withTaskGroup(of: Void.self) { group in
            await getPosts()
            for post in posts {
                group.async { await self.getCommentsFor(post: post) }
            }
        }
    }
    
    private func fetchThem<T: Decodable>(with post: Post? = nil) async -> [T] {
        var url: URL
        if post == nil {
            url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
        } else {
            url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(post!.id)/comments")!
        }
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // throw URLError(.badServerResponse)
                print(URLError(.badServerResponse))
                return []
            }
            let results = try JSONDecoder().decode([T].self, from: data)
            return results
        }
        catch {
            return []
        }
    }
    
}

struct ContentView: View {
    
    @StateObject var apiClient = APIClient.shared
    
    var body: some View {
        List {
            ForEach(apiClient.posts, id: \.id) { post in
                VStack {
                    Text(post.title)
                    if let comments = post.comments {
                        Text(comments.first?.name ?? "").foregroundColor(.red)
                        Text(" " + String(comments.count)).foregroundColor(.green)
                    }
                }
            }
        }
        .task {
            await apiClient.getAll()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


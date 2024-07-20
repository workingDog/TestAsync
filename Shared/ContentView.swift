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

@Observable class PostsManager {
    var posts = [Post]()
    
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
                group.addTask { await self.getCommentsFor(post: post) }
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
                // throw URLError(.badServerResponse)   //  todo
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
    @State var manager = PostsManager()
    
    var body: some View {
        List {
            ForEach(manager.posts) { post in
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
            await manager.getAll()
        }
    }
}

#Preview {
    ContentView()
}

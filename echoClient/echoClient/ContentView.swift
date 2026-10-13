//
//  ContentView.swift
//  echoClient
//  
//  Created by keeki-fami on 2026/09/30
//  
//

import SwiftUI
import GRPCCore // provide grpc runtime
import GRPCNIOTransportHTTP2 // provide networking code
import SwiftProtobuf // interact with protobuf message

struct ContentView: View {
    @State private var requestText: String = ""
    @State private var responseText: String = ""
    @Environment(ClientManager.self) var manager
    var body: some View {
        VStack {
            TextField("送信内容を入力", text: $requestText)
            Text("返答内容：\(responseText)")
            
            Button("送信する。") {
                Task {
                    do {
                        try await manager.withClient { client in
                            let echo = Echo_Echo.Client(wrapping: client)
                            var request = Echo_echoRequest()
                            request.text = self.requestText
                            let response = try await echo.doEcho(request)
                            self.responseText = response.text
                        }
                    } catch {
                        print("gRPC error: \(error)")
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

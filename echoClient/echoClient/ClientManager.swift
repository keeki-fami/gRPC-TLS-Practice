import GRPCCore
import GRPCNIOTransportHTTP2
import Synchronization
import SwiftUI


func readBinaryFile_UInt8() -> [UInt8]{
    guard let fileURL = Bundle.main.url(forResource: "root", withExtension: ".der") else {
        fatalError("failed to get file")
    }
    var binaryData = Data();
    do {
        // ファイル読み込み
        binaryData = try Data(contentsOf: fileURL, options: [])

    } catch {
        fatalError("failed to read the file.\n dataURL: \(fileURL)")
    }
    //return binaryData.encodedHexadecimals!;
    return [UInt8](binaryData)
}

@Observable
final class ClientManager: Sendable {
    fileprivate let state = Mutex(State.disconnected)

    static func makeTransport() throws -> HTTP2ClientTransport.TransportServices {
        try .http2NIOTS(
            target: .ipv4(address: "127.0.0.1", port: 50051),
//            transportSecurity: .plaintext
            transportSecurity: .tls(configure: { configure in
                let cert = readBinaryFile_UInt8()
                configure.trustRoots = .certificates([.bytes(cert, format: .der)])
            })
            
//            transportSecurity: .mTLS(identityProvider: {
//                
//            }, configure: { config in
//                config.trustRoots = .certificates([.bytes(readBinaryFile_UInt8(), format: .der)])
//            })
            

        )
    }

    func withClient(
        body: (_ client: GRPCClient<HTTP2ClientTransport.TransportServices>) async throws -> Void
    ) async throws {
        let client = try connectIfNecessary()
        try await body(client)
    }

    private func connectIfNecessary() throws -> GRPCClient<HTTP2ClientTransport.TransportServices> {
        try self.state.withLock { state in
            try state.connectIfNecessary()
        }
    }

    func disconnect() {
        let client = self.state.withLock { state in
            state.disconnect()
        }

        client?.beginGracefulShutdown()
    }
}

extension ClientManager {
    enum State {
        case connected(GRPCClient<HTTP2ClientTransport.TransportServices>, Task<Void, any Error>)
        case disconnected
    }
}

extension ClientManager.State {
    mutating func connectIfNecessary() throws -> GRPCClient<HTTP2ClientTransport.TransportServices> {
        switch self {
        case .connected(let client, _):
            return client

        case .disconnected:
            let client = try GRPCClient(transport: ClientManager.makeTransport())
            let task = Task { try await client.runConnections() }
            self = .connected(client, task)
            return client
        }
    }

    mutating func disconnect() -> GRPCClient<HTTP2ClientTransport.TransportServices>? {
        switch self {
        case .connected(let client, _):
            self = .disconnected
            return client
        case .disconnected:
            return nil
        }
    }
}

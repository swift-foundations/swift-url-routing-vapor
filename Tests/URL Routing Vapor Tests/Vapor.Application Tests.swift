//
//  Vapor.Application Tests.swift
//  swift-url-routing-vapor — URL Routing Vapor Tests
//
//  Coverage for the router-mounting half of the bridge.
//

import Testing
import Vapor
import VaporTesting

@testable import URL_Routing_Vapor

extension Vapor.Application {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        /// Matches exactly `GET /hello`; anything else fails to parse.
        struct Router: Parser.`Protocol`, Sendable {}
    }
}

extension Vapor.Application.Test.Router {
    // swift-linter:disable:next unification typealias
    // REASON: Parser.Protocol associated-type witness (Input); every conformer must declare this exact typealias.
    typealias Input = RFC_3986.URI.Request.Data
    typealias Output = Void

    struct Mismatch: Swift.Error {}
    typealias Failure = Mismatch

    func parse(_ input: inout Input) throws(Mismatch) {
        guard Array(input.path) == ["hello"] else { throw Mismatch() }
    }
}

extension Vapor.Application.Test.Unit {
    @Test
    func `mounted router answers a parsed route`() async throws {
        let app = try await Application.make(.testing)

        app.mount(Vapor.Application.Test.Router()) { _ in "hello!" }

        try await app.testing().test(.GET, "hello") { response async in
            #expect(response.status == .ok)
            #expect(response.body.string == "hello!")
        }

        try await app.asyncShutdown()
    }
}

extension Vapor.Application.Test.`Edge Case` {
    @Test
    func `unmatched requests fall through to the next responder`() async throws {
        let app = try await Application.make(.testing)

        app.mount(Vapor.Application.Test.Router()) { _ in "hello!" }

        try await app.testing().test(.GET, "elsewhere") { response async in
            #expect(response.status == .notFound)
        }

        try await app.asyncShutdown()
    }
}

extension Vapor.Application.Test.Integration {
    @Test
    func `responder-shaped mount receives the request and answers with a response`() async throws {
        let app = try await Application.make(.testing)

        app.mount(Vapor.Application.Test.Router()) { request, _, _ in
            Response(status: .ok, body: .init(string: "from \(request.url.path)"))
        }

        try await app.testing().test(.GET, "hello") { response async in
            #expect(response.status == .ok)
            #expect(response.body.string == "from /hello")
        }

        try await app.asyncShutdown()
    }
}

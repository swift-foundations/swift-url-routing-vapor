//
//  RFC_3986.URI.Request.Data Tests.swift
//  swift-url-routing-vapor — URLRoutingVapor Tests
//
//  Coverage for the Vapor.Request → request-data conversion half of the
//  bridge.
//

import Testing
import Vapor

@testable import URLRoutingVapor

extension RFC_3986.URI.Request.Data {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}

extension RFC_3986.URI.Request.Data.Test.Unit {
    @Test
    func `conversion maps method, URL components, and headers`() async throws {
        let app = try await Application.make(.testing)

        let request = Vapor.Request(
            application: app,
            method: .POST,
            url: "https://example.com:8080/a/b?x=1&x=2&y=z#frag",
            headers: ["Accept": "text/html"],
            on: app.eventLoopGroup.next()
        )

        let data = RFC_3986.URI.Request.Data(request: request)

        #expect(data != nil)
        #expect(data?.host == "example.com")
        #expect(data?.port == 8080)
        #expect(data?.path == "/a/b")
        #expect(data?.query["x"] == ["1", "2"])
        #expect(data?.query["y"] == ["z"])
        #expect(data?.fragment == "frag")
        #expect(data?.headers["Accept"]?.first ?? nil == "text/html")

        try await app.asyncShutdown()
    }
}

extension RFC_3986.URI.Request.Data.Test.`Edge Case` {
    @Test
    func `userinfo is absent without a Basic Authorization header`() async throws {
        let app = try await Application.make(.testing)

        let request = Vapor.Request(
            application: app,
            method: .GET,
            url: "https://example.com/",
            on: app.eventLoopGroup.next()
        )

        let data = RFC_3986.URI.Request.Data(request: request)
        #expect(data != nil)
        #expect(data?.userinfo == nil)

        try await app.asyncShutdown()
    }
}

extension RFC_3986.URI.Request.Data.Test.Integration {
    @Test
    func `Basic Authorization credentials map onto the RFC 3986 userinfo component`() async throws {
        let app = try await Application.make(.testing)

        // RFC 7617 §2 example vector.
        let request = Vapor.Request(
            application: app,
            method: .GET,
            url: "https://example.com/private",
            headers: ["Authorization": "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="],
            on: app.eventLoopGroup.next()
        )

        let data = RFC_3986.URI.Request.Data(request: request)
        #expect(data?.userinfo == "Aladdin:open sesame")

        try await app.asyncShutdown()
    }
}

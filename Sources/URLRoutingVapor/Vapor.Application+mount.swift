// Vapor.Application+mount.swift
// swift-url-routing-vapor — URLRoutingVapor
//
// Heritage: derived from pointfreeco/vapor-routing @ 0.1.3 (MIT License,
// Copyright (c) 2022 Point-Free), via boiler's re-expression (Sendable
// conformances, AsyncResponder-parameterized closure, convenience mount).
// Converged here from boiler as one half of the URLRouting × Vapor bridge
// (integration-mints arc, 2026-07-12). The dependency-scoped mount overload
// stays donor-side: its dependency keys belong to the server-foundation
// stack, not to this bridge.
//
// MIT License: Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation files
// (the "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions: The above copyright notice and this permission
// notice shall be included in all copies or substantial portions of the
// Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

public import URLRouting
public import Vapor

extension Vapor.Application {
    /// Mounts a router to the Vapor application.
    ///
    /// The installed middleware parses each incoming request with `router`;
    /// parsed routes are answered by `closure`, and unmatched requests fall
    /// through to the next responder.
    ///
    /// - Parameters:
    ///   - router: A parser over inputs of `RFC_3986.URI.Request.Data`.
    ///   - closure: Responds to a parsed route with a Vapor response;
    ///     receives the request and the next responder for fall-through
    ///     composition.
    public func mount<Router: Parser.`Protocol` & Sendable>(
        _ router: Router,
        use closure:
            @Sendable @escaping (Request, Vapor.AsyncResponder, Router.Output) async throws ->
            Vapor.Response
    ) where Router.Input == RFC_3986.URI.Request.Data {
        self.middleware.use(Mount(router: router, respond: closure))
    }

    /// Mounts a router, answering parsed routes with any encodable response.
    ///
    /// - Parameters:
    ///   - router: A parser over inputs of `RFC_3986.URI.Request.Data`.
    ///   - closure: Maps a parsed route to any `AsyncResponseEncodable`.
    public func mount<Router: Parser.`Protocol` & Sendable>(
        _ router: Router,
        use closure: @escaping @Sendable (Router.Output) async throws -> any AsyncResponseEncodable
    ) where Router.Input == RFC_3986.URI.Request.Data, Router.Output: Sendable {
        self.mount(router) { request, _, output in
            try await closure(output).encodeResponse(for: request)
        }
    }
}

/// The routing middleware a mount installs: parses each request with the
/// mounted router, answers parsed routes via the stored responder, and lets
/// unmatched requests fall through to the next responder.
private struct Mount<Router: Parser.`Protocol` & Sendable>
where Router.Input == RFC_3986.URI.Request.Data {
    let router: Router
    let respond: @Sendable (Request, AsyncResponder, Router.Output) async throws -> Vapor.Response
}

extension Mount: AsyncMiddleware {
    func respond(
        to request: Request,
        chainingTo next: AsyncResponder
    ) async throws -> Response {

        if request.body.data == nil {
            try await _ = request.body.collect(
                max: request.application.routes.defaultMaxBodySize.value
            )
            .get()
        }

        guard var requestData = RFC_3986.URI.Request.Data(request: request)
        else { return try await next.respond(to: request) }

        let route: Router.Output
        do {
            route = try self.router.parse(&requestData)
        } catch let routingError {
            do {
                return try await next.respond(to: request)
            } catch {
                // Log routing errors concisely.
                request.logger.debug(
                    "Route not found",
                    metadata: [
                        "path": .string(request.url.path),
                        "method": .string(request.method.rawValue),
                        "error": .string(routingError.localizedDescription),
                    ]
                )

                guard request.application.environment == .development
                else { throw error }

                // Only show detailed routing errors in development.
                return Response(status: .notFound, body: .init(string: "Not Found"))
            }
        }
        return try await self.respond(request, next, route).encodeResponse(for: request)
    }
}

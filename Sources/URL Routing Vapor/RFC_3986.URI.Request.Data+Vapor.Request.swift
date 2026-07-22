// RFC_3986.URI.Request.Data+Vapor.Request.swift
// swift-url-routing-vapor — URL Routing Vapor
//
// Heritage: derived from pointfreeco/vapor-routing @ 0.1.3
// (Sources/VaporRouting/URLRequestData+Vapor.Request.swift, MIT License,
// Copyright (c) 2022 Point-Free). Re-expressed 2026-07-12 against the
// institute swift-url-routing rewrite's native
// `RFC_3986.URI.Request.Data.init(method:scheme:userinfo:...)` surface
// (vapor-routing dissolution, repotraffic sprint S2; the pointfree
// user/password pair maps onto the RFC 3986 `userinfo` component, and the
// method string onto `HTTP.Method`). Converged here from
// swift-server-foundation-vapor as one half of the URLRouting × Vapor
// bridge (integration-mints arc, 2026-07-12).
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

import Foundation
import HTTP_Standard
import OrderedCollections
public import URLRouting
public import Vapor

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension RFC_3986.URI.Request.Data {
    /// Initializes parseable request data from a Vapor request.
    ///
    /// - Parameter request: A Vapor request.
    public init?(request: Vapor.Request) {
        guard
            let url = URL(string: request.url.string),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        let body: Foundation.Data?
        if var buffer = request.body.data,
            let bytes = buffer.readBytes(length: buffer.readableBytes)
        {
            body = Foundation.Data(bytes)
        } else {
            body = nil
        }

        self.init(
            method: HTTP.Method(rawValue: request.method.rawValue),
            scheme: request.url.scheme,
            userinfo: {
                if let basic = request.headers.basicAuthorization {
                    return "\(basic.username):\(basic.password)"
                }
                return nil
            }(),
            host: request.url.host,
            port: request.url.port,
            path: request.url.path,
            query: components.queryItems?.reduce(into: [:]) { query, item in
                query[item.name, default: []].append(item.value)
            } ?? [:],
            fragment: components.fragment,
            headers: .init(
                request.headers.map { key, value in
                    (
                        key,
                        value.split(separator: ",", omittingEmptySubsequences: false).map {
                            String($0)
                        }
                    )
                },
                uniquingKeysWith: { $0 + $1 }
            ),
            body: body
        )
    }
}

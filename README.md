# swift-url-routing-vapor

![Development Status](https://img.shields.io/badge/status-pre--cutover_integration_package-orange.svg)

Vapor integration for [swift-url-routing](https://github.com/swift-foundations/swift-url-routing).

> **Status: pre-cutover integration package.** This package converges the
> URLRouting × Vapor bridge previously spread across two server packages.
> Those donors still carry their own copies today; switching them here is a
> planned, separate change.

## Overview

The two halves of one bridge:

- **Request-data conversion** — `RFC_3986.URI.Request.Data.init?(request:)`
  turns a `Vapor.Request` into parseable request data: method, URL
  components, headers (including Basic-auth userinfo), and collected body.
- **Router mounting** — `Vapor.Application.mount(_:use:)` installs middleware
  that parses each incoming request with a URLRouting router. Parsed routes
  are answered by your closure (either returning a `Vapor.Response` with
  access to the next responder, or any `AsyncResponseEncodable`); unmatched
  requests fall through to the rest of your application.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-url-routing-vapor.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "URLRoutingVapor", package: "swift-url-routing-vapor")
    ]
)
```

## Quick Start

```swift
import URLRoutingVapor

let app = try await Application.make(.detect())
app.mount(SiteRouter()) { route in
    switch route {
    case .home: return HomePage()
    case .about: return AboutPage()
    }
}
```

## License

The package is licensed under the [Apache License, Version 2.0](LICENSE.md);
it contains code derived from
[pointfreeco/vapor-routing](https://github.com/pointfreeco/vapor-routing)
(MIT), whose license notice is preserved in the affected source files.

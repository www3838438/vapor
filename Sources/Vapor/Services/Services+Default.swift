import Async
import Console
import Dispatch
import HTTP
import Foundation
import Routing
import Service

extension Services {
    /// The default Services included in the framework.
    public static func `default`() -> Services {
        var services = Services()

        // register engine server and default config settings
        services.register(Server.self) { container in
            return try EngineServer(
                config: container.make(for: EngineServer.self),
                container: container
            )
        }
        services.register { container in
            return EngineServerConfig()
        }

        // register middleware
        services.register { container -> MiddlewareConfig in
            var config = MiddlewareConfig()
            config.use(DateMiddleware.self)
            config.use(ErrorMiddleware.self)
            return config
        }
        
        services.register { container in
            return DateMiddleware()
        }
        
        services.register { worker in
            return ErrorMiddleware(environment: worker.environment)
        }

        // register router
        services.register(Router.self, isSingleton: true) { container in
            return EngineRouter.default()
        }

        // register content coders
        services.register { container in
            return ContentConfig.default()
        }

        // register terminal console
        services.register(Console.self) { container in
            return Terminal()
        }
        services.register(Responder.self) { container in
            return try RouterResponder(
                router: container.make(for: Responder.self)
            )
        }

        services.register { worker -> ServeCommand in
            let responder = try worker.make(Responder.self, for: ServeCommand.self)

            let middleware = try worker
                .make(MiddlewareConfig.self, for: ServeCommand.self)
                .resolve(for: worker)

            return try ServeCommand(
                server: worker.make(for: ServeCommand.self),
                responder: middleware.makeResponder(chainedto: responder)
            )
        }
        services.register { container -> CommandConfig in
            return CommandConfig.default()
        }
        services.register { container -> RoutesCommand in
            return try RoutesCommand(
                router: container.make(for: RoutesCommand.self)
            )
        }

        // worker
        services.register { container -> EphemeralWorkerConfig in
            let config = EphemeralWorkerConfig()
            config.add(Request.self)
            config.add(Response.self)
            return config
        }

        // directory
        services.register { container -> DirectoryConfig in
            return DirectoryConfig.default()
        }

        // logging
        services.register(Logger.self) { container -> ConsoleLogger in
            return try ConsoleLogger(
                console: container.make(for: ConsoleLogger.self)
            )
        }
        services.register(Logger.self) { container -> PrintLogger in
            return PrintLogger()
        }

        return services
    }
}
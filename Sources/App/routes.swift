import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    // Hello routes tests
    router.get("hello", "people") { req -> String in
        return "Hello People!"
    }
    
    router.get("hello", String.parameter) { req -> String in
        let name = try req.parameters.next(String.self)
        return "Hello, \(name)!"
    }
    
    // Awesome people
    router.post("api", "v1", "person") { req -> Future<Person> in
        return try req.content.decode(Person.self)
            .flatMap(to: Person.self) { person in
                return person.save(on: req)
        }
    }
    
    router.get("api", "v1", "people") { req -> Future<[Person]> in
        return Person.query(on: req).all()
    }
    
    router.get("api", "v1", "person", "random") { req -> Future<Person> in
        
        // TODO
    }

}

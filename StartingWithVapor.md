# Starting with Vapor

* Vapor is an open-source framework that allows us to build Web Applications (APIs, Websites)
* Built by Tanner Nelson, Logan Wright and a whole lot more contributors on Github
* Modular
* Backed by Nodes

## Setup:
  - use `eval "$(curl -sL check.vapor.sh)"` to check requirements Xcode 9  and Swift Version (Quick to install)
  - required Homebrew --> `brew install vapor/tap/vapor` (Takes around 1min)

## Configure the first App:

- Create the directory `mkdir AwesomePeople`
- Move into the created directory `cd AwesomePeople/`
- Create the Vapor project `vapor new AwesomePeople`
- Mention Vapor creation templates (API; Web)(defaults to API which is what we want)
- Move into the created project `cd AwesomePeople`
- Build the project to Fetch and Build all the dependencies `vapor build` (Fetching ~1min; Building ~1min; Total 3min)

## Review the Project:

  - Open the Vapor project in Xcode with `vapor Xcode` (Generates the *.xcproject)
  - `Package.swift` to show the project dependencies
    - Vapor -->
    - BD Driver for SQL
  - `app.swift` 
    - is like the Main
  - `configure.swift` 
    - all the configureation
    - register the DB driver
    - create the DB object migrations to create all the Tables in the DB
      (migrations may be used to Seed the DB)
  - `routes.swift` 
    - where we build our routes/endpoints

- Run the project in the local machine `vapor run`

```bash
Running AwesomeList ...
[ INFO ] Migrating 'sqlite' database (MigrateCommand.swift:20)
[ INFO ] Preparing migration 'Todo' (Migrations.swift:109)
[ INFO ] Migrations complete (MigrateCommand.swift:24)
Running default command: .build/debug/Run serve
Server starting on http://localhost:8080
```

> "Go to: http://localhost:8080/hello

> run `vapor xcode -y` to Generate and .xcproject and open it on Xcode

- create a new Route
```ruby
router.get("hello", "people") { req -> String in
    return "Hello People!"
}
```

- modify created route to receive a dynamic parameter
```ruby
router.get("hello", String.parameter) { req -> String in
    let name = try req.parameters.next(String.self)
    return "Hello, \(name)!"
}
```
  
**QUESTIONS**  
* What is the `String.parameter`
* What does `.next(String.self)` do

## Our first Model:

- Delete Models folder content
- New File >> Swift >> Person
- Add required Imports
```ruby
import Vapor
import FluentSQLite
```

FluentSQLite --> DB Driver

- Create a Struct `Person`
- Extend Person to conform to `Fluent.Model` 
```ruby
struct Person: Codable {
   var id: Int?
   var name: String
   
   init(name: String) {
       self.name = name
   }
}

extension Person: Model {
   typealias Database = SQLiteDatabase
   typealias ID = Int
   public static var idKey: IDKey = \Person.id
}
```

Person --> DB Table with 2 rows `id` and `name`

This:
1. Tell Fluent what database to use for this model. The template is already configured to use SQLite.
2. Tell Fluent what type the ID is.
3. Tell Fluent the key path of the model’s ID property.

- Extend Person to conform to SQLiteModel 

```ruby 
extension Person: SQLiteModel {} 
```

- Extend Person to conform to `Migration` to allow the creation of the Tables based in our Model

```ruby 
extension Person: Migration {}
```

- Implement `Content` protocol so we don't worry how the Response handles our project
```ruby 
extension Person: Content {}
```

- Add the created Person Model to the Migrations so it creates the table in the configuration step
`migrations.add(model: Person.self, database: .sqlite)`

Fluent supports multiple DB types

These Migrations only run once when you run the project

* Clean Project for TODO Model
* Run and Check the Migrations in Console

**QUESTION**: What does `Content` do


## Our first CRUD Routes for Person:

- Create a POST for creating new Person entries
```ruby
  router.post("api", "v1", "person") { req -> Future<Person> in
      return try req.content.decode(Person.self)
          .flatMap(to: Person.self) { person in
              return person.save(on: req)
      }
  }
```

* create a new endpoint
* versioning with `v1`
* this operation returns a Future (in Vapor 2 operations were Synchronous, Futures allows for handling requests Async)
* Try to decode a `Person` object from the body of the request --> we get a `Future<Person>`
* `.flatMap(to:)` allows us to use the `Person` inside `Future<Person>` (`flatMap(to:)` is part of a set of operators from Vapor to manipulate Futures)
* `person.save(on: req)`

**Question** Future<T> --> T requires to be Content why?

- Test POST in POSTMAN

> Configure POST Request with URL `http://localhost:8080/api/v1/person`

> Header "Content-Type": "application/json"

> Body JSON 
```json
{"name": "David"}
```

> Server should respond
```json
{
   "id": 1,
   "name": "David"
}
```

> Next Person POST should increment the ID automatically
```json
{"name": "Francisco"}"
```

(Next POST Response)
```json
{
   "id": 2,
   "name": "Francisco"
}
```

- Create a GET got listing all `Person` entries
```ruby
router.get("api", "v1", "people") { req -> Future<[Person]> in
    return Person.query(on: req).all()
}
```

## Filter/Sort Query

We need to import Fluent first to have the query
```ruby
import Fluent
```

- Refactor the GET people endpoint to allow a QueryParameter for sorting the list
```ruby
router.get("api", "v1", "people") { req -> Future<[Person]> in
    
    switch req.query[String.self, at: "sort"] {

    case "ascending":
        return Person.query(on: req).sort(\Person.name, .ascending).all()
    case "descending":
        return Person.query(on: req).sort(\Person.name, .descending).all()
    default:
        return Person.query(on: req).all()
    }
}
```

**Question** How does query[<Type>, <Keypath>] work inside

## Randomize

```ruby
router.get("api", "v1", "person", "random") { req -> Future<Person> in
    
    return Person.query(on: req)
        .all()
        .flatMap(to: Person.self) { people in
            
            let randomNumber: Int
            #if os(Linux)
            srandom(UInt32(time(nil)))
            randomNumber = Int(random() % people.count) + 1
            #else
            randomNumber = Int(arc4random_uniform(UInt32(people.count))) + 1
            #endif
            
            return Person.query(on: req)
                .filter(\.id == randomNumber)
                .first()
                .map(to: Person.self) { person in
                    
                    guard let person = person else {
                        
                        throw Abort(.notFound)
                    }
                    
                    return person
            }
        }
}
```

* Ideal Query should have the OrderByRandom of SQL

```
SELECT column FROM table
ORDER BY RAND()
LIMIT 1
```

> Vapor Fluent Query doesn't support this, see: https://github.com/vapor/fluent/issues/442

## Deploy

> Create a new Account in https://dashboard.vapor.cloud

> run in Terminal `vapor cloud login`

> run in Terminal `vapor cloud deploy`

## Side notes

### Persistence

We've used SQLite in the example but you can use to persist data:
- PostgreSQL
- MySQL
- MongoDB

### Leaf

Leaf is a templating language that can be used with HTML and Swift.

You can build your web application's UI with leaf components.

### Side Ideas

- By using `Codable` and Protocols we can reuse the same Models into our iOS Projects
- Same language stack in whole project
- Build your own API with no Backend background
- Deploy with 2 commands
- Set up a testing environment for your projects

### Resources

- [Vapor Docs](https://docs.vapor.codes/3.0/)
- ["Server Side Swift with Vapor" by Ray Wenderlich](https://store.raywenderlich.com/products/server-side-swift-with-vapor)
- [TIL App in Vapor](https://github.com/raywenderlich/vapor-til)
- [Martim Lasek Tutorials on Medium](https://medium.com/@martinlasek)
- Join the [Vapor Discord](https://discordapp.com/invite/vapor)

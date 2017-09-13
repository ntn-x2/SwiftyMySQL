///Enum representing the CRUD operations possible on a DB
public enum DBOperation {
    case create
    case read
    case update
    case delete
}

///Protocol describing the required behaviour for each single table in the database
public protocol DBTable {
    
    func create() throws -> QueryDetails?
    func read() throws -> QueryDetails?
    func update() throws -> QueryDetails?
    func delete() throws ->QueryDetails?
    
    var tableName: String { get }
}

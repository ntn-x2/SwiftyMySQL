import MySQL
import CMySQL

public typealias QueryResultHandler = ((Node) throws -> Any?)

///A single operation representing a simple query (with no JOINs or special filter clauses)
public struct DBTransactionOperation {
    
    ///The CRUD operation to perform
    let type: DBOperation
    ///The table on which to perfom the operation
    let table: DBTable
    ///The handler handling the result of the query, if the query does not throws an error before completing
    let handler: QueryResultHandler?
    
    public init(type: DBOperation, table: DBTable, handler: QueryResultHandler?) {
        self.type = type
        self.table = table
        self.handler = handler
    }
}

///A class representing a sequence of operations on the DB. It has support for atomic transactions, so that rolling back at any point before committing resets the state of the DB to what it was before starting the transaction.
public final class DBTransaction {
    
    //The connection to the DB
    let connection: Connection
    
    /**
     Initialize a new connection to the DB.
     - Parameter database: The database on which open the connection.
     - throws: A MySQLError if the connection with the given DB cannot be made
     */

    public init(database: Database) throws {
        self.connection = try database.makeConnection()
    }
    
    /**
     Start a new transaction using the instance connection with the provided DB.
     - throws: A MySQLError if it is not possible to execute the operation.
     */
    public func start() throws {
        try self.manual("START TRANSACTION")
    }

    /**
     Commit the transaction state to the provided DB using the instance connection.
     - throws: A MySQLError if it is not possible to execute the operation.
     */
    public func commit() throws {
        try self.manual("COMMIT")
    }
    
    /**
     Rolls back the transaction state to the provided DB using the instance connection.
     - throws: A MySQLError if it is not possible to execute the operation.
     */
    public func rollback() throws {
        try self.manual("ROLLBACK")
    }
    
    /**
     Execute the provided operation against the given DB. It can also be called without an ongoing transaction.
     - Parameter operation: The operation to execute.
     - throws: A MySQLError if anything goes wrong with the query. A DBError if the operation is not supported on the specified table.
     - returns: The result of the handler called on the query result.
     */
    @discardableResult
    public func executeOperation(_ operation: DBTransactionOperation) throws -> Any? {
        var queryDetails: QueryDetails?
        
        switch operation.type {
        case .create:
            queryDetails = try operation.table.create()
        case .read:
            queryDetails = try operation.table.read()
        case .update:
            queryDetails = try operation.table.update()
        case .delete:
            queryDetails = try operation.table.delete()
        }
        
        guard queryDetails != nil else { throw DBError.unsupportedOperation }
        
        return try self.execute(queryDetails: queryDetails!, handler: operation.handler)
    }
    
    
    
    //MARK: Private interface
    
    
    private func execute(queryDetails: QueryDetails, handler: QueryResultHandler?) throws -> Any? {
        do {
            let queryResult = try self.connection.execute(queryDetails.string, queryDetails.parameters ?? [])
            return try handler?(queryResult)
        } catch {
            try self.rollback()
            throw error
        }
    }
    
    private func manual(_ query: String) throws {
        guard mysql_query(self.connection.cConnection, query) == 0 else {
            throw DBError.uncaughtError
        }
    }
}

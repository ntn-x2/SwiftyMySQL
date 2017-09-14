import Node
import MySQL

public protocol QueryDetails {
    var string: String { get }
    var parameters: [NodeRepresentable]? { get }
}

public struct LastIDQuery: QueryDetails {
    public let string: String
    public let parameters: [NodeRepresentable]?
    
    public init() {
        self.string = "SELECT LAST_INSERT_ID()"
        self.parameters = nil
    }
}

public struct RowCount: QueryDetails {
    public let string: String
    public let parameters: [NodeRepresentable]?
    
    public init() {
        self.string = "SELECT ROW_COUNT()"
        self.parameters = nil
    }
}

struct CustomQuery: QueryDetails {
    let string: String
    let parameters: [NodeRepresentable]?
    
    init(string: String, parameters: [NodeRepresentable]?=nil) {
        self.string = string
        self.parameters = parameters
    }
}

/**
 An abstract class representing a DB entity. It provides basic logic about how to prepare a CRUD query with the needed parameters as well.
 */
open class AbstractDBTable {
    
    /**
     Queries the database with a custom query with its associated parameters.
     
     - Parameter queryDetails: A tuple containing the query string (preferably parametrized) and its associated values, if parametrized.
     - Parameter withConnection: A valid connection to a database against which the query can be executed.
     
     - Throws: MySQLError if the connection is not valid, for several reasons.
     
     - Returns: A Node representing the result of the query.
    */
    public static func executeCustomQuery(queryDetails: QueryDetails, withConnection connection: Connection) throws -> Node {
        return try connection.execute(queryDetails.string, queryDetails.parameters ?? [])
    }
    
    internal func prepareCreateQuery(data: [String: NodeRepresentable], tableName: String) -> QueryDetails {
        
        var query = "INSERT INTO \(tableName) ($$$___$$$$$____$$$$) VALUES (£££___£££££____££££)"
        var queryParameters: [NodeRepresentable] = [Node](repeating: nil, count: data.count)
        
        var columnsDefinition = ""
        var valuesDefinition = ""
        
        data.enumerated().forEach { index, parameter in
            queryParameters[index] = parameter.value
            columnsDefinition += "\(parameter.key), "
            valuesDefinition += "?, "
        }
        
        columnsDefinition = columnsDefinition.trimmingCharacters(in: [",", " "])
        valuesDefinition = valuesDefinition.trimmingCharacters(in: [",", " "])
        
        query = query.replacingOccurrences(of: "$$$___$$$$$____$$$$", with: columnsDefinition)
        query = query.replacingOccurrences(of: "£££___£££££____££££", with: valuesDefinition)
        
        return CustomQuery(string: query, parameters: queryParameters)
    }
    
    internal func prepareReadQuery(filter: [String: NodeRepresentable]?=nil, projection: [String]?=nil, tableName: String) -> QueryDetails {
        
        let projectionSubQuery = projection?.joined(separator: ", ").trimmingCharacters(in: [" ", ","])
        let filterSubQuery = filter?.enumerated().reduce((filterValues: "", filterParameters: [NodeRepresentable]())) { query, nextFilter in
            return ( query.filterValues + "\(nextFilter.offset == 0 ? "" : " AND ")\(nextFilter.element.key) = ?", query.filterParameters + [nextFilter.element.value])
        }
        
        var query = "SELECT \(projectionSubQuery ?? "*") FROM \(tableName)"
        var queryParameters: [NodeRepresentable] = []
        
        if filterSubQuery != nil {
            query.append(" WHERE \(filterSubQuery!.filterValues)")
            queryParameters = filterSubQuery!.filterParameters
        }
        
        return CustomQuery(string: query, parameters: queryParameters)
    }
    
    internal func prepareUpdateQuery(data: [String: NodeRepresentable], filter: [String: NodeRepresentable]?=nil, tableName: String) -> QueryDetails {
        
        let filterSubQuery = filter?.enumerated().reduce((filterValues: "", filterParameters: [NodeRepresentable]())) { query, nextFilter in
            return ( query.filterValues + "\(nextFilter.offset == 0 ? "" : " AND ")\(nextFilter.element.key) = ?", query.filterParameters + [nextFilter.element.value])
        }
        
        var query = "UPDATE \(tableName) SET "
        var queryParameters: [NodeRepresentable] = [Node](repeating: nil, count: data.count)
        
        data.enumerated().forEach { index, parameter in
            query.append("\(parameter.key) = ?, ")
            queryParameters[index] = parameter.value
        }
        
        query = query.trimmingCharacters(in: [",", " "])
        
        if filterSubQuery != nil {
            query.append(" WHERE \(filterSubQuery!.filterValues)")
            queryParameters.append(contentsOf: filterSubQuery!.filterParameters)
        }
        
        return CustomQuery(string: query, parameters: queryParameters)
    }
    
    internal func prepareDeleteQuery(filter: [String: NodeRepresentable]?=nil, tableName: String) -> QueryDetails {
        
        let filterSubQuery = filter?.enumerated().reduce((filterValues: "", filterParameters: [NodeRepresentable]())) { query, nextFilter in
            return ( query.filterValues + "\(nextFilter.offset == 0 ? "" : " AND ")\(nextFilter.element.key) = ?", query.filterParameters + [nextFilter.element.value])
        }
        
        var query = "DELETE FROM \(tableName)"
        var queryParameters: [NodeRepresentable] = []
        
        if filterSubQuery != nil {
            query.append(" WHERE \(filterSubQuery!.filterValues)")
            queryParameters = filterSubQuery!.filterParameters
        }
        
        return CustomQuery(string: query, parameters: queryParameters)
    }
}

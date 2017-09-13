import Node

/**
 Errors thrown when a bad-formatted query is trying to be executed against the DB.
 - missingRequiredParameter: thrown when a required parameter is given in a DB query request.
 - presentNotRequiredParameter: thrown when a parameter which must not be given during a DB query request, is present instead.
 - propertyIDConflict: thrown when the ID of an instance property is not unique.
 */
public enum DBError: Error {
    case missingRequiredParameter(parameterID: String)
    case presentNotRequiredParameter(parameterID: String)
    case propertyIDConflict
    case unsupportedOperation
    case uncaughtError
}

///Base class representing the attributes requirements for a table in each of the CRUD operations.
open class DBQueryData {
    
    /**
     The type of requirement for a column.
     - required: Property must be present to complete the query operation.
     - absent: Property must be absent to complete the query operation.
     - none: Property can either be present or absent.
    */
    public enum PropertyRequirement {
        case required
        case absent
        case none
    }
    
    public typealias PropertyAttributes = [DBOperation: PropertyRequirement]
    
    public init() {}
    
    /**
     Dictionary containing all the informations about the requirements of each property for each CRUD operation.
     **To be overriden by all the subclasses.**
     */
    open var propertiesAttributes: [String: PropertyAttributes] = [:]
    
    /**
     Internal dictionary, representing the current value of each of the instance variables of the object.
     **To be overridden by all the subclasses.**
     */
    open var propertiesValues: [String: NodeRepresentable?] = [:]
    
    //Helper method to return the value of a instance property with a specific given ID, given during initialization phase.
    final internal func getProperty(for name: String) -> NodeRepresentable? {
        return self.propertiesValues[name]
    }
    
    //Verify that an instance variable is properly set to be used as parameter for a query
    final internal func verifyConditions(property: (name: String, attributes: PropertyAttributes), for dbOperation: DBOperation) throws {
        
        let propertyRequirement = property.attributes[dbOperation]
        
        if propertyRequirement == .required && self.getProperty(for: property.name) == nil {
            throw DBError.missingRequiredParameter(parameterID: property.name)
        } else if propertyRequirement == .absent && self.getProperty(for: property.name) != nil {
            throw DBError.presentNotRequiredParameter(parameterID: property.name)
        }
    }
    
    //Returns the dictionary of [column_name: column_value] for a DB operation involving creating data
    final internal func getCreationData(for dbOperation: DBOperation) throws -> [String: NodeRepresentable]? {
        
        //First check to verify that required or required-not-to-be parameters are (or are not) there
        var data: [String: NodeRepresentable] = [:]
        
        try self.propertiesAttributes.forEach { (name, attributes) in
            //We verify that right conditions for each parameter
            try self.verifyConditions(property: (name: name, attributes: attributes), for: dbOperation)
            
            guard data[name] == nil else { throw DBError.propertyIDConflict }
            if let propertyValue = self.getProperty(for: name) {
                data[name] = propertyValue
            }
        }
        if data.count > 0 {
            return data
        } else {
            return nil
        }
    }
    
    //Returns the dictionary of [column_name: column_value] for a DB operation involving filtering data
    final internal func getFilterData(for dbOperation: DBOperation) throws -> [String: NodeRepresentable]? {
        
        //First check to verify that required or required-not-to-be parameters are (or are not) there
        var data: [String: NodeRepresentable] = [:]
        
        try self.propertiesAttributes.forEach { (name, attributes) in
            //We verify that right conditions for each parameter
            try self.verifyConditions(property: (name: name, attributes: attributes), for: dbOperation)
            
            guard data[name] == nil else { throw DBError.propertyIDConflict }
            if let propertyValue = self.getProperty(for: name) {
                data[name] = propertyValue
            }
        }
        if data.count > 0 {
            return data
        } else {
            return nil
        }
    }
    
    //Returns the collection of [column_name] for a DB operation involving selecting data, using a projection of them
    final internal func getProjectionData(for dbOperation: DBOperation) throws -> [String]? {
        
        //First check to verify that required or required-not-to-be parameters are (or are not) there
        var data: [String: NodeRepresentable] = [:]
        
        try self.propertiesAttributes.forEach { (name, attributes) in
            //We verify that right conditions for each parameter
            try self.verifyConditions(property: (name: name, attributes: attributes), for: dbOperation)
            //We add the parameter value to the dictionary of data
            guard data[name] == nil else { throw DBError.propertyIDConflict }
            if let propertyValue = self.getProperty(for: name) {
                data[name] = propertyValue
            }
        }
        if data.count > 0 {
            return data.map { $0.key }
        } else {
            return nil
        }
    }
}


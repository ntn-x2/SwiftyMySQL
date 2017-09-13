/// A first-level implementation of the AbstractDBEntity abstract class. It provides the behaviour common to all its subclasses, but classes for each table must subclass this class to provide the custom ad-hoc behaviour.
open class ResourceDBTable: AbstractDBTable {
    ///The object used to create a new row in the table.
    let creationData: DBQueryData?
    ///The object used to filter the data to read from the table.
    let filterData: DBQueryData?
    ///The object used to specify the fields to project when reading from the table.
    let projectionData: DBQueryData?
    
    open var tableName: String {
        fatalError("Cannot invoke ResourceDBEntity property on abstract class ResourceDBEntity")
    }
    
    /**
     Initialize the entity with the values needed to perform the CRUD operations.
     */
    public init(creationData: DBQueryData?=nil, filterData: DBQueryData?=nil, projectionData: DBQueryData?=nil) {
        self.creationData = creationData
        self.filterData = filterData
        self.projectionData = projectionData
    }
}

extension ResourceDBTable: DBTable {
    
    public func create() throws -> QueryDetails? {
        guard let creationObject = self.creationData else { fatalError("Missing creationData object for creation")  }
        
        guard let creationData = try creationObject.getCreationData(for: .create) else { fatalError("Missing parameters for creation") }
        
        return self.prepareCreateQuery(data: creationData, tableName: self.tableName)
    }
    
    public func read() throws -> QueryDetails? {
        
        let filterObject = self.filterData
        let projectionObject = self.projectionData
        
        let filterData = try filterObject?.getFilterData(for: .read)
        let projectionData = try projectionObject?.getProjectionData(for: .read)
        
        return self.prepareReadQuery(filter: filterData, projection: projectionData, tableName: self.tableName)
    }
    
    public func update() throws -> QueryDetails? {
        guard let creationObject = self.creationData else { fatalError("Missing creationData object for creation")  }
        let filterObject = self.filterData
        
        guard let creationData = try creationObject.getCreationData(for: .update) else { fatalError("Missing parameters for creation") }
        let filterData = try filterObject?.getFilterData(for: .update)
        
        return self.prepareUpdateQuery(data: creationData, filter: filterData, tableName: self.tableName)
    }
    
    public func delete() throws -> QueryDetails? {
        let filterObject = self.filterData
        
        let filterData = try filterObject?.getFilterData(for: .read)
        
        return self.prepareDeleteQuery(filter: filterData, tableName: self.tableName)
    }
}

# SwiftyMySQL

## What is it?

SwiftyDB is a very lightweight and very basic MySQL utility written in Swift, which provides a higher level of abstraction over the [vapor/mysql](https://github.com/vapor/mysql) library written to be used with Vapor.

The basic actors performing this abstraction are:
- **ResourceDBTable**: A class implementing the common behaviour for all the tables in the database and wrapping a MySQL table. The only thing that subclasses must override, is the name of the table, as shown in the [relative section](#ResourceDBTableSubclass).
- **DBQueryData**: The base class representing the attributes requirements for a table in each of the CRUD operations (which ones are required for creations, for selections, updates or reads).
- **DBTransactionOperation**: A single operation (a single query, with no JOINs or special filter clauses, as for now).
- **DBTransaction**: A class responsible for executing operations on the specified Db. It has support for atomic transactions.

*As for now, there is the caveat of already have the tables in the DB, and  of updating their schemas by other means, e.g. with a script or through interactive MySQL shell.*

## Creation of a class reflecting a DB table and its rules

#### <a name="ResourceDBTableSubclass"></a>Subclass **ResourceDBTable**
The first thing to do, is to create a class inheriting from **ResourceDBTable**: *this represents the table on which the queries will be performed.* The only requirement is to *override the variable **tableName** so that it matches the name of an existing table in the DB.*
```swift
class UserCredentialsDBTable: ResourceDBTable {
    override var tableName: String {
        return "user_credentials"
    }
}
```

#### Subclass **DBQueryData**
Next, we need to create a class inheriting from **DBQueryData**: *this represents the rules to follow when performing each CRUD operation on its associated **ResourceDBTable** subclass.*<br>
```swift
class UserCredentialsDBQueryData: DBQueryData {
    let email: String?
    let password: String?

    private struct ColumnKeys {
        static let email = "email"
        static let customPassword = "password"
    }
    
    init(email: String?=nil, password: String?=nil) {
        self.email = email
        self.password = password
        
        super.init()
        
        super.propertiesValues = [
            ColumnKeys.email: self.email,
            ColumnKeys.password: self.password
        ]
        
        super.propertiesAttributes = [
            ColumnKeys.email: [
                .create: .required,
                .read: .none,
                .update: .none,
                .delete: .none
            ],
            ColumnKeys.password: [
                .create: .required,
                .read: .none,
                .update: .none,
                .delete: .none
            ]
        ]
    }
}
```
**Please note**: *all the instance properties should be declared as optionals, since the same class instances will be used for both *creation* operations (where all the fields might be required) and *retrieval* operations (where only the fields acting as filter might have a value).*<br>
For limitations of Swift language, there is need for the subclass to initialize the two inherited properties **propertiesValues** and **propertiesAttributes**, that are going to be used when performing the actual query.<br>
The *first* is a dictionary whose keys are **unique IDs** for each property and values are the values properties themselves.<br>
The *second* is a dictionary containing, for each unique property ID as key, the requirement for each of the CRUD operations (as in the example).<br>
*The subclasses of **DBQueryData** are the ones and only that need to be changed whenever the underlying database structure changes. Instead, if the name of a table is changed, than only the value returned by the **tableName** in the relative subclass of **ResourceDBTable** must be updated to match the new table name.*

## Creation of a transaction and execution of queries

Whenever comes the time of performing a specific query on a DB, the following steps are to be followed:

#### Creation of a **DBTransaction** 
This step has the job of carrying out the requested operations, in both transaction mode or "free" mode (i.e. queries with no dependencies on other ones).
```swift
let transaction = try DBTransaction(database: getDatabase(withConfig: droplet.config))
```
#### Creation of instances of **ResourceDBTable** subclasses
In the example, it is an instance of **UserCredentialsDBTable**, passing as parameter during initialization the needed parameters: data for either *creation*, *filter* or *projection* operation.
```swift
let userCredentialsCreationDBTable = UserCredentialsDBTable(creationData: UserCredentialsDBQueryData(email: "test_email@test.com", password: "backd00red")
```

#### Creation of one or more **DBTransactionOperation** instances
Each instance embodies the query that needs to be carried out. As parameter, the initializer requires:
+ *type*: The type of operation to perform (CREATE/READ/UPDATE/DELETE)
+ *table*: The **ResourceDBTable** subclass instance to execute the query on
+ *handler*: A handler that takes as input a **Node** instance, result of the query execution, and that can return an instance of **Any?**.
```swift
let operation = DBTransactionOperation(type: DBOperation.create, table: userCredentialsDBTable, handler: { _ in
    print("User created!")
})
```

#### Query execution
Taking care of catching and handling all the possible **MySQLError**s that might be thrown from the underlying MySQL connector.
```swift
do {
    try transaction.executeOperation(operation)
} catch let mysqlError as MySQLError {
    print("Ops! Something went wrong!")
}
```

In case there is need to perform operations that can only be committed if and only if all the operations have been correctly accomplished, before calling the *executeOperation* method to perform the queries, just open the transaction, *taking care of closing it once done*.
```swift
do {
    try transaction.start()
    try transaction.executeOperation(operation1)
    try transaction.executeOperation(operation2)
    try transaction.executeOperation(operation3)
    try transaction.commit()
} catch let mysqlError as MySQLError {
    print("Ops! Something went wrong! Initial state reverted back.")
}
```
*If an error is generated during any of the queries in the transaction,
the **ROLLBACK** query is automatically executed before rethrowing the error for further handling.*

## Installation

As for now, SwiftyMySQL is only available through **Swift Package Manager** repository management system. It already has all the dependencies it needs to communicate with a MySQL database, so in order to integrate it into your projects, here an example of a **Package.swift** file is provided:

```swift
import PackageDescription

var package = Package(
    name: "TestApp",
    dependencies: [
        .Package(url: "https://github.com/vapor/mysql.git", Version(1, 2, 0))
    ]
)
```

After updating the **Package.swift** file, just re-fetch the dependencies with
```
swift build
```

or, if using **vapor**, with
```
vapor build
```

## Future updates

I have been developing this small abstraction in the last couple of days, for a project I have been working on. I have plans to implement the support for **JOIN**s operations and more complex query filters, like **HAVING BY** and **WHERE**. For now, the way I am overtaking this lack of features, is by creating smaller queries and handling the results at a higher layer, insted of leaving all the login into a singlee query.<br>
Hope it may help someone in the same situation as me. Regards! :)
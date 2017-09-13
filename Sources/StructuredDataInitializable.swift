import Node

///Protocol allowing classes, structs and enums to be initialized from a StructuredData.
protocol StructuredDataInitializable {
    init(structuredData: StructuredData) throws
}

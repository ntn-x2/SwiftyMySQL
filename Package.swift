import PackageDescription

var package = Package(
    name: "SwiftyMySQL",
    dependencies: [
        .Package(url: "https://github.com/vapor/mysql.git", majorVersion: 2, minor: 0)
    ]
)

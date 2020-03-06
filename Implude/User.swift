struct User: Encodable {
    var email: String
    var name: String
    var uid: String = ""
    var profile: String = ""
    var admin: Bool = false
}

struct Versions {
    static func compatible(version1: String?, version2: String?)-> Bool {
        guard let v1 = version1, let v2 = version2, !v1.isEmpty, !v2.isEmpty else {
            return false
        }
        if v1.count < v2.count {
            return v2.starts(with: v1)
        } else {
            return v2.starts(with: v2)
        }
    }
}
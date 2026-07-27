import Foundation

// MARK: - Frist

/// Beschreibung einer Frist, wie sie in `tasks_de.json` steht.
///
/// Beispiel:
/// ```json
/// { "type": "relative", "unit": "business_days", "amount": 3,
///   "label": "spätestens am 3. Werktag", "strict": true }
/// ```
struct DeadlineSpec: Codable, Hashable, Sendable {

    enum Anchor: String, Codable, Sendable {
        /// Frist läuft ab dem Sterbedatum.
        case relative
        /// Frist läuft ab Kenntnis vom Erbfall. Wir rechnen behelfsweise ab
        /// dem Sterbedatum und weisen in der Oberfläche darauf hin.
        case fromKnowledge = "from_knowledge"
    }

    enum Unit: String, Codable, Sendable {
        case hours
        case days
        case businessDays = "business_days"
        case months
    }

    var type: Anchor
    var unit: Unit
    var amount: Int
    /// Kurzer Text für die Oberfläche, z.B. "spätestens am 3. Werktag".
    var label: String
    /// `true` = gesetzliche oder vertragliche Frist, `false` = Empfehlung.
    var strict: Bool
    /// Optionaler Hinweis, warum die Frist unscharf ist.
    var note: String?

    private enum CodingKeys: String, CodingKey {
        case type, unit, amount, days, label, strict, note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decodeIfPresent(Anchor.self, forKey: .type) ?? .relative
        unit = try c.decodeIfPresent(Unit.self, forKey: .unit) ?? .days
        // `days` wird als Kurzform für `amount` mit Einheit Tage akzeptiert.
        if let amount = try c.decodeIfPresent(Int.self, forKey: .amount) {
            self.amount = amount
        } else {
            self.amount = try c.decode(Int.self, forKey: .days)
        }
        label = try c.decode(String.self, forKey: .label)
        strict = try c.decodeIfPresent(Bool.self, forKey: .strict) ?? false
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encode(unit, forKey: .unit)
        try c.encode(amount, forKey: .amount)
        try c.encode(label, forKey: .label)
        try c.encode(strict, forKey: .strict)
        try c.encodeIfPresent(note, forKey: .note)
    }

    init(type: Anchor = .relative, unit: Unit = .days, amount: Int,
         label: String, strict: Bool = false, note: String? = nil) {
        self.type = type
        self.unit = unit
        self.amount = amount
        self.label = label
        self.strict = strict
        self.note = note
    }
}

// MARK: - Bedingungen

/// Bedingungen aus dem Onboarding. Innerhalb eines Feldes gilt ODER,
/// zwischen den Feldern gilt UND. Fehlt ein Feld, passt die Aufgabe immer.
struct TaskConditions: Codable, Hashable, Sendable {
    var placeOfDeath: [PlaceOfDeath]?
    var relationship: [Relationship]?
    var hasWill: [TriState]?
    var hasFuneralProvision: [TriState]?

    func matches(_ profile: ProfileSnapshot) -> Bool {
        if let places = placeOfDeath, !places.contains(profile.placeOfDeath) { return false }
        if let rels = relationship, !rels.contains(profile.relationship) { return false }
        if let wills = hasWill, !wills.contains(profile.hasWill) { return false }
        if let prov = hasFuneralProvision, !prov.contains(profile.hasFuneralProvision) { return false }
        return true
    }
}

/// Wertfreie Kopie des Nutzerprofils, damit Filterlogik ohne SwiftData
/// testbar bleibt.
struct ProfileSnapshot: Hashable, Sendable {
    var dateOfDeath: Date
    var placeOfDeath: PlaceOfDeath
    var relationship: Relationship
    var hasWill: TriState
    var hasFuneralProvision: TriState

    static let preview = ProfileSnapshot(
        dateOfDeath: Date(),
        placeOfDeath: .home,
        relationship: .spouse,
        hasWill: .unknown,
        hasFuneralProvision: .unknown
    )
}

// MARK: - Aufgabe

struct TaskDefinition: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var phase: Phase
    var title: String
    /// Ein Satz, der in der Liste steht.
    var summary: String
    /// Ausklappbarer Erklärtext: Was ist zu tun und warum?
    var details: String
    /// Benötigte Unterlagen.
    var documents: [String]
    /// An wen wende ich mich?
    var contacts: [String]
    /// Kurze Hinweise, die erfahrungsgemäß helfen.
    var tips: [String]
    var deadline: DeadlineSpec?
    var conditions: TaskConditions?
    /// Reihenfolge innerhalb der Phase, kleiner = weiter oben.
    var priority: Int

    private enum CodingKeys: String, CodingKey {
        case id, phase, title, summary, details, documents, contacts, tips,
             deadline, conditions, priority
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        let rawPhase = try c.decode(Int.self, forKey: .phase)
        guard let phase = Phase(rawValue: rawPhase) else {
            throw DecodingError.dataCorruptedError(
                forKey: .phase, in: c,
                debugDescription: "Unbekannte Phase \(rawPhase) in Aufgabe \(id)")
        }
        self.phase = phase
        title = try c.decode(String.self, forKey: .title)
        summary = try c.decode(String.self, forKey: .summary)
        details = try c.decode(String.self, forKey: .details)
        documents = try c.decodeIfPresent([String].self, forKey: .documents) ?? []
        contacts = try c.decodeIfPresent([String].self, forKey: .contacts) ?? []
        tips = try c.decodeIfPresent([String].self, forKey: .tips) ?? []
        deadline = try c.decodeIfPresent(DeadlineSpec.self, forKey: .deadline)
        conditions = try c.decodeIfPresent(TaskConditions.self, forKey: .conditions)
        priority = try c.decodeIfPresent(Int.self, forKey: .priority) ?? 100
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(phase.rawValue, forKey: .phase)
        try c.encode(title, forKey: .title)
        try c.encode(summary, forKey: .summary)
        try c.encode(details, forKey: .details)
        try c.encode(documents, forKey: .documents)
        try c.encode(contacts, forKey: .contacts)
        try c.encode(tips, forKey: .tips)
        try c.encodeIfPresent(deadline, forKey: .deadline)
        try c.encodeIfPresent(conditions, forKey: .conditions)
        try c.encode(priority, forKey: .priority)
    }

    init(id: String, phase: Phase, title: String, summary: String, details: String,
         documents: [String] = [], contacts: [String] = [], tips: [String] = [],
         deadline: DeadlineSpec? = nil, conditions: TaskConditions? = nil,
         priority: Int = 100) {
        self.id = id
        self.phase = phase
        self.title = title
        self.summary = summary
        self.details = details
        self.documents = documents
        self.contacts = contacts
        self.tips = tips
        self.deadline = deadline
        self.conditions = conditions
        self.priority = priority
    }
}

// MARK: - Dokument

struct DocumentDefinition: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    /// Wofür wird das Dokument gebraucht?
    var purpose: String
    /// Empfohlene Anzahl, z.B. "5 bis 10 beglaubigte Ausfertigungen".
    var recommendedCount: String?
    /// Wo bekomme ich es?
    var source: String
    /// Wofür konkret, als Aufzählung.
    var usedFor: [String]
    var conditions: TaskConditions?
    var priority: Int

    private enum CodingKeys: String, CodingKey {
        case id, title, purpose, recommendedCount = "recommended_count",
             source, usedFor = "used_for", conditions, priority
    }
}

// MARK: - Wurzelobjekte der JSON-Dateien

struct TaskCatalog: Codable, Sendable {
    var version: Int
    var updated: String
    var tasks: [TaskDefinition]
}

struct DocumentCatalog: Codable, Sendable {
    var version: Int
    var updated: String
    var documents: [DocumentDefinition]
}

/// The record type of the current schema version.
///
/// Everything outside `SchemaV1` uses this alias, so moving to a new schema version
/// is a one-line change here.
typealias PracticeSessionRecord = SchemaV1.PracticeSessionRecord

enum ShowtimeRecordsViewState: Equatable, Sendable {
    case loading
    case empty
    case loaded([ShowtimeRecordRowModel])
    case failed
}

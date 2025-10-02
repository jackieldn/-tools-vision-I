import SwiftUI
import AndtoolsCore

struct BatchInspector: View {
    @EnvironmentObject private var app: AppState
    
    var body: some View {
        List(selection: Binding(get: {
            app.selectedItem?.id
        }, set: { newID in
            if let id = newID {
                app.selectedItem = app.batch.items.first { $0.id == id }
            }
        })) {
            ForEach(app.batch.items) { item in
                BatchRow(item: item)
                    .tag(item.id)
                    .contextMenu {
                        Button("Remove") { app.batch.remove(item) }
                        Button(item.isChecked ? "Uncheck" : "Check") { item.isChecked.toggle() }
                    }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Batch Inspector")
    }
}

private struct BatchRow: View {
    @ObservedObject var item: BatchItem
    
    var body: some View {
        HStack {
            Toggle("", isOn: $item.isChecked)
                .toggleStyle(.checkbox)
                .labelsHidden()
            VStack(alignment: .leading) {
                Text(item.url.lastPathComponent).font(.headline)
                HStack {
                    switch item.status {
                    case .pending:
                        Label("Pending", systemImage: "clock")
                            .foregroundStyle(.secondary)
                    case .running(let p):
                        ProgressView(value: p)
                            .frame(width: 120)
                        Text("\(Int(p*100))%")
                            .foregroundStyle(.secondary)
                    case .done:
                        Label("Done", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case .failed(let err):
                        Label("Failed", systemImage: "xmark.octagon.fill").foregroundStyle(.red)
                        Text(err).foregroundStyle(.secondary)
                    case .skipped:
                        Label("Skipped", systemImage: "forward.end").foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

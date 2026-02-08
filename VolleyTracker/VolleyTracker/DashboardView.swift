import SwiftUI
import SwiftData

struct GroupsView: View {
    let coach: Coach

    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [Group]

    @State private var showAddGroup = false
    @State private var showDeleteConfirm = false
    @State private var groupToDelete: Group?

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    init(coach: Coach) {
        self.coach = coach
        _groups = Query(filter: #Predicate<Group> { $0.coach == coach })
    }

    var body: some View {
        ZStack {
            Image("volleyball")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 5)

            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 14) {

                Text(dateText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 12)

                Text("Groups")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if groups.isEmpty {
                    Spacer()
                    Text("No groups yet")
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                } else {
                    List {
                        ForEach(groups) { group in
                            NavigationLink {
                                PlayersView(group: group)
                            } label: {
                                GroupRowView(group: group)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                                Button {
                                    groupToDelete = group
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .role(.destructive)

                                Button {
                                    // edit logic ако имаш
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // back идва от NavigationStack
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddGroup = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
            }
        }
        .confirmationDialog(
            "Delete group?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let groupToDelete {
                    modelContext.delete(groupToDelete)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAddGroup) {
            AddGroupView(coach: coach)
        }
    }
}

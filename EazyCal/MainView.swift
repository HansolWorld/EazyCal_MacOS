//
//  MainView.swift
//  EazyCal
//
//  Created by apple on 10/13/23.
//

import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    private var hGrid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    @State var isTempleteShow: Bool = false

    var body: some View {
        ZStack {
            Color.background
            HStack(spacing: 0) {
                GeometryReader { geometry in
                    VStack {
                        VStack {
                            CategoryView()
                            Divider()
                        }
                        .frame(height: geometry.size.height/4)
                        VStack {
                            TemplateView()
                            Divider()
                        }
                        .frame(height: geometry.size.height/4)
                        .onTapGesture {
                            isTempleteShow = true
                        }
                        .popover(isPresented: $isTempleteShow) {
                            Text("Coming Soon")
                                .padding()
                        }
                        VStack {
                            TodoView(mode: .Todo)
                        }
                        .frame(height: geometry.size.height/2)
                    }
                    .padding(.vertical)
                    .background {
                        Color.white
                    }
                }
                .frame(maxWidth: 300)
                CalenderView()
            }
        }
        .ignoresSafeArea()
//        NavigationView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
//                    } label: {
//                        Text(item.timestamp!, formatter: itemFormatter)
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//            Text("Select an item")
//        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

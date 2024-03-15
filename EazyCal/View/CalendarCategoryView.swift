//
//  CalendarCategoryView.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI
import SwiftData
import EventKit

struct CalendarCategoryView: View {
    private let gridItem = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var isAddPopoverShow = false
    @State private var isEditPopoverShow = false
    @State private var categoryIcon = ""
    @State private var categoryTitle = ""
    @State private var requestCategory: CalendarCategory?
    @State private var selectTag: CalendarCategory?
    @State private var editCategoryRequest: Bool = false
    @State private var deleteCategoryRequest: Bool = false
    @State private var currentDragItem: EKCalendar?
    @EnvironmentObject var eventManager: EventStoreManager

    @Environment(\.modelContext) private var context
    @Query(sort: \CalendarCategory.date, animation: .snappy) private var categories: [CalendarCategory]
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(IndexCategory.calendar.title)
                    .font(.headline)
                    .foregroundStyle(.gray300)
                Spacer(minLength: 10)
                
                Button(action: {
                    isAddPopoverShow = true
                }) {
                    Image(systemName: SFSymbol.plus.name)
                        .foregroundStyle(Color.primaryBlue)
                        .popover(isPresented: $isAddPopoverShow) {
                         CalendarCategoryPopoverView(isShow: $isAddPopoverShow)
                                .environmentObject(eventManager)
                        }
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(columns: gridItem) {
                ForEach(categories, id:\.id) { category in
                    Button(action: {
                        withAnimation {
                            selectTag = category
                        }
                    }) {
                        VStack {
                            Text(category.icon)
                                .font(.system(size: 12))
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.background)
                                }
                                .opacity(selectTag == category ? 1 : 0.5)
                                .overlay {
                                    if selectTag == category {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primaryBlue, lineWidth: 2)
                                    }
                                }
                            Text(category.title)
                                .lineLimit(1)
                                .font(.subheadline)
                                .fontWeight(selectTag == category ? .bold : .regular)
                                .foregroundStyle(selectTag == category ? .primaryBlue : .gray400)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if category.title != "전체" && category.title != "미등록" {
                            Button(action: {
                                categoryTitle = category.title
                                categoryIcon = category.icon
                                requestCategory = category
                                editCategoryRequest = true
                            }) {
                                Text("수정")
                            }
                            Button(action: {
                                requestCategory = category
                                deleteCategoryRequest = true
                            }) {
                                Text("삭제")
                            }
                        }
                    }
                    .alert("카테고리 수정", isPresented: $editCategoryRequest) {
                        TextField("Icon", text: $categoryIcon)
                        TextField("Title", text: $categoryTitle)
                        
                        Button("취소", role: .cancel) {
                            categoryTitle = ""
                            categoryIcon = ""
                            requestCategory = nil
                        }
                        Button("수정") {
                            if let requestCategory {
                                requestCategory.icon = categoryIcon
                                requestCategory.title = categoryTitle
                                categoryTitle = ""
                                categoryIcon = ""
                                self.requestCategory = nil
                            }
                        }
                    }
                    .alert("카테고리 삭제", isPresented: $deleteCategoryRequest) {
                        Button("취소", role: .cancel) {
                            requestCategory = nil
                        }
                        Button("삭제", role: .destructive) {
                            if let requestCategory {
                                context.delete(requestCategory)
                                self.requestCategory = nil
                            }
                        }
                    }
                    .onDrop(of: [.text], isTargeted: nil, perform: { providers in
                        if let currentDragItem {
                            replaceCategory(category, droppingCalendar: currentDragItem)
                            self.selectTag = category
                        }
                        currentDragItem = nil
                        return true
                    })
                }
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    let categoriedCalendar: [String] = categories[2...].flatMap { $0.calendars }
                    let calendaries = eventManager.calendars.filter {
                        if selectTag?.title == "전체" {
                            return true
                        } else if selectTag?.title == "미등록" {
                            return !categoriedCalendar.contains( $0.calendarIdentifier)
                        } else {
                            if let selectTag = selectTag {
                                return selectTag.calendars.contains($0.calendarIdentifier)
                            } else {
                                return false
                            }
                        }
                    }
                    
                    ForEach(calendaries, id:\.self) { calendar in
                        CategoryLabelView(calendar: calendar, currentDragItem: $currentDragItem)
                            .environmentObject(eventManager)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background)
            }
        }
        .onAppear {
            selectTag = categories[0]
        }
    }
    
    
    func replaceCategory(_ category: CalendarCategory, droppingCalendar: EKCalendar) {
        if selectTag?.title != "전체" {
            selectTag?.calendars.removeAll(where: {$0 == droppingCalendar.calendarIdentifier})
        }
        category.calendars.append(droppingCalendar.calendarIdentifier)
    }
}

#Preview {
    CalendarCategoryView()
        .environmentObject(EventStoreManager())
}

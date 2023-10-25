//
//  AddNewCategoryView.swift
//  EazyCal
//
//  Created by apple on 10/23/23.
//

import SwiftUI

struct AddNewCategoryView: View {
    @Binding var newTitle: String
    @Binding var newColor: CGColor
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("새로운 캘린더", text: $newTitle)
                .font(CustomTextStyle.caption.font)
                .foregroundStyle(.gray300)
            Divider()
            Text("색상 지정")
                .customStyle(.caption)
                .foregroundStyle(.gray400)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                Button(action: {
                    newColor = CGColor(red: 65/255, green: 129/255, blue: 255/255, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor:  CGColor(red: 65/255, green: 129/255, blue: 255/255, alpha: 1)))
                }
                Button(action: {
                    newColor = CGColor(red: 77/255, green: 191/255, blue: 81/255, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor: CGColor(red: 77/255, green: 191/255, blue: 81/255, alpha: 1)))
                }
                Button(action: {
                    newColor = CGColor(red: 255/255, green: 75/255, blue: 75/255, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor: CGColor(red: 255/255, green: 75/255, blue: 75/255, alpha: 1)))
                }
                Button(action: {
                    newColor = CGColor(red: 255/255, green: 230/255, blue: 0, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor: CGColor(red: 255/255, green: 230/255, blue: 0, alpha: 1)))
                }
                Button(action: {
                    newColor = CGColor(red: 255/255, green: 148/255, blue: 22/255, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor: CGColor(red: 255/255, green: 148/255, blue: 22/255, alpha: 1)))
                }
                Button(action: {
                    newColor = CGColor(red: 255/255, green: 103/255, blue: 194/255, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor: CGColor(red: 255/255, green: 103/255, blue: 194/255, alpha: 1)))
                }
                Button(action: {
                    newColor = CGColor(red: 146/255, green: 97/255, blue: 251/255, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor: CGColor(red: 146/255, green: 97/255, blue: 251/255, alpha: 1)))
                }
                Button(action: {
                    newColor = CGColor(red: 43, green: 43, blue: 43, alpha: 1)
                }) {
                    Circle()
                        .frame(maxWidth: 11)
                        .foregroundStyle(Color(cgColor: CGColor(red: 43/255, green: 43/255, blue: 43/255, alpha: 1)))
                }
            }
        }
        .padding()
        .background {
            Color.white
                .scaleEffect(1.5)
        }
    }
}

#Preview {
    AddNewCategoryView(newTitle: .constant(""), newColor: .constant(CGColor(red: 1, green: 1, blue: 1, alpha: 1)))
}

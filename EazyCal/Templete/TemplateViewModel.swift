//
//  TempleteViewModel.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import Foundation

class TemplateViewModel: ObservableObject {
    @Published var templates: [Template] = Template.dummyTemplates
}

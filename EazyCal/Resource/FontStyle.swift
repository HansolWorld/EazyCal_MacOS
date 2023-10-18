//
//  FontStyle.swift
//  EazyCal
//
//  Created by apple on 10/15/23.
//

import SwiftUI

enum CustomTextStyle {
    case title
    case subtitle
    case day
    case body
    case body2
    case date
    case caption
    case caption2
    
    var font: Font {
        switch self {
        case .title:
            return .custom("SpoqaHanSansNeo-Bold", size: 26)
        case .subtitle:
            return .custom("SpoqaHanSansNeo-Medium", size: 17)
        case .day:
            return .custom("SpoqaHanSansNeo-Regular", size: 17)
        case .body:
            return .custom("SpoqaHanSansNeo-Regular", size: 16)
        case .body2:
            return .custom("SpoqaHanSansNeo-Regular", size: 15)
        case .date:
            return .custom("SpoqaHanSansNeo-Regular", size: 16)
        case .caption:
            return .custom("SpoqaHanSansNeo-Regular", size: 14)
        case .caption2:
            return .custom("SpoqaHanSansNeo-Medium", size: 12)
        }
    }
    
    var letterSpacing: CGFloat {
        switch self {
        case .body, .body2, .caption:
            return -0.6
        case .caption2:
            return -0.3
        default:
            return 0
        }
    }
    
    var letterHeight: CGFloat {
        switch self {
        case .title, .day, .date:
            return 22
        case .subtitle:
            return 21
        case .body:
            return 19
        case .body2:
            return 15
        case .caption:
            return 16
        case .caption2:
            return 15
        }
    }
}

// Custom modifier for applying the style
extension Text {
    func customStyle(_ style: CustomTextStyle) -> some View {
        return self
            .font(style.font)
            .kerning(style.letterSpacing)
            .frame(minHeight: style.letterHeight, alignment: .center)
    }
}

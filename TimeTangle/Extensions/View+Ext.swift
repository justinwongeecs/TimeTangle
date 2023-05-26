//
//  View+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI

struct CenterView: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
            Spacer()
        }
    }
}

struct LeftAlignedView: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
        }
    }
}

struct RightAlignedView: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
        }
    }
}

extension View {
    func centered() -> some View {
        modifier(CenterView())
    }
    
    func leftAligned() -> some View {
        modifier(LeftAlignedView())
    }
    
    func rightAligned() -> some View {
        modifier(RightAlignedView())
    }
}

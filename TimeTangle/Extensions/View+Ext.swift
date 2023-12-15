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

struct RoundedRectangleBackgroundView: ViewModifier {
    var cornerRadius: CGFloat
    var fillColor: Color
    var fillColorOpacity: CGFloat
    var strokeColor: Color
    var strokeLineWidth: CGFloat
    var frameHeight: CGFloat?
    var frameWidth: CGFloat?
    
    func body(content: Content) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fillColor.opacity(fillColorOpacity))
            .stroke(strokeColor, lineWidth: strokeLineWidth)
            .frame(width: frameWidth, height: frameHeight)
            .overlay(content)
    }
}

struct SettingsBlurredView: ViewModifier {
    var isSubscriptionPro: Bool
    
    func body(content: Content) -> some View {
        content
        .blur(radius: isSubscriptionPro ? 0 : 6)
        .disabled(isSubscriptionPro ? false : true)
    }
}

struct SettingsLockedView: ViewModifier {
    var isSubscriptionPro: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                !isSubscriptionPro ?
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray)
                    .font(.system(size: 30)) : nil
            )
    }
}

struct NoResultsStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.secondary).bold()
            .font(.title2)
    }
}

//MARK: - View Extension
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
    
    func roundedRectangleBackgroundStyle(
        cornerRadius: CGFloat,
        fillColor: Color,
        fillColorOpacity: CGFloat = 1,
        strokeColor: Color,
        strokeLineWidth: CGFloat = 1,
        frameWidth: CGFloat? = nil,
        frameHeight: CGFloat? = nil
    ) -> some View {
        modifier(RoundedRectangleBackgroundView(cornerRadius: cornerRadius, fillColor: fillColor, fillColorOpacity: fillColorOpacity, strokeColor: strokeColor, strokeLineWidth: strokeLineWidth, frameHeight: frameHeight, frameWidth: frameWidth))
    }
    
    func applySettingsBlurredStyle(isSubscriptionPro: Bool) -> some View {
        modifier(SettingsBlurredView(isSubscriptionPro: isSubscriptionPro))
    }
    
    func applySettingsLockedStyle(isSubscriptionPro: Bool) -> some View {
        modifier(SettingsLockedView(isSubscriptionPro: isSubscriptionPro))
    }
    
    func applyNoResultsStyle() -> some View {
        modifier(NoResultsStyle())
    }
}

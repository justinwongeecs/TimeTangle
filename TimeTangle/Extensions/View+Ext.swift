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

extension View {
    func presentScreen<Content>(isPresented: Binding<Bool>, modalPresentationStyle: UIModalPresentationStyle, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View{
        if isPresented.wrappedValue {
            let window = UIApplication.shared.windows.last
            window?.isHidden = true
            let view = content()
            let viewController = UIHostingController(rootView: view)
            viewController.modalPresentationStyle = modalPresentationStyle
            viewController.modalTransitionStyle = .crossDissolve
            UIApplication.shared.topMostController()!.present(viewController, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPresented.wrappedValue = false
            }
        }
        return self
    }
    
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
}

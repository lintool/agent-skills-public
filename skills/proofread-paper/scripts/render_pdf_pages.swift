#!/usr/bin/env swift
import Foundation
import PDFKit
import AppKit

if CommandLine.arguments.count != 3 {
    fputs("usage: render_pdf_pages.swift input.pdf output_dir\n", stderr)
    exit(2)
}

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDir = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

guard let document = PDFDocument(url: input) else {
    fputs("could not open PDF\n", stderr)
    exit(1)
}

let scale: CGFloat = 3.0
for index in 0..<document.pageCount {
    guard let page = document.page(at: index) else { continue }
    let bounds = page.bounds(for: .mediaBox)
    let size = NSSize(width: bounds.width * scale, height: bounds.height * scale)
    let image = NSImage(size: size)
    image.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: size).fill()
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        continue
    }
    context.saveGState()
    context.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: context)
    context.restoreGState()
    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        continue
    }
    let out = outputDir.appendingPathComponent(String(format: "page-%02d.png", index + 1))
    try png.write(to: out)
}

print("rendered \(document.pageCount) pages")

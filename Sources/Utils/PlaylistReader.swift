//
//  PlaylistReader.swift
//  SpatialGen
//
//  Created by Zachary Handshoe on 8/28/24.
//

import Foundation
import CoreGraphics

func getAvailableResolutions(from url: URL, completion: @escaping (Result<[ResolutionOption], Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data, let content = String(data: data, encoding: .utf8) else {
            completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse m3u8 content"])))
            return
        }
        
        let resolutions = parseResolutions(from: content)
        
        if resolutions.isEmpty {
            completion(.failure(NSError(domain: "ResolutionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No available resolutions found"])))
        } else {
            completion(.success(resolutions))
        }
    }.resume()
}

private func parseResolutions(from content: String) -> [ResolutionOption] {
    let lines = content.components(separatedBy: .newlines)
    var resolutions: [ResolutionOption] = []
    for (index, line) in lines.enumerated() {
        if line.contains("RESOLUTION=") {
            let components = line.components(separatedBy: ",")
            for component in components {
                if component.contains("RESOLUTION=") {
                    let resolutionPart = component.components(separatedBy: "=")[1]
                    
                    let dimensions = resolutionPart.components(separatedBy: "x")
                    if dimensions.count == 2,
                       let width = Int(dimensions[0]),
                       let height = Int(dimensions[1]) {
                        
                        let size = CGSize(width: width, height: height)
                        let label = getResolutionString(for: height)
                        if !label.isEmpty {
                            // Grab the next line (url) and append
                            if index + 1 < lines.count {
                                let nextLine = lines[index + 1]
                                if let playlistURL = URL(string: nextLine) {
                                    let resolutionOption = ResolutionOption(size: size, label: label, streamURL: playlistURL)
                                    resolutions.append(resolutionOption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return resolutions.sorted { $0.size.width > $1.size.width }
}

private func getResolutionString(for height: Int) -> String {
    switch height {
    case 720: return "720p"
    case 1080: return "1080p"
    case 2048..<3072: return "4K"
    case 3072..<3840: return "6K"
    case 3840..<5120: return "8K"
    case 5120..<6144: return "10K"
    case 6144..<7168: return "12K"
    case 7168..<8192: return "14K"
    case 8192...: return "16K"
    default: return ""
    }
}


struct ResolutionOption: Identifiable, Hashable {
    let id = UUID()
    let size: CGSize
    let label: String
    let streamURL: URL
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(size.width)
        hasher.combine(size.height)
        hasher.combine(label)
        hasher.combine(streamURL)
    }

    static func == (lhs: ResolutionOption, rhs: ResolutionOption) -> Bool {
        return lhs.id == rhs.id &&
               lhs.size == rhs.size &&
               lhs.label == rhs.label &&
               lhs.streamURL == rhs.streamURL
    }
}

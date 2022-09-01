//
//  Search.swift
//  StoreSearch
//
//  Created by Акбар Уметов on 31/8/22.
//

import Foundation

typealias SearchComplete = (Bool) -> Void

class Search {
    enum Category: Int {
        case all = 0
        case music = 1
        case software = 2
        case ebooks = 3
        
        var type: String {
            switch self {
            case .all:
                return ""
            case .music:
                return "musicTrack"
            case .software:
                return "software"
            case .ebooks:
                return "ebook"
            }
        }
    }
    
    enum State {
        case notSearchedYet
        case loading
        case noResults
        case results([SearchResult])
    }
    
    private var dataTask: URLSessionDataTask?
    private(set) var state: State = .notSearchedYet
    
    func performSearch(for text: String, category: Category, completion: @escaping SearchComplete) {
        if !text.isEmpty {
            dataTask?.cancel()
            
            state = .loading
            
            let url = iTunesURL(searchText: text, category: category)
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                var newState = State.notSearchedYet
                var success = false
                
                if let error = error as NSError?, error.code == -999 {
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let data = data {
                    var searchResults = self.parse(data: data)
                    
                    if searchResults.isEmpty {
                        newState = .noResults
                    } else {
                        searchResults.sort(by: <)
                        
                        newState = .results(searchResults)
                    }
                    
                    success = true
                }
                
                print("Failure! \(response!)")
                
                DispatchQueue.main.async {
                    self.state = newState
                    
                    completion(success)
                }
            }
            .resume()
        }
    }
    
    private func iTunesURL(searchText: String, category: Category) -> URL {
//        let locale = Locale.autoupdatingCurrent
//        let language = locale.identifier
//        let countryCode = locale.regionCode ?? "en_US"
        let kind = category.type
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format: "https://itunes.apple.com/search?" + "term=\(encodedText)&limit=200&entity=\(kind)",
                               encodedText)
        let url = URL(string: urlString)
        
        print("URL: \(url!)")
        
        return url!
    }
    
    private func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            
            return result.results
        } catch {
            print("JSON Error: \(error)")
            
            return []
        }
    }
}

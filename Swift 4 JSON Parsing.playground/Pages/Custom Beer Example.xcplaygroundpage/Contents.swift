import Foundation

let json = """
           {
               "name" : "Lawnmower",
               "meta": { "abv": 4.9 },
               "brewery_name" : "Saint Arnold",
               "brewery_city" : "Houston",
               "style": "kolsch",
               "created_at": "2018-06-20T17:57:16Z",
               "bottle_sizes": [ 12, 16 ]
           }
           """

enum BeerStyle : String, Codable {
    case ipa
    case lager
    case kolsch
}

struct Brewery : Codable {
    let name: String
    let city: String
}

struct Beer : Codable {
    let name: String
    let abv: Float
    let brewery: Brewery
    let style: BeerStyle
    let createdAt: Date
    let bottleSizes: [Float]
    let comments: String?
    
    enum CodingKeys : String, CodingKey {
        case name
        case breweryName = "brewery_name"
        case breweryCity = "brewery_city"
        case style
        case createdAt = "created_at"
        case comments
        case bottleSizes = "bottle_sizes"
        case meta
    }
    
    enum MetaCodingKeys : String, CodingKey {
        case abv
    }
}

extension Beer {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let name = try container.decode(String.self, forKey: .name)
        
        let meta = try container.nestedContainer(keyedBy: MetaCodingKeys.self, forKey: .meta)
        let abv = try meta.decode(Float.self, forKey: .abv)
        
        let breweryName = try container.decode(String.self, forKey: .breweryName)
        let breweryCity = try container.decode(String.self, forKey: .breweryCity)
        let brewery = Brewery(name: breweryName, city: breweryCity)
        
        let style = try container.decode(BeerStyle.self, forKey: .style)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        let comments = try container.decodeIfPresent(String.self, forKey: .comments)
        
        // let bottleSizes = try container.decode([Float].self, forKey: .bottleSizes)
        var bottleSizesContainer = try container.nestedUnkeyedContainer(forKey: .bottleSizes)
        var sizes: [Float] = []
        while !bottleSizesContainer.isAtEnd {
            let size = try bottleSizesContainer.decode(Float.self)
            sizes.append(size.rounded())
        }
        
        self.init(name: name, abv: abv, brewery: brewery, style: style, createdAt: createdAt,
                  bottleSizes: sizes,
                  comments: comments)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        var meta = container.nestedContainer(keyedBy: MetaCodingKeys.self, forKey: .meta)
        try meta.encode(abv, forKey: .abv)
        
        try container.encode(style, forKey: .style)
        try container.encode(brewery.name, forKey: .breweryName)
        try container.encode(brewery.city, forKey: .breweryCity)
        try container.encode(createdAt, forKey: .createdAt)
        
        // try container.encode(bottleSizes, forKey: .bottleSizes)
        var bottlesArray = container.nestedUnkeyedContainer(forKey: .bottleSizes)
        try bottleSizes.forEach {
            try bottlesArray.encode($0.rounded())
        }
        
        try container.encodeIfPresent(comments, forKey: .comments)
    }
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let beer = try! decoder.decode(Beer.self, from: json.data(using: .utf8)!)
dump(beer)
print("✅")

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
let data = try! encoder.encode(beer)
print(String(data:data, encoding: .utf8)!)



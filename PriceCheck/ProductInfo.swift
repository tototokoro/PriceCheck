import Foundation

struct ProductInfo {
    var name: String?
    var price: Int?
    var shippingPrice: Int?
    var condition: String?
    var link: URL?
    var image: URL?
}

struct BookInfo: Codable {
    var name: String?
//    var previousPrice: Int? //price + shippingPrice
    var image: URL?
}

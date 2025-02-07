//
//  Invoice.swift
//  ProcessOut
//
//  Created by Jeremy Lejoux on 10/09/2019.
//

public class Invoice: Codable {
    var name: String = ""
    var amount: String = ""
    var currency: String = ""
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case amount = "amount"
        case currency = "currency"
    }
    
    public init(name: String, amount: String, currency: String) {
        self.name = name
        self.amount = amount
        self.currency = currency
    }
}

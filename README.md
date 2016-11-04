# Conception origin
[UnboxedAlamofire](https://github.com/serejahh/UnboxedAlamofire)

# UnboxedAlamofire

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

[Alamofire](https://github.com/Alamofire/Alamofire) + [Unbox](https://github.com/JohnSundell/Unbox): the easiest way to download and decode JSON into swift custom objects.

## Usage

Objects you request have to conform [Unboxable](https://github.com/JohnSundell/Unbox#basic-example) protocol.

### Make Custom Object - Realm
``` swift
class RealmObject: Object, CustomUnboxed {
    public static func custom(unboxer: Unboxer) throws -> CustomUnboxed {
        let campany: RealmObject = RealmObject()
        campany.identifier = try! unboxer.unbox(key: "identifier")
        campany.name = try! unboxer.unbox(key: "name")
        campany.phone = try! unboxer.unbox(key: "phone")
        return campany
    }
}
```

### Get an object

``` swift
Alamofire.request(url, method: .get).responseObject { (response: DataResponse<RealmObject>) in
	let realmObject = response.result.value
}
```

### Get an array

``` swift
Alamofire.request(url, method: .get).responseArray { (response: DataResponse<[RealmObject]>) in
	let realmObjects = response.result.value
}
```

### KeyPath

Also you can specify a keypath in both requests:

``` swift
Alamofire.request(url, method: .get).responseObject(keyPath: "response") { (response: DataResponse<RealmObject>) in
	let realmObject = response.result.value
}
```

## Installation

### [Carthage](https://github.com/Carthage/Carthage)

```
github "KITSUKI-INC/CustomUnboxedAlamofire" ~> 1.0
```

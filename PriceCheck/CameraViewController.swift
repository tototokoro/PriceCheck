import Foundation
import AVFoundation
import UIKit
import Kanna

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var productList: [(name:String, price:Int, shippingPrice:Int, condition:String, link:URL, image:URL)] = []
    var passData: [String: Any] = [:]
    var isbn13: String = ""
    var cCode: String = ""
    var reserveURL = ""
    
    let detectionArea = UIView()
    
    // カメラやマイクの入出力を管理するオブジェクトを生成
    private let session = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // カメラやマイクのデバイスそのものを管理するオブジェクトを生成（ここではワイドアングルカメラ・ビデオ・背面カメラを指定）
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],mediaType: .video,position: .back)
        
        // ワイドアングルカメラ・ビデオ・背面カメラに該当するデバイスを取得
        let devices = discoverySession.devices
        
        //　該当するデバイスのうち最初に取得したものを利用する
        if let backCamera = devices.first {
            do {
                // QRコードの読み取りに背面カメラの映像を利用するための設定
                let deviceInput = try AVCaptureDeviceInput(device: backCamera)
                
                if self.session.canAddInput(deviceInput) {
                    self.session.addInput(deviceInput)
                    
                    // 背面カメラの映像からコードを検出するための設定
                    let metadataOutput = AVCaptureMetadataOutput()
                    
                    if self.session.canAddOutput(metadataOutput) {
                        self.session.addOutput(metadataOutput)
                        
                        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = [.ean13]
                        
                        // 背面カメラの映像を画面に表示するためのレイヤーを生成
                        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                        previewLayer.frame = self.view.bounds
                        previewLayer.videoGravity = .resizeAspectFill
                        self.view.layer.addSublayer(previewLayer)
                     
                        addBorder()
                        
                        // 読み取り開始
                        self.session.startRunning()
                    }
                }
            } catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }
    
    //バーコード読み取り時に印を表示する
    private func addBorder(){
        let barcodeImage = UIImage(named: "barcode")!
        let width :CGFloat = barcodeImage.size.width
        let height :CGFloat = barcodeImage.size.height
        
        let barcodeImageView = UIImageView(image: barcodeImage)
        barcodeImageView.alpha = 0.5
        barcodeImageView.frame = CGRect(x: 0, y: 0, width: width * 2, height: height*2)
        
        let screenWidth: CGFloat = view.frame.size.width
        let screenHeight: CGFloat = view.frame.size.height
        
        barcodeImageView.center = CGPoint(x: screenWidth/2, y: screenHeight/3)
        
        self.view.addSubview(barcodeImageView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        productList.removeAll()
        isbn13 = ""
        cCode = ""
        self.session.startRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //バーコードを読み取った際に呼び出される
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for data in metadataObjects as! [AVMetadataMachineReadableCodeObject]{
            
            if(isbn13 == "" || cCode == ""){
                //バーコードかどうか確認
                if data.type != .ean13 {continue}
                
                //内容が空かどうかの確認
                if data.stringValue == nil {continue}
                
                //ISBN時の処理
                if (data.stringValue?.prefix(3).contains("978"))! {
                    isbn13 = data.stringValue!
                    continue
                }
                //Cコード時の処理（本の内容など）
                if (data.stringValue?.prefix(3).contains("192"))! {
                    cCode = data.stringValue!
                    cCode = String(cCode[cCode.index(cCode.startIndex, offsetBy: 3)..<cCode.index(cCode.endIndex, offsetBy: -6)])
                    continue
                }
            } else {
                //読み取り終了
                self.session.stopRunning()
                
                print(cCode)

                let dispatchGroup = DispatchGroup()
                let queue1 = DispatchQueue(label: "scrapingProductsInfo")
                let queue2 = DispatchQueue(label: "getReserveURL")
                
                //番号を元にスクレイピング
                queue1.async (group: dispatchGroup) {
                    self.searchBook(isbn: self.isbn13)
                }
                let isbn10 = isbn13Toisbn10(isbn13: isbn13)
                queue2.async (group: dispatchGroup){
                    self.scrapeWebsite(isbn13: self.isbn13, isbn10: isbn10)
                }
                
                dispatchGroup.notify(queue: .main){
                    print(self.productList.count)
                    self.productList.sort(by: {($0.price + $0.shippingPrice) < ($1.price + $1.shippingPrice)})
                    self.passData["products"] = self.productList
                    self.passData["reserveURL"] = self.reserveURL
                    self.performSegue(withIdentifier: "showResultView", sender: self.passData)
                }
            }
        }
    }
    
    func searchBook(isbn: String){
        let system_id = "Tokyo_Nakano"
        
        guard let req_url = URL(string: "http://api.calil.jp/check?appkey=\(apiKey["kariru"]!)&isbn=\(isbn)&systemid=\(system_id)&callback=no&format=json") else {
            return
        }
        //リクエストに必要な情報を生成
        let req = URLRequest(url: req_url)
        //データ転送を管理するためのセッションを生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        //リクエストをタスクとして登録
        let task = session.dataTask(with: req, completionHandler: {
            (data, response, error) in
            //セッションを終了
            session.finishTasksAndInvalidate()
            do{
                if let jsonObject = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary,
                    let books = jsonObject["books"] as? NSDictionary,
                    let isbn = books[isbn] as? NSDictionary,
                    //要修正
                    let location = isbn[system_id] as? NSDictionary
                {
                    self.reserveURL = (location["reserveurl"] as? String)!
                }
            } catch {
                print(error)
            }
        })
        task.resume()
    }
    
    func getHtml(url: URL) -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            fatalError("fail to download")
        }
    }
    
    //取得したISBNに従ってスクレイピング
    func scrapeWebsite(isbn13: String, isbn10: String){
        //Amazon検索
        //Getリクエスト　指定URLのコードを取得
        let amazonUrl = URL(string: "https://www.amazon.co.jp/s/ref=nb_sb_noss?field-keywords=\(isbn13)")
        let amazonData = self.getHtml(url: amazonUrl!)
        var productName = ""
        if let doc = try? HTML(html: amazonData, encoding: .utf8){
            //商品名取得
            productName = doc.css("li#result_0 h2").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            print(productName)
        }
        
        let detailPageUrl = URL(string: "https://www.amazon.co.jp/gp/offer-listing/\(isbn10)")
        let detailData = self.getHtml(url: detailPageUrl!)
        if let doc = try? HTML(html: detailData, encoding: .utf8){
            var imageURL: URL?
            
            if let image = doc.css("div#olpProductImage img").first!["src"]{
                //アマゾンの画像URLを取得
                imageURL = URL(string: image)
            } else{
                print("画像見つからず")
            }
            
            let products = doc.css("div.olpOffer")
            for product in products.prefix(5){
                //値段
                let price = product.css("span.a-color-price").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                
                var shippingPrice: String?
                //送料
                if let a = product.css("span.olpShippingPrice").first{
                    shippingPrice = a.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                } else{
                    shippingPrice = "0"
                }
                
                //コンディション
                let codition = product.css("span.olpCondition").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                

                self.productList.append((name: productName, price: self.getPrice(price: price), shippingPrice: self.getPrice(price: shippingPrice!),  condition: codition, link: detailPageUrl!, image: imageURL!))
            }
        }
        //メルカリ検索
        if let name_encode = productName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed){
            self.getMercariProduct(productName: name_encode)
        }
    }
    
    private func getMercariProduct(productName: String) {
        let mercariUrl = URL(string: "https://www.mercari.com/jp/search/?keyword=\(productName)&shipping_payer_id%5B2%5D=1&status_on_sale=1")
        
        let mercariData = self.getHtml(url: mercariUrl!)
        if let doc = try? HTML(html: mercariData, encoding: .utf8){
            
            let numberItems = doc.css("section.items-box-container h2").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            //要修正（０件かどうか判定）
            if(numberItems == "検索結果 0件"){
                print(numberItems)
            } else {
                var tempProductList: [(name:String, price:Int, shippingPrice:Int, condition:String, link:URL, image:URL)] = []
                
                let products = doc.css("section.items-box")
                
                for product in products{
                    let name = product.css("h3").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                    let price = product.css("div.items-box-price").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                    let link = product.css("a").first!["href"]
                    let image = product.css("img").first!["data-src"]
                    
                    tempProductList.append((name: name, price: self.getPrice(price: price), shippingPrice: 0, condition: "不明", link: URL(string: link!)!, image: URL(string: image!)!))
                    
                }
                tempProductList.sort(by: {($0.price + $0.shippingPrice) < ($1.price + $1.shippingPrice)})
                        
                self.productList += tempProductList.prefix(5)
            }
        }
    }

    //文字列で与えられた価格をintに変換
    private func getPrice(price: String) -> Int{
        
        var newPrice = ""
        
        price.forEach{
            switch $0 {
            case "0"..."9":
                newPrice += String($0)
            default:
                break
            }
        }
        return Int(newPrice)!
    }

    func isbn13Toisbn10(isbn13: String) -> String {
        var tempIsbn10 = ""
        var j = 0
        var p = 10
        var checkDigit = 0
        
        for i in isbn13.characters {
            j += 1
            if(j > 3 && j < 13){
                tempIsbn10 += String(i)
                checkDigit += Int(String(i))! * p
                p -= 1
            }
        }
        checkDigit = 11 - (checkDigit % 11)
        
        if(checkDigit == 11){
            tempIsbn10 += "0"
        } else if(checkDigit == 10){
            tempIsbn10 += "x"
        } else{
            tempIsbn10 += String(checkDigit)
        }
        
        return tempIsbn10
    }
    
    //画面遷移時に製品リストを渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResultView" {
            let nextViewController = segue.destination as! ResultViewController
            nextViewController.passedData = sender as! [String: Any]
        }
    }
}

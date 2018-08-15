import Foundation
import AVFoundation
import UIKit
import Kanna

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var productsList: [String : [ProductInfo]] = [:]
    var isbn13: String = ""
    var cCode: String = ""
    var bookImage: URL?
    var passData = [String: Any]()
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
        productsList.removeAll()
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
                
                let isbn10 = isbn13Toisbn10(isbn13: isbn13)
                self.productsList[isbn13] = []
                
                //読み取り直後に表示（もう少し工夫してもいいかも）
                //ダイアログを表示する
                let alertController = UIAlertController(title: "読み取り完了", message: "本を探しています", preferredStyle: .alert)
                //OKボタンを追加
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                //アクションを追加
                alertController.addAction(defaultAction)
                //ダイアログの表示
                present(alertController, animated: true, completion: nil)
                
                DispatchQueue.global(qos: .default).async {
                    //番号を元にスクレイピング
                    self.scrapeWebsite(isbn13: self.isbn13, isbn10: isbn10)
                    
                    DispatchQueue.main.async {
                        self.productsList[self.isbn13]?.sort(by: {($0.price! + $0.shippingPrice!) < ($1.price! + $1.shippingPrice!)})
                        
                        self.passData["productsList"] = self.productsList
                        self.passData["image"] = self.bookImage
                        
                        self.performSegue(withIdentifier: "showResultView", sender: self.passData)
                    }
                }
            }
        }
    }
    
    //取得したISBNに従ってスクレイピング
    func scrapeWebsite(isbn13: String, isbn10: String){
        //Amazon検索
        //Getリクエスト　指定URLのコードを取得
        let amazonUrl = "https://www.amazon.co.jp/s/ref=nb_sb_noss?field-keywords=\(isbn13)"
        if let amazonData = self.getHtml(url: amazonUrl){
            var productName = ""
            if let doc = try? HTML(html: amazonData, encoding: .utf8){
                //商品名取得
                productName = doc.css("li#result_0 h2").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            let detailPageUrl = "https://www.amazon.co.jp/gp/offer-listing/\(isbn10)"
            if let detailData = self.getHtml(url: detailPageUrl){
                if let doc = try? HTML(html: detailData, encoding: .utf8){
                    
                    let products = doc.css("div.olpOffer")
                    
                    for product in products.prefix(5){
                        var productInfo = ProductInfo()
                        //商品名
                        productInfo.name = productName
                        
                        //値段
                        productInfo.price = self.getPrice(price: product.css("span.a-color-price").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines))
                        
                        //送料
                        if let a = product.css("span.olpShippingPrice").first{
                            productInfo.shippingPrice = self.getPrice(price: a.text!.trimmingCharacters(in: .whitespacesAndNewlines))
                        } else{
                            productInfo.shippingPrice = 0
                        }
                        
                        //コンディション
                        productInfo.condition = product.css("span.olpCondition").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        productInfo.link = URL(string: detailPageUrl)
                        
                        if let image = doc.css("div#olpProductImage img").first!["src"]{
                            //アマゾンの画像URLを取得
                            bookImage = URL(string: image)
                            productInfo.image = URL(string: image)
                        } else{
                            print("画像見つからず")
                        }
                        
                        self.productsList[isbn13]?.append(productInfo)
                    }
                }
            }
            //メルカリ検索
            if let name_encode = productName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed){
                self.getMercariProduct(productName: name_encode)
            }
        }
    }
    
    private func getMercariProduct(productName: String) {
        let mercariUrl = "https://www.mercari.com/jp/search/?keyword=\(productName)&shipping_payer_id%5B2%5D=1&status_on_sale=1"
       
        if let mercariData = self.getHtml(url: mercariUrl){
            if let doc = try? HTML(html: mercariData, encoding: .utf8){
                
                let numberItems = doc.css("section.items-box-container h2").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                
                //要修正（０件かどうか判定）
                if(numberItems == "検索結果 0件"){
                    print(numberItems)
                } else {
                    var tempProductList: [ProductInfo] = []
                    var productInfo =  ProductInfo()
                    
                    let products = doc.css("section.items-box")
                    
                    for product in products{
                        productInfo.name = product.css("h3").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                        productInfo.price = self.getPrice(price: product.css("div.items-box-price").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines))
                        productInfo.shippingPrice = 0
                        productInfo.condition = "不明"
                        productInfo.link = URL(string: product.css("a").first!["href"]!)
                        productInfo.image = URL(string: product.css("img").first!["data-src"]!)
                        
                        tempProductList.append(productInfo)
                    }
                    
                    tempProductList.sort(by: {($0.price! + $0.shippingPrice!) < ($1.price! + $1.shippingPrice!)})
                    
                    self.productsList[isbn13]?.append(contentsOf: tempProductList.prefix(5))
                }
            }
        }
    }
    
    func getHtml(url: String) -> Data? {
        do {
            return try Data(contentsOf: URL(string: url)!)
        } catch {
            fatalError("fail to download")
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
        
        for i in isbn13 {
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

import Foundation
import AVFoundation
import UIKit
import Alamofire
import Kanna

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
     var productList: [(name:String, price:String, shippingPrice:String, condition:String, link:URL, image:URL)] = []
    
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
                        
                        // 読み取り開始
                        self.session.startRunning()
                    }
                }
            } catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.session.startRunning()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for data in metadataObjects as! [AVMetadataMachineReadableCodeObject]{
            //バーコードかどうか確認
            if data.type != .ean13 {continue}
            
            //内容が空かどうかの確認
            if data.stringValue == nil {continue}
            
            if (data.stringValue?.prefix(3).contains("192"))! {
                print("下のバーコードを読み取った\n修正しようね")
                continue
            }
            
            //読み取り終了
            self.session.stopRunning()
            
            //番号を元にスクレイピング
            scrapeWebsite(barcodeNumber: data.stringValue!)
            
            //５秒後に画面遷移（要修正）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.performSegue(withIdentifier: "showResultView", sender: self.productList)
            }
        }
    }
    
    func scrapeWebsite(barcodeNumber: String){
        //Amazon検索
        //Getリクエスト　指定URLのコードを取得
        let amazonUrl = "https://www.amazon.co.jp/s/ref=nb_sb_noss?field-keywords=\(barcodeNumber)"
        print(amazonUrl)
        Alamofire.request(amazonUrl).responseString {response in print("アマゾン一覧:\(response.result.isSuccess)")
            
            if let html = response.result.value{
                if let doc = try? HTML(html: html, encoding: .utf8){
                    let node = doc.css("li#result_0")
                    
                    if let productNumber = node.first?["data-asin"]{
                        let productName: String? = doc.css("li#result_0 h2").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                        print(productName!)
                        let detailPageUrl = "https://www.amazon.co.jp/gp/offer-listing/\(productNumber)"
                        
                        Alamofire.request(detailPageUrl).responseString { response in print("アマゾン商品:\(response.result.isSuccess)")
                            if let html = response.result.value{
                                if let doc = try? HTML(html: html, encoding: .utf8){
                                    
                                    var imageURL: URL?
                                    var price: String?
                                    var shippingPrice: String?
                                    var codition: String?
                                    
                                    if let image = doc.css("div#olpProductImage img").first!["src"]{
                                        //アマゾンの画像URLを取得
                                        imageURL = URL(string: image)
                                        
                                    } else{
                                        print("画像見つからず")
                                    }
                                    
                                    let products = doc.css("div.olpOffer")
                                    
                                    for product in products.prefix(5){
                                        //値段
                                        price = product.css("span.a-color-price").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        //送料
                                        if let a = product.css("span.olpShippingPrice").first{
                                            shippingPrice = a.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                                        } else{
                                            shippingPrice = "￥ 0"
                                        }
                                        
                                        //コンディション
                                        codition = product.css("span.olpCondition").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        self.productList.append((name: productName!, price: price!, shippingPrice: shippingPrice!,  condition: codition!, link: URL(string: detailPageUrl)!, image: imageURL!))
                                    }
                                }
                            }
                        }
                        //メルカリ検索
                        if let name_encode = productName!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed){
                            
                            let mercariUrl = "https://www.mercari.com/jp/search/?keyword=\(name_encode)&shipping_payer_id%5B2%5D=1&status_on_sale=1"
                            
                            Alamofire.request(mercariUrl).responseString { response in print("メルカリ一覧:\(response.result.isSuccess)")
                                if let html = response.result.value{
                                    if let doc = try? HTML(html: html, encoding: .utf8){
                                        
                                        let numberItems = doc.css("section.items-box-container h2").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        //要修正（０件かどうか判定）
                                        if(numberItems == "検索結果 0件"){
                                            print(numberItems)
                                        } else {
                                            var tempProductList: [(name:String, price:String, shippingPrice:String, condition:String, link:URL, image:URL)] = []
                                            
                                            let products = doc.css("section.items-box")
                                            
                                            for product in products{
                                                let name = product.css("h3").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                                                let price = product.css("div.items-box-price").first!.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                                                let link = product.css("a").first!["href"]
                                                let image = product.css("img").first!["data-src"]
                                                tempProductList.append((name: name, price: price, shippingPrice: "0", condition: "不明", link: URL(string: link!)!, image: URL(string: image!)!))
                                                
                                            }
                                            self.productList += tempProductList.prefix(5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResultView" {
            let nextViewController = segue.destination as! ResultViewController
            nextViewController.productList = sender as! [(name:String, price:String, shippingPrice:String, condition:String, link:URL, image:URL)]
        }
    }
}

//
//  PayPalCheckoutVC.swift
//  StreamVideo
//
//  Created by Kiran on 8/17/20.
//  Copyright © 2020 Kiran. All rights reserved.
//

import UIKit

class PayPalCheckoutVC: UIViewController {

    var payPalConfig = PayPalConfiguration()
    var orderId : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        self.setAcceptCreditCards(acceptCreditCards: false)
        self.configurePaypal(strMarchantName: "Awesome Shirts, Inc.")
        self.goforPayNow(shipPrice: "0", taxPrice: "0", totalAmount: "5.0", strShortDesc: "Basic", strCurrency: "USD")
        
//        self.startCheckout()
    }
    
    func acceptCreditCards() -> Bool {
        return self.payPalConfig.acceptCreditCards
    }
    
    func setAcceptCreditCards(acceptCreditCards: Bool) {
        self.payPalConfig.acceptCreditCards = acceptCreditCards
    }
    
    var environment:String = PayPalEnvironmentNoNetwork {
        willSet(newEnvironment) {
            if (newEnvironment != environment) {
                PayPalMobile.preconnect(withEnvironment: newEnvironment)
            }
        }
    }
    
    var braintreeClient: BTAPIClient?
    
    func startCheckout() {
        // Example: Initialize BTAPIClient, if you haven't already
        guard let clientId = Utility.getPayPalClientId() else {
            return
        }
        guard let client = BTAPIClient(authorization: clientId) else {
            return
        }
        
        self.braintreeClient = client
        
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient!)
        
        payPalDriver.viewControllerPresentingDelegate = self
        payPalDriver.appSwitchDelegate = self // Optional

        // Specify the transaction amount here. "2.32" is used in this example.
        let request = BTPayPalRequest(amount: "2.32")
        request.currencyCode = "USD" // Optional; see BTPayPalRequest.h for more options

        payPalDriver.requestOneTimePayment(request) { (tokenizedPayPalAccount, error) in
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                print("Got a nonce: \(tokenizedPayPalAccount.nonce)")

                // Access additional information
                let email = tokenizedPayPalAccount.email
                let firstName = tokenizedPayPalAccount.firstName
                let lastName = tokenizedPayPalAccount.lastName
                let phone = tokenizedPayPalAccount.phone

                // See BTPostalAddress.h for details
                let billingAddress = tokenizedPayPalAccount.billingAddress
                let shippingAddress = tokenizedPayPalAccount.shippingAddress
            } else if let error = error {
                // Handle error here...
                print(error)
            } else {
                // Buyer canceled payment approval
            }
        }
    }
    
    
    //MARK: Configure paypal
    func configurePaypal(strMarchantName:String) {
        // Set up payPalConfig
        payPalConfig.acceptCreditCards = self.acceptCreditCards();
        payPalConfig.merchantName = strMarchantName
        payPalConfig.merchantPrivacyPolicyURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
        payPalConfig.merchantUserAgreementURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
        
        payPalConfig.languageOrLocale = NSLocale.preferredLanguages[0]
        
        payPalConfig.payPalShippingAddressOption = .payPal;
        
        print("PayPal iOS SDK Version: \(PayPalMobile.libraryVersion())")
        PayPalMobile.preconnect(withEnvironment: environment)
    }
    
    func setupPaypal(orderId: String, clientId: String, secretKey: String, totalAmount: Float, account: String, currencyCode: String, discount: Float, shipping: Float, tax: Float) {
        var payPalConfig = PayPalConfiguration()
        //Initializaing the paypal environment with the client id.
         PayPalMobile.initializeWithClientIds(forEnvironments: [PayPalEnvironmentProduction: clientId, PayPalEnvironmentSandbox: clientId])
         payPalConfig.acceptCreditCards = true
          //Client details
         payPalConfig.merchantName = account
         payPalConfig.merchantPrivacyPolicyURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
         payPalConfig.merchantUserAgreementURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
         payPalConfig.languageOrLocale = NSLocale.preferredLanguages[0]//UserDefaults.fetch(key: UserDefaults.Keys.AppLanguageKey) ?? "en"
         payPalConfig.payPalShippingAddressOption = .payPal;
         var items = [Any]()
         let item = PayPalItem.init(name: "Product Name", withQuantity: 1, withPrice: NSDecimalNumber(string: String(format:"%.2f", totalAmount)), withCurrency: currencyCode, withSku: "ProductName")
            
         items.append(item)
         print(items)
            
         let subtotal = PayPalItem.totalPrice(forItems: items)
         let shipping = NSDecimalNumber(string: String(format:"%.2f", shipping))
         let tax = NSDecimalNumber(string: String(format:"%.2f", tax))
         let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)
         //let total = subtotal.adding(shipping).adding(tax)
         print("totallll: \(totalAmount)")
         let payment = PayPalPayment(amount: NSDecimalNumber(string: String(format:"%.2f", totalAmount)), currencyCode: currencyCode, shortDescription: orderId, intent: .sale)
         payment.items = items
          payment.paymentDetails = paymentDetails
          if (payment.processable) {
             let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
             present(paymentViewController!, animated: true, completion: nil)
          } else {
              print("Payment not processalbe: \(payment)")
         }
    }
    
    //MARK: Start Payment
    func goforPayNow(shipPrice:String?, taxPrice:String?, totalAmount:String, strShortDesc:String?, strCurrency:String) {
        var subtotal : NSDecimalNumber = 0
        var shipping : NSDecimalNumber = 0
        var tax : NSDecimalNumber = 0
//        if items.count > 0 {
//            subtotal = PayPalItem.totalPriceForItems(items as [AnyObject])
//        } else {
//            subtotal = NSDecimalNumber(string: totalAmount)
//        }
        subtotal = NSDecimalNumber(string: totalAmount)
        // Optional: include payment details
        if (shipPrice != nil) {
            shipping = NSDecimalNumber(string: shipPrice)
        }
        if (taxPrice != nil) {
            tax = NSDecimalNumber(string: taxPrice)
        }
        let total = subtotal.adding(shipping).adding(tax)
        
        var description = strShortDesc
        if (description == nil) {
            description = ""
        }
        let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)
        
        let paypalItem = PayPalItem(name: "Basic", withQuantity: 1, withPrice: total, withCurrency: strCurrency, withSku: "basic")
        
        let payment = PayPalPayment(amount: total, currencyCode: strCurrency, shortDescription: description!, intent: .sale)
        payment.items = [paypalItem] as [AnyObject]
        payment.paymentDetails = paymentDetails
        
        self.payPalConfig.acceptCreditCards = self.acceptCreditCards();
        
        if self.payPalConfig.acceptCreditCards == true {
            print("We are able to do the card payment")
        }
        
        if (payment.processable) {
            let objVC = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
            self.present(objVC!, animated: true, completion: { () -> Void in
                print("Paypal Presented")
            })
        }
        else {
            print("Payment not processalbe: \(payment)")
        }
    }
}

extension PayPalCheckoutVC : PayPalPaymentDelegate {
    
    func payPalPaymentDidCancel(_ paymentViewController: PayPalPaymentViewController) {
        print(#function)
        paymentViewController.dismiss(animated: true, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    func payPalPaymentViewController(_ paymentViewController: PayPalPaymentViewController, didComplete completedPayment: PayPalPayment) {
        print(#function)
        print("PayPal Payment Success !")
        paymentViewController.dismiss(animated: true, completion: { () -> Void in
            // send completed confirmaion to your server
            print("Here is your proof of payment:\n\n\(completedPayment.confirmation)\n\nSend this to your server for confirmation and fulfillment.")
            let dict = ["order_id": self.orderId, "paypal_payment_response": ["response": completedPayment.confirmation["response"] ?? ""]] as [String : Any]
            let paymentDict = ["response": completedPayment.confirmation["response"] ?? ""] as [String : Any]
            print(dict)
           
        })
    }
    
}

extension PayPalCheckoutVC : BTViewControllerPresentingDelegate {
    
    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        print(#function)
    }
    
    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        print(#function)
    }
    
}

extension PayPalCheckoutVC : BTAppSwitchDelegate {
    
    func appSwitcherWillPerformAppSwitch(_ appSwitcher: Any) {
        print(#function)
    }
    
    func appSwitcher(_ appSwitcher: Any, didPerformSwitchTo target: BTAppSwitchTarget) {
        print(#function)
    }
    
    func appSwitcherWillProcessPaymentInfo(_ appSwitcher: Any) {
        print(#function)
    }
    
}

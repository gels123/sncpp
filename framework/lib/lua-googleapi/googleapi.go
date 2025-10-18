// go mod init luagoogleapi
// go mod tidy
// or
// go get google.golang.org/api/androidpublisher/v3
// go get google.golang.org/api/option
// go get firebase.google.com/go
// go get firebase.google.com/go/auth

// go build -buildmode=c-shared -o libgooglebill.so googlebill.go

package main

/*
#include <stdio.h>
#include <stdlib.h>
*/
import "C"

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"unsafe"

	firebase "firebase.google.com/go"
	messaging "firebase.google.com/go/messaging"
	androidpublisher "google.golang.org/api/androidpublisher/v3"
	option "google.golang.org/api/option"
)

//google bill
var filename string
var ctx context.Context
var androidpublisherService *androidpublisher.Service
var err error

//google fcm
var fcm_filename string
var fcm_app *firebase.App
var fcm_ctx context.Context
var fcm_client *messaging.Client

type MyProductPurchase struct {
	AcknowledgementState int64  `json:"acknowledgementState"`
	ConsumptionState     int64  `json:"consumptionState"`
	Kind                 string `json:"kind"`
	OrderId              string `json:"orderId"`
	ProductId            string `json:"productId"`
	PurchaseState        int64  `json:"purchaseState"`
	PurchaseTimeMillis   int64  `json:"purchaseTimeMillis,string"`
	PurchaseType         *int64 `json:"purchaseType"`
	Quantity             int64  `json:"quantity"`
	RegionCode           string `json:"regionCode"`
}

//export doInit
func doInit(_filename string, _fcm_filename string) bool {
	if _filename != "" {
		filename = _filename
		ctx = context.Background()
		androidpublisherService, err = androidpublisher.NewService(ctx, option.WithCredentialsFile(filename))
		if err != nil {
			androidpublisherService = nil
			fmt.Println("androidpublisher.NewService error")
			return false
		}
	}
	if _fcm_filename != "" {
		fcm_filename = _fcm_filename
		fcm_app, err = firebase.NewApp(context.Background(), nil, option.WithCredentialsFile(fcm_filename))
		if err != nil {
			fcm_app = nil
			fcm_client = nil
			fmt.Println("firebase.NewApp error")
			return false
		}
		// Obtain a messaging.Client from the App.
		fcm_ctx = context.Background()
		fcm_client, err = fcm_app.Messaging(fcm_ctx)
		if err != nil {
			fcm_app = nil
			fcm_client = nil
			fmt.Println("fcm_app.Messaging error")
			return false
		}
	}
	fmt.Println("doInit ok=", _filename, _fcm_filename)
	return true
}

//export doVerify
func doVerify(packageName string, productId string, token string) (bool, *C.char) {
	fmt.Println("googlebill.go doVerify enter=", packageName, productId, token)
	if androidpublisherService == nil {
		return false, C.CString("googlebill.go doVerify error, no androidpublisherService")
	}
	ret, err := androidpublisherService.Purchases.Products.Get(packageName, productId, token).Do()
	// fmt.Println("doVerify ret== OrderId=", ret.OrderId, "ProductId=", ret.ProductId, "Kind=", ret.Kind, "ConsumptionState=", ret.ConsumptionState, "PurchaseState=", ret.PurchaseState, "PurchaseTimeMillis=", ret.PurchaseTimeMillis, "PurchaseType=", ret.PurchaseType, "Quantity=", ret.Quantity, "RegionCode=", ret.RegionCode)
	if err != nil {
		// fmt.Println("googlebill.go doVerify error, ret=", ret, "err=", err.Error())  //has bug
		return false, C.CString(err.Error())
	}

	//field must be given, can not ignore
	var ret2 MyProductPurchase
	ret2.AcknowledgementState = ret.AcknowledgementState
	ret2.ConsumptionState = ret.ConsumptionState
	ret2.Kind = ret.Kind
	ret2.OrderId = ret.OrderId
	ret2.ProductId = ret.ProductId
	ret2.PurchaseState = ret.PurchaseState
	ret2.PurchaseTimeMillis = ret.PurchaseTimeMillis
	ret2.PurchaseType = ret.PurchaseType
	ret2.Quantity = ret.Quantity
	ret2.RegionCode = ret.RegionCode

	res, err := json.Marshal(ret2)
	if err != nil {
		return false, C.CString("googlebill.go doVerify error, json fail")
	}
	return true, C.CString(string(res))
}

//export FreeString
func FreeString(p *C.char) {
	if p != nil {
		C.free(unsafe.Pointer(p))
	}
}

func main() {
	fmt.Println("=======main start======")
	// ctx = context.Background()
	// filename = "/home/share/lnx_server3/server/depends/lua-googleplay/slgz-cbt1-api-32fcbf10046f.json"
	// androidpublisherService, err = androidpublisher.NewService(ctx, option.WithCredentialsFile(filename))
	// if err != nil {
	// 	androidpublisherService = nil
	// 	fmt.Println("androidpublisher.NewService error")
	// 	return
	// }
	// packageName := "com.tutenslgz.cbt001"
	// productId := "daily_0001"
	// token := "bjjfkcabiiljnicjmpmclpgo.AO-J1Oz9kKAIV8Ew4y3BcJGI0eJA4qEqUAeZ4xPGEIcduROPEc6Gju_em3osqNPv3vF0MGdUlgRTXtfhq3Ewlp6Z5eLc518v6w"
	// ret, err := androidpublisherService.Purchases.Products.Get(packageName, productId, token).Do()
	// fmt.Println("==========sdf==ret=", ret, "err=", err.Error())

	//fcm
	filename = "/home/share/lnx_server3/server/depends/lua-googleapi/gelsfirebase20221114-firebase-adminsdk-2z96g-f3f0335935.json"
	fcm_app, err = firebase.NewApp(context.Background(), nil, option.WithCredentialsFile(filename))
	if err != nil {
		fmt.Println("error initializing app: %v\n", err.Error())
		return
	}
	// Obtain a messaging.Client from the App.
	fcm_ctx = context.Background()
	// fcm_client, err := fcm_app.Auth(fcm_ctx)
	fcm_client, err = fcm_app.Messaging(fcm_ctx)
	if err != nil {
		fmt.Println("error getting Messaging client: %v\n", err.Error())
	}

	topic := "world_1"
	// This registration token comes from the client FCM SDKs.
	registrationToken := "fxV6ToLJh3A:APA91bGfcaOl4mmnj_mPY7MTscjzT0aZLvyK5xaLLboWavxFoeqc3hZu_npEtaINebzHAfOrARg4kn9RmWC9ZYKvhqJrPhnNI43qtUruQsvd7Or7w_ZnDG4agOMM_7xB0J4ci9UHPT5S"

	// These registration tokens come from the client FCM SDKs.
	registrationTokens := []string{
		registrationToken,
		// ...
		"cBYSJNhfG_Q:APA91bFzLxiSVynUc2thc6aGfF1ba_6WoJvOctw2_1cIlUEr2r7Pf-n_Qk6uisLpc9Whcf-UU4WwcjnRwLTm_Zok1pH2RGw2_WvLmaT_AdZp84caH29haB4gQFIdrc0wQSr-vVgR0F3o",
	}
	subscribe(topic, registrationTokens)
	sendMsgToToken(registrationToken, "news", "hello kitty.")
	sendMsgToTopic(topic, "news", "hello kitty.")

	fmt.Println("=======main end======", fcm_app)
}

//export sendMsgToTopic
func sendMsgToTopic(topic string, title string, body string) bool {
	if fcm_ctx == nil || fcm_client == nil || topic == "" || title == "" || body == "" {
		fmt.Println("sendMsgToTopic error1")
		return false
	}
	notification := &messaging.Notification{
		Title: title,
		Body:  body,
	}
	// See documentation on defining a message payload.
	message := &messaging.Message{
		Notification: notification,
		Topic:        topic,
	}
	// Send a message to the devices subscribed to the provided topic.
	response, err := fcm_client.Send(fcm_ctx, message)
	if err != nil {
		fmt.Println("sendMsgToTopic error2", err.Error())
		return false
	}
	// Response is a message ID string.
	fmt.Println("sendMsgToTopic Successfully sent message:", response)
	return true
}

//export sendMsgToToken
func sendMsgToToken(registrationToken string, title string, body string) bool {
	if fcm_ctx == nil || fcm_client == nil || registrationToken == "" || title == "" || body == "" {
		fmt.Println("sendMsgToToken error1")
		return false
	}
	// See documentation on defining a message payload.
	notification := &messaging.Notification{
		Title: title,
		Body:  body,
	}
	message := &messaging.Message{
		// Data: map[string]string{
		//  "score": "850",
		//  "time": "2:45",
		// },
		Notification: notification,
		// Webpush: &messaging.WebpushConfig{
		// 	Notification: &messaging.WebpushNotification{
		// 		Title: "title",
		// 		Body:  "body",
		// 		//      Icon: "icon",
		// 	},
		// 	FcmOptions: &messaging.WebpushFcmOptions{
		// 		Link: "https://fcm.googleapis.com/",
		// 	},
		// },
		Token: registrationToken,
	}
	// Send a message to the device corresponding to the provided
	// registration token.
	response, err := fcm_client.Send(fcm_ctx, message)
	if err != nil {
		fmt.Println("sendMsgToToken error2", err.Error())
		return false
	}
	// Response is a message ID string.
	fmt.Println("sendMsgToToken Successfully sent message:", response)
	return true
}

//export subscribe
func subscribe(topic string, tokens []string) bool {
	if fcm_ctx == nil || fcm_client == nil || topic == "" || len(tokens) <= 0 {
		fmt.Println("subscribe error1")
		return false
	}
	fmt.Println("subscribe topic=", topic, "lentokens=", len(tokens), "tokens[0]=", tokens[0])
	// Subscribe the devices corresponding to the registration tokens to the topic.
	response, err := fcm_client.SubscribeToTopic(fcm_ctx, tokens, topic)
	if err != nil {
		fmt.Println("subscribe error2", err.Error())
		return false
	}
	// See the TopicManagementResponse reference documentation for the contents of response.
	if len(response.Errors) > 0 {
		for i := 0; i < len(response.Errors); i++ {
			fmt.Println("subscribe SuccessCount=", response.SuccessCount, "FailureCount=", response.FailureCount, "tokens subscribe fail", i, response.Errors[i].Reason)
		}
	} else {
		fmt.Println("subscribe SuccessCount=", response.SuccessCount, "FailureCount=", response.FailureCount, "tokens subscribe success")
	}
	return true
}

//export unsubscribe
func unsubscribe(topic string, tokens []string) bool {
	if fcm_ctx == nil || fcm_client == nil || topic == "" || len(tokens) <= 0 {
		fmt.Println("unsubscribe error1")
		return false
	}
	fmt.Println("unsubscribe topic=", topic, "lentokens=", len(tokens), "tokens[0]=", tokens[0])
	response, err := fcm_client.UnsubscribeFromTopic(fcm_ctx, tokens, topic)
	if err != nil {
		fmt.Println("unsubscribe error2", err.Error())
		return false
	}
	// See the TopicManagementResponse reference documentation for the contents of response.
	if len(response.Errors) > 0 {
		for i := 0; i < len(response.Errors); i++ {
			fmt.Println("unsubscribe SuccessCount=", response.SuccessCount, "FailureCount=", response.FailureCount, "tokens unsubscribe fail", i, response.Errors[i].Reason)
		}
	} else {
		fmt.Println("unsubscribe SuccessCount=", response.SuccessCount, "FailureCount=", response.FailureCount, "tokens unsubscribe success")
	}
	return true
}

func createCustomToken(ctx context.Context, app *firebase.App) {
	authClient, err := app.Auth(context.Background())
	if err != nil {
		fmt.Println("error getting Auth client: %v\n", err.Error())
		return
	}

	token, err := authClient.CustomToken(ctx, "25696773511053390")
	if err != nil {
		fmt.Println("error minting custom token: %v\n", err.Error())
		return
	}
	log.Printf("Got custom token: %v\n", token)
}

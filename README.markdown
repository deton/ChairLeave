# 自作マットスイッチで離席検出してPCスクリーンロックするBLEデバイス

![写真](../img/chairleave.jpg)

BLEのProximity Profile(PXP)対応デバイスです。
PXPデバイスを持ち歩くのは面倒なので、椅子側に設置して、
自作マットスイッチで離席を検出した時にコネクションを切断するようにしています。
PC側は、BluetoothスタックのPXP機能をそのまま使ってロックされます。

[人感センサによるスクリーンロック回避USBデバイス](https://github.com/deton/avoidscreenlock)
を作ったのですが、たまにロックされないままになっていることがあるので作成。

## 部品
### デバイス側
+ 自作マットスイッチ(センサーパッド)。アルミホイルとクリアファイル(0.2mm厚)で作成。
  スペーサにするため、クリアファイルを片側だけに切って、2穴パンチで直径6mmの穴をたくさん開ける
  (1cm角の穴をカッターでいくつか開けたものだと、座布団の下に置くだけでスイッチオン)。
  アルミホイルではさんで、封筒に入れる。
  koshianからのリード線にゼムクリップを付けてアルミホイルをはさむ(アルミは普通の半田では半田付けできないので)。
  自作マットスイッチを座布団の下に置く。
  (封筒のかわりにクリアファイルだと少し厚みがあるので座りごこちがいまいち。
  ビニール袋だとすべっていまいち)
+ [koshian](http://www.m-pression.com/ja/solutions/boards/koshian)
+ [konashi小型化拡張ボード](http://yukaishop.base.ec/items/559791)。LDOが載っているので、電源は3.2V-12.0V可
+ [cheero Canvas 3200mAh IoT 機器対応](http://www.cheero.net/products/canvas-iot/)。普通のモバイルバッテリだと電流量が少なくてしばらくするとオフになるのでIoT向けのモバイルバッテリ
+ [ブレッドボード用5V電源ボード Micro-B版 ヒューズ付き](https://www.switch-science.com/catalog/2443/)
+ (マットスイッチ読取状態表示用LEDと抵抗10kΩ)
+ SDKサンプルのPXPファームウェアを変更して、マットスイッチがオフになったらコネクション切断するように変更。

WICED-Smart-SDK-2.2.2のbleprox.cに対する変更点
(bleprox.cがオープンソースでないので、ソース公開でなく変更方法のみ公開)

```
mkdir Apps\chair_leave
copy Wiced-Smart\bleapp\app\bleprox.c Apps\chair_leave\chair_leave.c
gvim Apps\chair_leave\chair_leave.c
```

### PC側(Windows7)
+ I-O DATA USB-BT40LE
いくつか試したところ、Broadcomスタック(I-O DATA USB-BT40LE)のロック機能が使いやすそうでした。
ロック前に10秒のカウントダウンダイアログが表示されるので、
座り直す等の対応ができます。
![カウントダウンダイアログ](../img/countdown.jpg)
Motorolaスタック(Planex BT-Micro4)や東芝スタック(Logitec LBT-PCSCU01DWH)ではいきなりロック。
(CSRスタック(Logitec LBT-UAN04C1BK)はインストール中エラーが出ているせいか、PXP動作を確認できず。
IVRスタック(BlueSoleil)(ELECOM LBT-UAN05C2)では、ロック前カウントダウンダイアログは表示されるが、
設定ダイアログを閉じるとPXP機能がオフになるようで、使いにくい)
(なお、PXP動作はPXPタグLBT-PCSCU01で確認)
http://36yen.blogspot.jp/2015/06/bluetooth.html

## はまった点
### mbed BLE APIでdisconnection reason 0x22
当初、mbed BLE APIでBLE NanoやRedBearLab nRF51822を使って開発していた際、
すぐに切断される現象が発生。
PC側のUSB BLEの問題かと思ってclass 2でなくclass 1のものを買ったりしてみたが
状況変わらず。

試しにAndroidと接続した場合は切断されない。

40秒で切断される。切断時の理由コードを出力してみたら、0x22。
Bluetooth仕様を見ると、LL Response Timeout。
Connection supervisory timeout等を変えてみるが関係無い模様。
mbed BLE APIで作るのは断念。

Nordic SDKやBroadcom SDKを試す。
nRF51822の問題だとSDKでも駄目かもしれないと思って、koshian(Broadcom BCM20737S)を選択。
(後に、Nordic SDKでPXPサンプルをビルドしてBLE Nanoで試したところは切断されないことを確認。APIとしてはNordic SDKの方がきれいな印象)

### koshianでファームウェア書き換え後、アドバタイズがすぐ止まる
(koshianのOTAでのファームウェア書き換えはうまくいかず、有線で書き換え。
後からこのページを見つけるが未試行。
http://qiita.com/toyoshim/items/040056f08ebf9ee6ab59)

原因がわからずしばらくはまる。
Broadcom Communityを調べて、Crystal Warm-Up workaroundを行うことで解決。

### 離席検出センサ
検出方法をいくつか試して、自作マットスイッチに落ち着く。

* [シャープ赤外線測距モジュールGP2Y0E03](http://akizukidenshi.com/catalog/g/gI-07547/): 角度がずれるとうまく検出できず
* [フォトリフレクタで座布団にかかる圧力を計測](http://yutasugiura.com/research/yurufuwa/yurufuwa.html#fuwafuwa): センサ1個だけだと検出が難しそうな感じ
* マットスイッチ。秋葉原高架下の防犯カメラ等を扱っている店で処分価格1000円になっていたもの。しっかり体重をかけた時のみ反応するので確実性は高い。ただし、かためなので今回の用途では座りごこちが悪い。
その他、介護関係の徘徊センサーや、工場の安全装置等で使われているものがあるようだが確実性が重要なので高価。

## 課題
* マットスイッチの上に置く座布団の位置によって、離席してもオンになったままになる場合あり。
  逆に、座る位置や姿勢によってたまにオフになる場合あり。
  座布団の上に置けばほぼ問題なし。
  自作マットスイッチのスペーサの穴の大きさ・形・配置・数はさらなる調整が必要そう。
* しばらくするとPC側がずっと接続したままとみなすようになる場合あり。
  特に休止状態から復帰した後。

## 関連
+ BluetoothデバイスがPCから離れた時に自動ロック。
  Bluetooth 4.0のProximity Profile(PXP)。
  (Bluetoothデバイスを持ち歩く必要あり)
	+ [パソコンから離れると自動でロックし近づくとロック解除。Bluetooth4.0対応セキュリティーカードとレシーバー](http://buffalo.jp/product/news/2012/09/05_04/)
	+ [ぶるタグ](http://pc.nikkeibp.co.jp/article/column/20120912/1062902/?P=2)
	+ [Ubuntuで同様に](http://gihyo.jp/admin/serial/01/ubuntu-recipe/0267)
+ BroadcomのBluetoothスタックには、
  A2DP等で接続している携帯端末が離れた時にロックする機能あり
+ [BtProx: Bluetooth Proximity Lock Utility](btprox.sourceforge.net)
+ [PeopleLogOn スマホのWi-Fi電波などを利用して離席時にパソコンをオートロックする、手軽なセキュリティ対策ソフト](http://www.vector.co.jp/magazine/softnews/150613/n1506131.html)
+ [WinSensorシリーズ（SENSOR-HM/ECO）](http://www.iodata.jp/product/lcd/option/sensor-hmeco/)。人感センサーで離席時に省電力モードに切替
+ Android 5.0はPXPに対応しているが、ホスト側としての対応のみの模様(F-04Gで試した感じでは)。
+ [自作マットスイッチで犬が話すドッグトーキングマシン製作例](http://www.mycomkits.com/hpgen/HPB/entries/27.html)

+ [人感センサによるスクリーンロック回避USBデバイス](https://github.com/deton/avoidscreenlock)

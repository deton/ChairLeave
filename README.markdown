# 感圧センサで離席検出してPCスクリーンロックするBLEデバイス

BLEのProximity Profile(PXP)対応デバイスです。
PXPデバイスを持ち歩くのは面倒なので、椅子側に設置して、
感圧センサ(や自作マットスイッチ)で離席を検出した時にコネクションを切断するようにしています。
PC側は、BluetoothスタックのPXP機能をそのまま使ってロックされます。

![写真](../img/chairleave.jpg)

[人感センサによるスクリーンロック回避USBデバイス](https://github.com/deton/avoidscreenlock)
を作ったのですが、たまにロックされないままになっていることがあるので作成。

## 部品
### デバイス側
+ [koshian](http://www.m-pression.com/ja/solutions/boards/koshian)
+ [konashi小型化拡張ボード](http://yukaishop.base.ec/items/559791)。
  LDOが載っているので、電源は3.2V-12.0V可
+ [感圧センサ](https://www.switch-science.com/catalog/2615/)
+ 抵抗10kΩ(プルダウン用)
+ [cheero Canvas 3200mAh IoT 機器対応](http://www.cheero.net/products/canvas-iot/)。
  普通のモバイルバッテリだと電流量が少なくてしばらくするとオフになるのでIoT向けのモバイルバッテリ
+ [ブレッドボード用5V電源ボード Micro-B版 ヒューズ付き](https://www.switch-science.com/catalog/2443/)
+ (センサ読取状態表示用LEDと抵抗10kΩ)

回路は、
[『Prototyping Lab――「作りながら考える」ためのArduino実践レシピ』](http://www.oreilly.co.jp/books/9784873114538/)
にあるものそのままです。

SDKサンプルのPXPファームウェアを変更して、感圧センサのADC読取値が一定以下になったらコネクション切断するように変更。

WICED-Smart-SDK-2.2.2のbleprox.cに対する変更です。
(bleprox.cがオープンソースでないので、ソース公開でなく変更差分のみ公開)

コマンドプロンプトで、WICED-Smart-SDK-2.2.2のmake.exeのあるディレクトリで、
genChairLeave.batを実行すると、変更後のファームウェアソースを生成します
(要vim。vim.exeにPATHを通しておいてください)。

### PC側(Windows7)
+ I-O DATA USB-BT40LE
USB BLEをいくつか試したところ、
Broadcomスタック(I-O DATA USB-BT40LE)のロック機能が使いやすそうでした。
ロック前に10秒のカウントダウンダイアログが表示されるので、
姿勢を変えたり座り直す等の対応ができます。
![カウントダウンダイアログ](../img/countdown.png)
![PXP設定ダイアログ](../img/broadcompxp2.png)

参考: その他試したUSB BLE(PXP動作はPXPタグLBT-PCSCU01で確認):
+ Motorolaスタック(Planex BT-Micro4)ではいきなりロック。
+ 東芝スタック(Logitec LBT-PCSCU01DWH)はMotorolaスタックと同様。
+ IVRスタック(BlueSoleil)(ELECOM LBT-UAN05C2)では、
  ロック前カウントダウンダイアログは表示されるが、
  設定ダイアログを閉じるとPXP機能がオフになるようで、使いにくい
+ CSRスタック(Logitec LBT-UAN04C1BK)はインストール中エラーが出たせいか、
  PXP動作を確認できず。

参考: http://36yen.blogspot.jp/2015/06/bluetooth.html

## はまった点
### mbed BLE APIでdisconnection reason 0x22
当初、mbed BLE APIでBLE NanoやRedBearLab nRF51822を使って[開発を始めた](https://developer.mbed.org/users/deton/code/ChairLeave/)が、
すぐに切断される現象が発生。
PC側のUSB BLEの問題かと思ってclass 2でなくclass 1のものを買ったりしてみたが
状況変わらず。

試しにAndroidと接続した場合は切断されない。

40秒で切断される。切断時の理由コードを出力してみたら、0x22。
Bluetooth仕様を見ると、LMP Response Timeout / LL Response Timeout。
Connection supervisory timeout等を変えてみるが関係無い模様。
mbed BLE APIで作るのは断念。

Broadcom SDKやNordic SDKを試す。
nRF51822の問題だとSDKでも駄目かもしれないと思って、koshian(Broadcom BCM20737S)を選択。
(後に、Nordic nRF51 SDKでPXPサンプルをビルドしてBLE Nanoで試したところは切断されないことを確認。APIとしてはNordic SDKの方がきれいな印象)

### koshianでファームウェア書き換え後、アドバタイズがすぐ止まる
原因がわからずしばらくはまる。
Broadcom Communityを調べて、[Crystal Warm-Up workaround](https://community.broadcom.com/message/3607#3607)を行うことで解決。

#### koshianのファームウェア書き換え方法
koshianのOTAでのファームウェア書き換えはうまくいかず、有線で書き換え。
後からこのページを見つけるが未試行。
http://qiita.com/toyoshim/items/040056f08ebf9ee6ab59

F/W書き込み/デバッグ用端子のTXとRXパッドにのみ配線を半田付け。
VCCとGNDは他のピンを使用。

F/W書き換え時は、TX,RX,GND,VCCを[USB-Serial-FTDI](https://www.switch-science.com/catalog/1032/)に接続した後、PCにUSBケーブル接続。
コマンドラインでWiced-Smart-SDKディレクトリでmake。

ble_trace1()等によるデバッグ出力確認は、
PCとのUSBケーブルは外した状態で電源を入れた後、
F/W書き込み/デバッグ用端子のTX,RX,GNDのみUSB-Serial-FTDIに接続して、PCにUSBケーブル接続。
Baud rate 115200。TeraTermの場合Terminal設定のNew-line ReceiveをAUTOに。

### 離席検出センサ
検出方法をいくつか試して、感圧センサに落ち着く。次点は自作マットスイッチ。

感圧センサの場合、座っている際の違和感もほとんど無く、
センシングもほぼ期待通り行われるが、
たまに着席しているのにそうでないと認識される場合あり。
姿勢を変えたり座り直したりするとOK。

確実に着席を認識する点では、自作マットスイッチを座布団の上に置く方が良い印象。
ただ、座布団の上に自作マットスイッチを置くと座りごこちが悪くなるのが欠点。
(座布団の下に置くと、離席時にスイッチオフにならない場合があり、調整が難しい)

### 自作マットスイッチ(センサーパッド)
アルミホイルとクリアファイル(0.2mm厚)で作成。

![自作マットスイッチ](../img/matswitch.jpg)

作り方:

1. スペーサにするため、クリアファイルを片側だけに切って、
   2穴パンチで直径6mmの穴をたくさん開ける
   (1cm角の穴をカッターでいくつか開けたものだと、座布団の下に置くだけでスイッチオン)。
2. スペーサをアルミホイルではさんで、封筒に入れる。
3. koshianからのリード線にゼムクリップを付けてアルミホイルをはさむ
   (アルミは普通の半田では半田付けできないので)。

自作マットスイッチを座布団の下に置く。確実性が欲しい場合は座布団の上に置く。
(封筒のかわりにクリアファイルだと少し厚みがあるので座りごこちがいまいち。
ビニール袋だとすべっていまいち)

### その他センサ
* マットスイッチ製品。秋葉原高架下の防犯カメラ等を扱っている店で処分価格1000円になっていたもの。
  しっかり体重をかけた時のみ反応するので確実性は高い。
  ただし、堅めなので今回の用途では座りごこちが悪い。
  その他、介護関係の徘徊センサーや、工場の安全装置等で使われているものがあるようだが確実性が重要なので高価。
* [シャープ赤外線測距モジュールGP2Y0E03](http://akizukidenshi.com/catalog/g/gI-07547/): 角度がずれるとうまく検出できず
* [フォトリフレクタで座布団にかかる圧力を計測](http://yutasugiura.com/research/yurufuwa/yurufuwa.html#fuwafuwa): センサ1個だけだと検出が難しそうな感じ

## 課題
* 自作マットスイッチの上に置く座布団の位置によって、離席してもオンになったままになる場合あり。
  逆に、座る位置や姿勢によってたまにオフになる場合あり。
  座布団の上に置けばほぼ問題なし。
  自作マットスイッチのスペーサの穴の大きさ・形・配置・数はさらなる調整が必要そう。
* 休止状態からの復帰後、しばらくするとPC側がずっと接続したままとみなすようになる場合あり。

## 関連
+ BluetoothデバイスがPCから離れた時に自動ロック。
  Bluetooth 4.0のProximity Profile(PXP)。
  (Bluetoothデバイスを持ち歩く必要あり)
	+ [パソコンから離れると自動でロックし近づくとロック解除。Bluetooth4.0対応セキュリティーカードとレシーバー](http://buffalo.jp/product/news/2012/09/05_04/)
	+ [ぶるタグ](http://pc.nikkeibp.co.jp/article/column/20120912/1062902/?P=2)
	+ [Ubuntuで同様に](http://gihyo.jp/admin/serial/01/ubuntu-recipe/0267)
+ BroadcomのBluetoothスタックには、
  A2DP等で接続している携帯端末が離れた時にロックする機能あり
+ [BtProx: Bluetooth Proximity Lock Utility](http://btprox.sourceforge.net/)
+ [PeopleLogOn スマホのWi-Fi電波などを利用して離席時にパソコンをオートロックする、手軽なセキュリティ対策ソフト](http://www.vector.co.jp/magazine/softnews/150613/n1506131.html)
+ [WinSensorシリーズ（SENSOR-HM/ECO）](http://www.iodata.jp/product/lcd/option/sensor-hmeco/)。人感センサーで離席時に省電力モードに切替
+ Android 5.0はPXPに対応しているが、ホスト側としての対応のみの模様(F-04Gで試した感じでは)。
+ [自作マットスイッチで犬が話すドッグトーキングマシン製作例](http://www.mycomkits.com/hpgen/HPB/entries/27.html)

# cordova-plugin-wxpay

这个是一个cordova插件，专用于iOS版本的微信支付。其实在做这个插件之前已经尝试使用过其他的Cordova微信支付插件了，可惜，微信支付的框架会经常发生。所以，如果一些插件库不经常更新的话，旧的插件会变得无法使用。

所以，在这里写这个插件主要是尝试自己完成一个插件的开发。如果你之后需要用到这个插件，并且我不再更新了的话。相信自己，你也能够自己开发一个类似的插件。

## 主要文件介绍
插件目录：

* src
	* ios
		* ios下的原生文件
	* android
		* android下的原生文件
* www
	* js文件
* plugin.xml

插件开发主要需要用到的文件需要用到上面的文件路径。我这个插件路径也是一样，可以作为参考（安卓不会，别问我）。。。

### src文件
主要有ios以及android两个文件夹，当然，cordova支持的其他平台也可以添加类似的文件夹来完成这个插件支持的平台。

主要介绍ios下的，其实其他平台也类似，需要同事协助，当然你自己厉害，全部开发了也行。

ios下面，可以看到几个文件。

```
* AppleDelegate+CDVWpay.h
* AppleDelegate+CDVWpay.m
* CDVWxpay.h
* CDVWxpay.m
* libWeChatSDK.a
* WechatAuthSDK.h
* WXApi.h
* WXApiObject.h
```

前面四个文件是自己编写的，上面的js文件（也就是我的wxpayPlugin.js）也就是通过读取自己编写的原生的代码来生成一个js类，原生的类需要特殊的写法，下面介绍。然后后面的四个是微信开放平台的iOS开发工具包下的文件。

现在来看一下四个自己编写的文件

#### AppleDelegate+CSDVWpay
如果做过iOS开发应该可以看得出来这个是一个AppDelegate的类目，他主要的工作是：通过runtime获得`-application:didFifnishLaunchimgWithOptions:`方法，为这个方法添加代码。添加的代码就是我们平常微信开发中的接入第一步了，在`-application:didFifnishLaunchimgWithOptions:`方法内向微信平台注册应用程序id。并且设置代理以及重写AppDelegate的handleOpenURL和openURL方法。

**注意：上面这样做的原因是：我们无法直接将整个AppDelegate文件放入到我们的`src/ios`目录下面，因为这个目录下的文件其实都会在cordova构建ios应用程序的时候放入ios工程内，如果直接写一个AppDelegate文件，会产生两个相同文件的错误。**

#### CDVWxpay
这个类就是真正完成支付的类了。

注意他的格式，他的父类应该是CDVPlugin。里面有`-payment`方法，通过js来调用，这个方法就是原生代码完成的微信支付了。可以直接根据微信Demo来模仿。在这个方法内需要注意，如果你想返回数据回到js当中，你需要放回一个CDVPluginResult的对象出去，具体返回可以看详细代码。

在这个类当中，还实现了WXApiDelegate，实现了页面回调。


### www文件
www文件里面主要存放js代码，这段js代码就是通过原生的代码来生成一个js对象的。当我们在cordova项目中使用这个js对象的时候，在平台下，他会根据你的配置文件（Plugin.xml）来调用具体的某个平台的某个类的某个方法。

学过js都应该看得懂的，唯一有点不懂可能是`exec(success, fail, 'CDVWxpay', 'payment', option)`这一句。这句代码的几个参数，分别是成功回调方法，失败回调方法，调用原生代码的类名，原生类中的方法，以及参数。

### plugin.xml
这个就是整个插件的配置文件了。一句句看

plugin中id代表你插件名字，这个最好按照官方的命名方式`cordova-plugin-*`，version当然就是版本了。

* name就是你插件的名字了。

* description是插件的描述了。

* engines说明这个插件需要的配置。

* js-module指向js文件

* platform指向具体平台
	* source-file代表引入的资源文件，可以看到.a文件也算是资源文件。`framework="true"`代表该文件是框架文件。`compiler-flags="-Objc -all_load"`之前按照iOS接入指南会发现需要iOS工程下`Other Linker Flags`设置为`"-Objc -all_load`会发现没有工程给我们去设置（因为iOS工程需要构建之后才会出现，而插件开发是在构建之前开发完成的），其实就在这里设置就可以了。其他的类的实现文件也在这里引入。
	* framework代表引入的框架，可以看到，微信需要我们手动引入的框架也是在这里引入
	* header-file代表类声明文件。
	* config-file代表在plist或者在xml中添加节点，第一个config.xml代表在原生工程里面的info.plist文件加入的配置。第二个config.xml代表在cordova的配置文件`config.xml`内添加的配置。
	
	
## Usage
直接在cordova内引入，通过命令行添加这个插件

`
cordova plugin add https://github.com/vito7zhang/cordova-plugin-wxpay.git
`

在需要用到的地方直接使用

```
wxpay.payment(function(msg){
          console.log("成功");
          console.log(msg);
      },function(msg){
          console.log("失败");
          console.log(msg);
      },[{
          appid: "***",
          partnerid: "**",
          noncestr: "**",
          prepayid: "**",
          package: "**",
          timestamp: "**",
          sign: "**"
      }]
```

来调起原生的微信客户端。

这里需要注意，这一步骤对应的应该是微信中支付当中的应用客户端发起微信支付调用微信客户端的步骤。

在这之前应该

1. 由应用客户端向应用服务端发起请求生成支付订单
2. 由应用服务端签名数据，向微信支付系统调用统一下单的API，然后返回预支付订单（prepay_id），然后再次签名数据后再返回给应用客户端。

### TODO
安卓版本

支付宝支付插件

### End
这里仅仅做了的是cordova微信支付的的iOS端，android正在完善，不过文档应该也不会再写了，因为也是很类似的。

除此之外，微信支付还需要应用客户端和应用服务器端做成功支付的校验。需要自己完善
写于：2017.5.25







# xcodebuild_shell

### 最近在弄持续集成方案，因为Jenkins自动打包同样要使用手动触发，同时也不需要定时去打包上传，我们就写了一个shell脚本，当模块完成时候去上传蒲公英交付测试，之后会写一个使用ApplicationLoader上传App Store的脚本，本文默认您已经进行过打包流程并成功

##### 在正式版Xcode9更新之后，之前的脚本无法使用，报错如下
```
error: exportArchive: "AppName.app" requires a provisioning profile with the Push Notifications and App Groups features.
Error Domain=IDEProvisioningErrorDomain Code=9
```
##### 首先我们需要先进行 xcodebuild export plist 配置
##### 如下图所示，一步一步做

![我们手动进行打包操作](http://upload-images.jianshu.io/upload_images/2353844-9b5471a4061e1e6d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![打包~~~](http://upload-images.jianshu.io/upload_images/2353844-22fec9045a3537c6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![打包~~~](http://upload-images.jianshu.io/upload_images/2353844-4dc56709392ea722.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![打包~~~](http://upload-images.jianshu.io/upload_images/2353844-0acb5eac86b88a7c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![我们就要这个plist文件](http://upload-images.jianshu.io/upload_images/2353844-d8126c80fb8a7998.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image.png](http://upload-images.jianshu.io/upload_images/2353844-f1f9adb9b6d83262.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


##### 我们还要将里面的`compileBitcode`设置为`NO`,这个很关键，不然会出现一系列有趣的问题，关于`Bitcode`的问题可以看官网[App Thinning](https://developer.apple.com/library/content/documentation/IDEs/Conceptual/AppDistributionGuide/AppThinning/AppThinning.html),下面我们的比较关键的一步就完成了
##### 下面就是我没有改设置的报错，一脸蒙B... 没有任何提示...
```
Segmentation fault: 11
```

### 下面我们开始打包
##### *我们打包的前提是需要自动配置证书，打包的模式是Release，请设置对应的值，我们在脚本里不需要设置`CODE_SIGN_IDENTITY `和`PROVISIONING_PROFILE `*

![image.png](http://upload-images.jianshu.io/upload_images/2353844-b77cf4a888c2c0d1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image.png](http://upload-images.jianshu.io/upload_images/2353844-d11066a8c2a8af67.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##### 由于我们有正式接口和测试接口包需要交付测试测试，我们这边就需要手动打包两次获取对应ExportOptions.plist

```
#go!

PREFIX_SYMBOL="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "开始上传\n\n"

#工程名
PROJECTNAME="XXX"
#需要编译的 targetName
TARGET_NAME="XXX"
#是否是工作空间
ISWORKSPACE=true
# 开始时间
DATE=`date '+%Y-%m-%d-%T'`
#编译模式 工程默认有 Debug Release 
CONFIGURATION_TARGET=Release
#编译路径
BUILDPATH=~/Desktop/${TARGET_NAME}_${DATE}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${TARGET_NAME}.xcarchive
#输出的ipa目录
IPAPATH=${BUILDPATH}
#导出ipa 所需plist
FormalExportOptionsPlist=./FormalExportOptions.plist
TestExportOptionsPlist=./TestExportOptions.plist
ExportOptionsPlist=${FormalExportOptionsPlist}
# 是否上传蒲公英
UPLOADPGYER=false



echo "选择接口${PREFIX_SYMBOL}"
echo "1 正式接口${PREFIX_SYMBOL}"
echo "2 测试接口${PREFIX_SYMBOL}"
echo "默认正式接口${PREFIX_SYMBOL}"

# 读取用户输入并存到变量里
read parameter
sleep 0.5

# 判读用户是否有输入 
if [ -n "$parameter" ]
then
	if [ "$method" = "1" ]
	then
	ExportOptionsPlist=${FormalExportOptionsPlist}
	elif [ "$method" = "2" ]
	then
	ExportOptionsPlist=${TestExportOptionsPlist}
	else
	echo "参数无效"
	exit 1
	fi
else
	ExportOptionsPlist=${FormalExportOptionsPlist}
fi

echo "上传蒲公英${PREFIX_SYMBOL}"
echo "1 不上传${PREFIX_SYMBOL}"
echo "2 上传${PREFIX_SYMBOL}"
echo "默认不上传${PREFIX_SYMBOL}"

read para
sleep 0.5

if [ -n "$para" ]
then
	if [ "$para" = "1" ]
	then 
	UPLOADPGYER=false
	elif [ "$para" = "2" ]
	then
	UPLOADPGYER=true
	else
	echo "参数无效...."
	exit 1
	fi
else
	UPLOADPGYER=false
fi


echo "输出相关编译参数${PREFIX_SYMBOL}"

if [ $ISWORKSPACE = true ]
then
echo "项目基于工作空间"
else
echo "项目不是基于工作空间"
fi

echo "编译模式: ${CONFIGURATION_TARGET}"
echo "导出ipa配置文件路径: ${ExportOptionsPlist}"
echo "打包文件路径: ${ARCHIVEPATH}"
echo "导出ipa路径: ${IPAPATH}"
echo "直接点击回车继续，输入任意退出${PREFIX_SYMBOL}"

read continue_work
sleep 0.5

if [ -n "$continue_work" ]
then
echo "退出${PREFIX_SYMBOL}"
exit 1
else
echo "开始编译${PREFIX_SYMBOL}"
fi



if [ $ISWORKSPACE = true ]
then
# 清理
xcodebuild clean -workspace ${PROJECTNAME}.xcworkspace \
-configuration \
${CONFIGURATION} -alltargets
#开始构建
xcodebuild archive -workspace ${PROJECTNAME}.xcworkspace \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET}
else
# 清理
xcodebuild clean -project ${PROJECTNAME}.xcodeproj \
-configuration \
${CONFIGURATION} -alltargets
#开始构建
xcodebuild archive -project ${PROJECTNAME}.xcodeproj \
-scheme ${TARGET_NAME} \
-archivePath ${ARCHIVEPATH} \
-configuration ${CONFIGURATION_TARGET}
fi



echo "是否构建成功${PREFIX_SYMBOL}"
# xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$ARCHIVEPATH" ]
then
echo "成功${PREFIX_SYMBOL}"
else
echo "失败${PREFIX_SYMBOL}"
rm -rf $BUILDPATH
exit 1
fi

xcodebuild -exportArchive \
-archivePath ${ARCHIVEPATH} \
-exportOptionsPlist ${ExportOptionsPlist} \
-exportPath ${IPAPATH}

echo "检查是否成功导出ipa${PREFIX_SYMBOL}"
IPAPATH=${IPAPATH}/${TARGET_NAME}.ipa
if [ -f "$IPAPATH" ]
then
echo "导出ipa成功${PREFIX_SYMBOL}"
open $BUILDPATH
else
echo "导出ipa失败${PREFIX_SYMBOL}"
exit 1
fi

# 上传蒲公英	
if [ $UPLOADPGYER = true ]
then
	echo "上传ipa到蒲公英${PREFIX_SYMBOL}"
	curl -F "file=@$IPAPATH" \
    -F "installType=2" \
	-F "uKey=XXXX" \
	-F "_api_key=XXXX" \
	-F "password=XXXX" \
    https://www.pgyer.com/apiv2/app/upload

	if [ $? = 0 ]
	then
	echo "上传成功${PREFIX_SYMBOL}"
	else
	echo "上传失败${PREFIX_SYMBOL}"
	fi
fi

echo "配置信息${PREFIX_SYMBOL}"
echo "编译模式: ${CONFIGURATION_TARGET}"
echo "导出ipa配置文件: ${ExportOptionsPlist}"
echo "打包文件路径: ${ARCHIVEPATH}"
echo "导出ipa路径: ${IPAPATH}"

exit 0

```
##### 24行开始我们填入的是之前我们导出的ExportOptions.plist，上传蒲公英部分的参数可以参照[官方文档](https://www.pgyer.com/doc/view/api#uploadApp)，我们将打包的路径都设置成了桌面

### 然而这个脚本并不是大家拿去都能用，也是需要根据自己的项目来设置相应的环境变量，希望能帮助到大家！有用就给个星~

[简书地址](http://www.jianshu.com/p/85e696f77789)


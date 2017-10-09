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

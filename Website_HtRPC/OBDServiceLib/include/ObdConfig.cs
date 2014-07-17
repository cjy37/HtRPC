using System;
using System.Xml;
using System.Text;
using System.Text.RegularExpressions;
using System.Configuration;
using System.IO;
using FluorineFx;
using OBDServiceLib.RemoteInterface;


namespace OBDServiceLib.include
{
    /// <summary>
    /// 系统参数列表，共用函数库
    /// </summary>
    public class ObdConfig
    {
        public static string DateTimeFormat = "yyyy-MM-dd HH:mm:ss";
        public static string DateFormat = "yyyy-MM-dd";
        public static string TimeFormat = "HH:mm:ss";
        public static string DateTimeFormatFile = "yyyyMMddHHmmss";

        public static string SendEmail = GetAppSettings("SendEmail");
        public static string SendEmailServer = GetAppSettings("SendEmailServer");
        public static string SendEmailUser = GetAppSettings("SendEmailUser");
        public static string SendEmailPassword = GetAppSettings("SendEmailPassword");

        public static  string DEFAULT_DATA_DB = "obd_data_1";

        public static string SmtpPort = GetAppSettings("SmtpPort");
        public static Boolean EnableSsl
        {
            get
            {
                return Convert.ToBoolean(GetAppSettings("EnableSsl"));
            }
        }// = GetAppSettings("EnableSsl");
        /******************* config *******************/


        /// <summary>
        /// 服务器名
        /// </summary>
        public static string MapKey(string hostName)
        {
            hostName = hostName.Replace(".", "");
            return GetAppSettings("mapKey" + hostName);
        }

        public static string MapClient(string hostName)
        {
            hostName = hostName.Replace(".", "");
            return GetAppSettings("mapClient" + hostName);
        }

        /// <summary>
        /// 服务器名
        /// </summary>
        public static string ServerIpName = GetAppSettings("ServerIpName");
        /// <summary>
        /// 连接服务器的端口
        /// </summary>
        public static int ServerPort = Convert.ToInt32(GetAppSettings("ServerPort"));

        public static string CookieDomain
        {
            get
            {
                return DESEncrypt.Decrypt(_cookieDomain);
            }
        }

        /// <summary>
        /// 连接数据库的端口
        /// </summary>
        public static bool IsUseAndCloseConnect = Convert.ToBoolean(GetAppSettings("isUseAndCloseConnect"));
		
        /// <summary>
        /// 数据库名
        /// </summary>
        private static string _dbName = GetAppSettings("databaseName");

        private static string _dbNameUserData = GetAppSettings("databaseUserDataName");

        private static string _cookieDomain = GetAppSettings("cookieDomain");

        public static string DatabaseName
        {
            get { return _dbName; }
        }

        public static string DatabaseNameUserData
        {
            get { return _dbNameUserData; }
        }


		//---------------------------------------------------------------------------------


        /******************* Function *****************************/
        /// <summary>
        /// 格式化DataSet.GetXml()导出的数据，节点结构为属性结构（行列转换）
        /// </summary>
        /// <param name="x">DataSet.GetXml()导出的数据</param>
        /// <returns>转换后的XML</returns>
        public static XmlDocument FormatXml(XmlDocument x)
        {
            // 此处代码动态构造 xml 文档对象结构来输出XML文档 
            var xmlDoc = x;
            if (xmlDoc == null)
                return null;
            //-------------- 查询数据库，填充XmlDoc -------------------------- 
            /*
             * <root>
             *   <xsl:for-each select="* /*">
             *     <xsl:element name="{name()}"> 
             *       <xsl:for-each select="*"> 
             *         <xsl:attribute name="{name()}"> <xsl:value-of select="."/> </xsl:attribute> 
             *       </xsl:for-each> 
             *     </xsl:element> 
             *   </xsl:for-each>
             * </root>
             */
            // 保存输出结果的缓冲区 
            var myResult = new StringBuilder();
            myResult.Append("<root>");

            // 模拟 <xsl:for-each select="* / *">

            // ReSharper disable PossibleNullReferenceException
            foreach (XmlNode node in xmlDoc.SelectNodes("*/*"))
            // ReSharper restore PossibleNullReferenceException
            {
                myResult.Append("<" + node.Name);

                // 模拟 <xsl:for-each select="*"> 
                // ReSharper disable PossibleNullReferenceException
                foreach (XmlNode node2 in node.SelectNodes("*"))
                // ReSharper restore PossibleNullReferenceException
                {

                    // 模拟 <xsl:value-of select="." /> 
                    if (node2.InnerText.IndexOf("\"") > 0 || node2.InnerText.IndexOf("//") > 0)
                    {
                        //tmpString = "<![CDATA[" + node2.InnerText + "]]>";
                    }
                    else
                    {
                        myResult.Append(" " + node2.Name);
                        var tmpString = node2.InnerText;
                        myResult.Append("=\"" + tmpString + "\"");
                    }

                }
                myResult.Append(" />");
            }

            myResult.Append("</root>");
            var xml = new XmlDocument();
            xml.LoadXml(myResult.ToString());
            return xml;
        }



        //---------------------------------------------------------------------------------
        /// <summary>
        /// 获取web.config中的配置信息
        /// </summary>
        /// <param name="s">配置关键字</param>
        /// <returns>配置值</returns>
        public static string GetAppSettings(string s)
        {
            return ConfigurationManager.AppSettings[s];
        }
        //---------------------------------------------------------------------------------

        /// <summary>
        /// 验证码是否显示，默认为true显示
        /// </summary>
        public static bool VCodeVisible = Convert.ToBoolean(GetAppSettings("VCodeVisible"));

        /// <summary>
        /// 验证码个数
        /// </summary>
        public static Int32 VCodeNum = Convert.ToInt32(GetAppSettings("VCodeNum"));

        /// <summary>
        /// 验证码显示模式，默认为1  
        ///1:数字 2:大小字母 3:大字母 4:小字母 5:汉字
        ///6:数字+大小写字母 7:数字+大字母 8:数字+小字母9:数字+汉字
        ///10:汉字+大小写字母 11:汉字+大字母 12:汉字+小字母13:数字+汉字+大小写字母
        /// </summary>
        public static string VCodeType = GetAppSettings("VCodeType");

        /// <summary>
        /// 验证码忽略大小写
        /// </summary>
        public static bool VCodeIgnoreUL = Convert.ToBoolean(GetAppSettings("VCodeIgnoreUL"));

        /// <summary>
        /// 验证码有无噪点
        /// </summary>
        public static bool VCodeNoiseLine = Convert.ToBoolean(GetAppSettings("VCodeNoiseLine"));
        /// <summary>
        /// 验证码有无噪线
        /// </summary>
        public static bool VCodeNoisePoint = Convert.ToBoolean(GetAppSettings("VCodeNoisePoint"));
        /// <summary>
        /// 验证码字体样式
        /// </summary>
        public static string VCodeFont = GetAppSettings("VCodeFont");
        /// <summary>
        /// 验证码颜色样式
        /// </summary>
        public static string VCodeColor = GetAppSettings("VCodeColor");

        /// <summary>
        /// 页面标题
        /// </summary>
        public static string pageTitle = GetAppSettings("pageTitle");
    }
}